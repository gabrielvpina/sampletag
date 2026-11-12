import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../data/repositories/sample_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../../domain/geo.dart';
import '../../domain/import_plan.dart';
import '../../domain/models.dart';
import '../photo_service.dart';
import 'csv_exporter.dart';
import 'html_report_builder.dart';
import 'kml_exporter.dart';

/// Conteúdo de um ZIP de backup/coleta.
class BackupPackage {
  const BackupPackage({
    required this.archive,
    required this.templates,
    required this.samples,
    this.settings,
    this.createdAt,
  });
  final Archive archive;
  final List<SampleTemplate> templates;
  final List<Sample> samples;
  final AppSettings? settings;
  final DateTime? createdAt;
}

/// Pacote lido + plano de importação, para a tela de prévia.
class ImportPreview {
  const ImportPreview(this.package, this.plan);
  final BackupPackage package;
  final ImportPlan plan;
}

class ImportResult {
  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.renamed,
    required this.replaced,
    required this.templates,
    required this.photos,
  });
  final int imported;
  final int skipped;
  final Map<String, String> renamed;
  final int replaced;
  final int templates;
  final int photos;

  String get summary => [
        '$imported amostra(s) importada(s)',
        if (renamed.isNotEmpty) '${renamed.length} renomeada(s)',
        if (replaced > 0) '$replaced substituída(s)',
        if (skipped > 0) '$skipped ignorada(s)',
        if (templates > 0) '$templates modelo(s) novo(s)',
      ].join(', ');
}

/// Resultado de uma restauração de backup.
class RestoreResult {
  const RestoreResult(this.samples, this.templates, this.photos);
  final int samples;
  final int templates;
  final int photos;
}

