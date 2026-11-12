import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/core/errors.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/data/repositories/settings_repository.dart';
import 'package:sampletag/data/repositories/template_repository.dart';
import 'package:sampletag/domain/import_plan.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/export_service.dart';
import 'package:sampletag/services/photo_service.dart';

Sample sample(String id, String code, {DateTime? updated, String tpl = cacauTemplateId, List<String> photos = const []}) {
  final t = updated ?? DateTime(2026, 11, 1);
  return Sample(
    id: id,
    sampleCode: code,
    templateId: tpl,
    category: SampleCategory.biological,
    collectedAt: DateTime(2026, 11, 1),
    collectorName: 'X',
    photos: photos,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('ImportPlan', () {
    test('classifica novas, atualizadas, iguais, antigas e conflitos', () {
      final local = [
        sample('a', 'CAC-0001', updated: DateTime(2026, 11, 1)),
        sample('b', 'CAC-0002', updated: DateTime(2026, 11, 5)),
        sample('c', 'CAC-0003', updated: DateTime(2026, 11, 1)),
        sample('d', 'CAC-0004'),
      ];
      final incoming = [
        sample('a', 'CAC-0001', updated: DateTime(2026, 11, 3)), // atualizada
        sample('b', 'CAC-0002', updated: DateTime(2026, 11, 2)), // local mais nova
        sample('c', 'CAC-0003', updated: DateTime(2026, 11, 1)), // igual
        sample('x', 'cac-0004'), // conflito (ignora caixa)
        sample('y', 'CAC-0099'), // nova
        sample('z', 'CAC-0099'), // repetida dentro do pacote
        sample('w', 'CAC-0100', tpl: 'tpl-inexistente'),
      ];
      final plan = ImportPlan.build(
        incomingSamples: incoming,
        incomingTemplates: const [cacauTemplate],
        localSamples: local,
        localTemplates: const [cacauTemplate],
      );
      expect(plan.count(ImportKind.updated), 1);
      expect(plan.count(ImportKind.olderThanLocal), 1);
      expect(plan.count(ImportKind.unchanged), 1);
      expect(plan.count(ImportKind.added), 1);
      expect(plan.count(ImportKind.codeConflict), 2);
      expect(plan.count(ImportKind.missingTemplate), 1);

      final r = plan.resolve(conflictAction: (_) => ConflictAction.rename);
      final codes = r.upserts.map((s) => s.sampleCode).toList();
      expect(codes, containsAll(['CAC-0001', 'CAC-0099', 'cac-0004-B', 'CAC-0099-B']));
      expect(r.renamed, {'cac-0004': 'cac-0004-B', 'CAC-0099': 'CAC-0099-B'});
      expect(r.skipped, 3);

      final skip = plan.resolve(conflictAction: (_) => ConflictAction.skip, updateExisting: false);
      expect(skip.upserts.map((s) => s.id), ['y']);

      final replace = plan.resolve(conflictAction: (_) => ConflictAction.replace);
      expect(replace.deleteIds, ['d']);
      // A repetição dentro do pacote não apaga a amostra recém-importada: é renomeada.
      expect(replace.upserts.map((s) => s.sampleCode), contains('CAC-0099-B'));
    });

    test('modelo com mesmo nome e prefixo é reaproveitado; outro vira novo', () {
      final cafeA = SampleTemplate(id: 'tpl-a', name: 'Café', codePrefix: 'CAF', color: 1, defaultStorageInstruction: '', category: SampleCategory.biological);
      final cafeB = SampleTemplate(id: 'tpl-b', name: ' café ', codePrefix: 'caf', color: 2, defaultStorageInstruction: '', category: SampleCategory.biological);
      final solo = SampleTemplate(id: 'tpl-s', name: 'Solo', codePrefix: 'SOL', color: 3, defaultStorageInstruction: '', category: SampleCategory.technical);
      final plan = ImportPlan.build(
        incomingSamples: [sample('1', 'CAF-1', tpl: 'tpl-b'), sample('2', 'SOL-1', tpl: 'tpl-s')],
        incomingTemplates: [cafeB, solo],
        localSamples: const [],
        localTemplates: [cafeA],
      );
      expect(plan.templateIdMap, {'tpl-b': 'tpl-a', 'tpl-s': 'tpl-s'});
      expect(plan.newTemplates.map((t) => t.id), ['tpl-s']);
      expect(plan.items.first.incoming.templateId, 'tpl-a');
    });

    test('uniqueCode pula letras ocupadas', () {
      expect(uniqueCode('A', {'a-b', 'a-c'}), 'A-D');
    });
  });

  group('dois celulares', () {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late Directory tmp;
    late AppDatabase dbA, dbB;
    late ExportService a, b;

    ExportService svc(AppDatabase db, String name) {
      final dir = Directory('${tmp.path}/$name')..createSync();
      return ExportService(
        samples: SampleRepository(db),
        templates: TemplateRepository(db),
        settings: SettingsRepository(db),
        photos: PhotoService(baseDir: dir),
        db: db,
        tempDir: () async => dir,
      );
    }

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('two_phones');
      dbA = AppDatabase(NativeDatabase.memory());
      dbB = AppDatabase(NativeDatabase.memory());
      a = svc(dbA, 'A');
      b = svc(dbB, 'B');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
      tmp.deleteSync(recursive: true);
    });

    test('coletor envia o backup e o coordenador importa sem perder nada', () async {
      // Celular A (Ana): 2 amostras, uma com foto.
      await SettingsRepository(dbA).save(const AppSettings(collectorName: 'Ana Souza', project: 'Campo A'));
      final photoDir = await a.photos.photosDir();
      File('${photoDir.path}/foto1.jpg').writeAsBytesSync([1, 2, 3]);
      await SampleRepository(dbA).upsertAll([
        sample('a1', 'CAC-2026-0001', photos: ['foto1.jpg']),
        sample('a2', 'CAC-2026-0002'),
      ]);
      final zip = await (await a.backup()).readAsBytes();

      // Celular B (coordenador): já tem uma CAC-2026-0001 diferente.
      await SettingsRepository(dbB).save(const AppSettings(collectorName: 'João Lima', project: 'Projeto B'));
      await SampleRepository(dbB).upsert(sample('b1', 'CAC-2026-0001'));

      // Restaurar recusa (códigos repetidos) com mensagem clara.
      await expectLater(b.restore(zip), throwsA(isA<AppException>()));

      final preview = await b.previewImport(zip);
      expect(preview.plan.source.label, 'Ana Souza (AS)');
      expect(preview.plan.count(ImportKind.added), 1);
      expect(preview.plan.conflicts, hasLength(1));

      final result = await b.applyImport(preview, conflictAction: (_) => ConflictAction.rename);
      expect(result.imported, 2);
      expect(result.renamed, {'CAC-2026-0001': 'CAC-2026-0001-B'});
      expect(result.photos, 1);

      final all = await SampleRepository(dbB).getAll();
      expect(all.map((s) => s.sampleCode).toSet(), {'CAC-2026-0001', 'CAC-2026-0001-B', 'CAC-2026-0002'});
      expect(File(await b.photos.resolve('foto1.jpg')).existsSync(), isTrue);
      // Configurações do coordenador intactas.
      final st = await SettingsRepository(dbB).get();
      expect((st.collectorName, st.project), ('João Lima', 'Projeto B'));

      // Importar de novo o mesmo arquivo não duplica nada.
      final again = await b.previewImport(zip);
      expect(again.plan.count(ImportKind.added), 0);
      final r2 = await b.applyImport(again, conflictAction: (_) => ConflictAction.skip);
      expect(r2.imported, 0);
      expect(await SampleRepository(dbB).getAll(), hasLength(3));
    });

    test('arquivo que não é do SampleTag é recusado', () async {
      expect(() => b.readPackage([1, 2, 3]), throwsA(isA<AppException>()));
    });
  });
}
