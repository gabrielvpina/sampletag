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
import '../../domain/models.dart';
import '../photo_service.dart';
import 'csv_exporter.dart';
import 'html_report_builder.dart';
import 'kml_exporter.dart';

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
    Future<Directory> Function()? tempDir,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  final SampleRepository samples;
  final TemplateRepository templates;
  final SettingsRepository settings;
  final PhotoService photos;
  final AppDatabase db;

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
    final now = DateTime.now();
    final html = const HtmlReportBuilder().build(ReportInput(
      samples: list,
      templates: await _templateMap(),
      settings: s,
      generatedAt: now,
      templateHtml: await rootBundle.loadString('assets/report/template.html'),
      leafletJs: await rootBundle.loadString('assets/report/leaflet.min.js'),
      leafletCss: await rootBundle.loadString('assets/report/leaflet.min.css'),
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

  /// Restaura um backup. Amostras e modelos são mesclados pelo `id`
  /// (registros existentes com o mesmo id são substituídos; os demais ficam).
  Future<RestoreResult> restore(List<int> zipBytes, {bool restoreSettings = true}) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Object {
      throw const AppException('Arquivo inválido: não é um ZIP de backup do SampleTag.');
    }
    final jsonFile = archive.findFile('sampletag_backup.json');
    if (jsonFile == null) {
      throw const AppException('Backup inválido: sampletag_backup.json não encontrado.');
    }
    final Map<String, Object?> data;
    try {
      data = (jsonDecode(utf8.decode(jsonFile.content)) as Map).cast<String, Object?>();
    } on Object {
      throw const AppException('Backup corrompido (JSON ilegível).');
    }
    if (data['format'] != 'sampletag-backup') {
      throw const AppException('Arquivo não é um backup do SampleTag.');
    }

    final tpl = [
      for (final t in (data['templates'] as List? ?? const []))
        SampleTemplate.fromJson((t as Map).cast<String, Object?>()),
    ];
    final smp = [
      for (final s in (data['samples'] as List? ?? const []))
        Sample.fromJson((s as Map).cast<String, Object?>()),
    ];

    // Fotos primeiro, para não haver amostras apontando para arquivos ausentes.
    var photoCount = 0;
    final dir = await photos.photosDir();
    try {
      for (final f in archive) {
        if (!f.isFile || !f.name.startsWith('photos/')) continue;
        // Proteção contra "zip slip": usa só o nome base.
        final base = p.basename(f.name);
        if (base.isEmpty || base.startsWith('.')) continue;
        await File(p.join(dir.path, base)).writeAsBytes(f.content, flush: true);
        photoCount++;
      }
    } on FileSystemException catch (e) {
      throw AppException(friendlyError(e));
    }

    await db.transaction(() async {
      await templates.upsertAll(tpl);
      await samples.upsertAll(smp);
      if (restoreSettings && data['settings'] is Map) {
        final map = (data['settings'] as Map).map((k, v) => MapEntry('$k', '$v'));
        await settings.save(AppSettings.fromMap(map));
      }
    });
    return RestoreResult(smp.length, tpl.length, photoCount);
  }
}