/// Gera arquivos de exportação e os compartilha. Nada sai do aparelho sem
/// que o usuário escolha um destino na folha de compartilhamento.
class ExportService {
  ExportService({
    required this.samples,
    required this.templates,
    required this.settings,
    required this.photos,
    required this.db,
    this.geo,
    Future<Directory> Function()? tempDir,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  final SampleRepository samples;
  final TemplateRepository templates;
  final SettingsRepository settings;
  final PhotoService photos;
  final AppDatabase db;

  /// Limites IBGE para o mapa base do relatório (opcional nos testes).
  final GeoLibrary? geo;

  /// Pasta temporária (injetável nos testes).
  final Future<Directory> Function() _tempDir;

  static const backupFormatVersion = 1;

  Future<Map<String, SampleTemplate>> _templateMap() async =>
      {for (final t in await templates.getAll()) t.id: t};

  Future<File> _writeTemp(String name, List<int> bytes) async {
    final dir = Directory(p.join((await _tempDir()).path, 'exports'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, name));
    try {
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      throw AppException(friendlyError(e));
    }
    return file;
  }

  Future<void> share(File file, {required String mime, String? subject}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: mime)],
      subject: subject ?? p.basename(file.path),
    ));
  }

  String _stamp() => fmtIsoDate(DateTime.now());

  Future<File> csv(List<Sample> list) async {
    final s = await settings.get();
    final text = const CsvExporter().export(list, await _templateMap());
    final name = 'SampleTag_${safeFileName(s.project).isEmpty ? 'Amostras' : safeFileName(s.project)}_${_stamp()}.csv';
    return _writeTemp(name, utf8.encode(text));
  }

  Future<File> kml(List<Sample> list) async {
    final s = await settings.get();
    final text = const KmlExporter()
        .export(list, await _templateMap(), documentName: s.project.isEmpty ? 'SampleTag' : s.project);
    final name = 'SampleTag_${safeFileName(s.project).isEmpty ? 'Amostras' : safeFileName(s.project)}_${_stamp()}.kml';
    return _writeTemp(name, utf8.encode(text));
  }

  /// Relatório HTML autocontido. Com [withPhotos], embute miniaturas
  /// (~400 px, JPEG 70%) em base64.
  Future<File> htmlReport(List<Sample> list, {required bool withPhotos}) async {
    final s = await settings.get();
    final thumbs = <String, List<String>>{};
    if (withPhotos) {
      for (final sample in list) {
        final encoded = <String>[];
        for (final name in sample.photos) {
          final bytes = await photos.thumbnail(name);
          if (bytes != null) encoded.add(base64Encode(bytes));
        }
        if (encoded.isNotEmpty) thumbs[sample.id] = encoded;
      }
    }
    ReportGeo? reportGeo;
    if (geo != null) {
      reportGeo = await ReportGeo.build(
        geo!,
        highlighted: effectiveStates(list.map((x) => x.state), s.mapStates),
        includeMunicipalities: s.municipalBoundaries,
      );
    }
    final now = DateTime.now();
    final html = const HtmlReportBuilder().build(ReportInput(
      geo: reportGeo,
      samples: list,
      templates: await _templateMap(),
      settings: s,
      generatedAt: now,
      templateHtml: await rootBundle.loadString('assets/report/template.html'),
      leafletJs: await rootBundle.loadString('assets/report/leaflet.min.js'),
      leafletCss: await rootBundle.loadString('assets/report/leaflet.min.css'),
      iconSvg: await rootBundle.loadString('assets/icon/sampletag_icon.svg'),
      thumbnails: thumbs,
    ));
    return _writeTemp(reportFileName(s.project, now), utf8.encode(html));
  }

  // ---------------------------------------------------------------------------
  // Backup ZIP (banco + fotos) e restauração
  // ---------------------------------------------------------------------------

  /// Cria um ZIP com:
  /// - `sampletag_backup.json`: dados de modelos, amostras e configurações
  ///   (usado na restauração, independente da versão do esquema);
  /// - `sampletag.sqlite`: cópia íntegra do banco (via `VACUUM INTO`);
  /// - `photos/*.jpg`: fotos originais.
  Future<File> backup() async {
    final archive = Archive();
    final allSamples = await samples.getAll();
    final payload = {
      'format': 'sampletag-backup',
      'version': backupFormatVersion,
      'schemaVersion': db.schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': (await settings.get()).toMap(),
      'templates': [for (final t in await templates.getAll()) t.toJson()],
      'samples': [for (final s in allSamples) s.toJson()],
    };
    archive.addFile(ArchiveFile.string('sampletag_backup.json', jsonEncode(payload)));

    final tmp = await _tempDir();
    final dbCopy = File(p.join(tmp.path, 'sampletag_snapshot.sqlite'));
    if (await dbCopy.exists()) await dbCopy.delete();
    try {
      await db.customStatement('VACUUM INTO ?', [dbCopy.path]);
      archive.addFile(ArchiveFile.bytes('sampletag.sqlite', await dbCopy.readAsBytes()));
    } on Object {
      // A cópia SQLite é complementar; o JSON já basta para restaurar.
    } finally {
      if (await dbCopy.exists()) await dbCopy.delete();
    }

    for (final name in allSamples.expand((s) => s.photos).toSet()) {
      final f = File(await photos.resolve(name));
      if (await f.exists()) archive.addFile(ArchiveFile.bytes('photos/$name', await f.readAsBytes()));
    }
    final bytes = ZipEncoder().encodeBytes(archive);
    return _writeTemp('SampleTag_Backup_${_stamp()}.zip', bytes);
  }

  /// Lê e valida um ZIP de backup/coleta do SampleTag.
  BackupPackage readPackage(List<int> zipBytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Object {
      throw const AppException('Arquivo inválido: não é um ZIP do SampleTag.');
    }
    final jsonFile = archive.findFile('sampletag_backup.json');
    if (jsonFile == null) {
      throw const AppException('Arquivo inválido: sampletag_backup.json não encontrado.');
    }
    final Map<String, Object?> data;
    try {
      data = (jsonDecode(utf8.decode(jsonFile.content)) as Map).cast<String, Object?>();
    } on Object {
      throw const AppException('Arquivo corrompido (JSON ilegível).');
    }
    if (data['format'] != 'sampletag-backup') {
      throw const AppException('Arquivo não é um backup do SampleTag.');
    }
    try {
      final settingsMap = data['settings'] is Map
          ? (data['settings'] as Map).map((k, v) => MapEntry('$k', '$v'))
          : <String, String>{};
      return BackupPackage(
        archive: archive,
        templates: [
          for (final t in (data['templates'] as List? ?? const []))
            SampleTemplate.fromJson((t as Map).cast<String, Object?>()),
        ],
        samples: [
          for (final x in (data['samples'] as List? ?? const []))
            Sample.fromJson((x as Map).cast<String, Object?>()),
        ],
        settings: settingsMap.isEmpty ? null : AppSettings.fromMap(settingsMap),
        createdAt: DateTime.tryParse('${data['createdAt']}'),
      );
    } on Object {
      throw const AppException('Arquivo corrompido (dados inválidos).');
    }
  }

  /// Copia para a pasta de fotos as imagens do pacote cujos nomes estão em
  /// [names] (ou todas, se `null`). Arquivos já existentes são mantidos.
  Future<int> _copyPhotos(Archive archive, {Set<String>? names}) async {
    var count = 0;
    final dir = await photos.photosDir();
    try {
      for (final f in archive) {
        if (!f.isFile || !f.name.startsWith('photos/')) continue;
        // Proteção contra "zip slip": usa só o nome base.
        final base = p.basename(f.name);
        if (base.isEmpty || base.startsWith('.')) continue;
        if (names != null && !names.contains(base)) continue;
        final target = File(p.join(dir.path, base));
        if (!await target.exists()) await target.writeAsBytes(f.content, flush: true);
        count++;
      }
    } on FileSystemException catch (e) {
      throw AppException(friendlyError(e));
    }
    return count;
  }

  /// Restaura um backup do próprio aparelho (inclui configurações).
  /// Amostras e modelos são mesclados pelo `id`. Para juntar dados de outro
  /// celular, use [previewImport]/[applyImport].
  Future<RestoreResult> restore(List<int> zipBytes, {bool restoreSettings = true}) async {
    final pkg = readPackage(zipBytes);
    final plan = ImportPlan.build(
      incomingSamples: pkg.samples,
      incomingTemplates: pkg.templates,
      localSamples: await samples.getAll(),
      localTemplates: await templates.getAll(),
    );
    if (plan.conflicts.isNotEmpty) {
      throw AppException(
        'O backup tem ${plan.conflicts.length} amostra(s) com código igual a amostras deste aparelho. '
        'Para juntar dados de outro celular, use "Importar coleta de outro celular".',
      );
    }

    // Fotos primeiro, para não haver amostras apontando para arquivos ausentes.
    final photoCount = await _copyPhotos(pkg.archive);
    await db.transaction(() async {
      await templates.upsertAll(pkg.templates);
      await samples.upsertAll(pkg.samples);
      if (restoreSettings && pkg.settings != null) await settings.save(pkg.settings!);
    });
    return RestoreResult(pkg.samples.length, pkg.templates.length, photoCount);
  }

  // ---------------------------------------------------------------------------
  // Importar coleta de outro celular
  // ---------------------------------------------------------------------------

  /// Lê o pacote e compara com o banco local, sem gravar nada.
  Future<ImportPreview> previewImport(List<int> zipBytes) async {
    final pkg = readPackage(zipBytes);
    final plan = ImportPlan.build(
      incomingSamples: pkg.samples,
      incomingTemplates: pkg.templates,
      localSamples: await samples.getAll(),
      localTemplates: await templates.getAll(),
      source: ImportSource(
        collectorName: pkg.settings?.collectorName ?? '',
        collectorTag: pkg.settings?.collectorTag ?? '',
        project: pkg.settings?.project ?? '',
        createdAt: pkg.createdAt,
      ),
    );
    return ImportPreview(pkg, plan);
  }

  /// Grava a importação. As configurações deste aparelho não são alteradas.
  Future<ImportResult> applyImport(
    ImportPreview preview, {
    required ConflictAction Function(ImportItem item) conflictAction,
    bool updateExisting = true,
  }) async {
    final changes = preview.plan.resolve(conflictAction: conflictAction, updateExisting: updateExisting);
    final needed = {for (final x in changes.upserts) ...x.photos};
    final photoCount = await _copyPhotos(preview.package.archive, names: needed);

    final replaced = <Sample>[];
    await db.transaction(() async {
      await templates.upsertAll(changes.templates);
      for (final id in changes.deleteIds) {
        final old = await samples.getById(id);
        if (old != null) replaced.add(old);
        await samples.delete(id);
      }
      await samples.upsertAll(changes.upserts);
    });
    // Fotos das amostras locais substituídas.
    final kept = needed;
    for (final old in replaced) {
      for (final ph in old.photos) {
        if (!kept.contains(ph)) await photos.deleteFile(ph);
      }
    }
    return ImportResult(
      imported: changes.upserts.length,
      skipped: changes.skipped,
      renamed: changes.renamed,
      replaced: changes.deleteIds.length,
      templates: changes.templates.length,
      photos: photoCount,
    );
  }
}
