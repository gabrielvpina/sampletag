import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/data/repositories/settings_repository.dart';
import 'package:sampletag/data/repositories/template_repository.dart';
import 'package:sampletag/services/export/export_service.dart';
import 'package:sampletag/services/photo_service.dart';

import 'flows/create_and_export_flow.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('sampletag_test');
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  testWidgets('formulário valida campos obrigatórios e salva a amostra', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    await pumpApp(tester, db, tmp);

    final code = await createSampleThroughUi(tester);

    final saved = await tester.runAsync(() => SampleRepository(db).getAll());
    expect(saved, hasLength(1));
    final s = saved!.single;
    expect(s.sampleCode, code);
    expect(s.cloneGenotype, 'CCN-51');
    expect(s.customFields['tecido'], 'Folha jovem');
    expect(s.storageInstruction, 'Armazenar a -20 °C (Análise de DNA/RNA)');

    // Voltou para a lista, que mostra o card e o contador.
    expect(find.text(code), findsOneWidget);
    expect(find.text('1 amostra'), findsOneWidget);

    // Rascunho foi apagado ao salvar.
    expect(await tester.runAsync(() => SettingsRepository(db).loadDraft('new')), isNull);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, steps: 2);
  });

  testWidgets('fluxo: criar amostra → exportar relatório HTML', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    await pumpApp(tester, db, tmp);
    final code = await createSampleThroughUi(tester);

    final file = await tester.runAsync(() async {
      final svc = ExportService(
        samples: SampleRepository(db),
        templates: TemplateRepository(db),
        settings: SettingsRepository(db),
        photos: PhotoService(baseDir: tmp),
        db: db,
        tempDir: () async => tmp,
      );
      return svc.htmlReport(await SampleRepository(db).getAll(), withPhotos: true);
    });

    expect(file!.path, matches(RegExp(r'SampleTag_Relatorio_Geral_\d{4}-\d{2}-\d{2}\.html$')));
    final html = await tester.runAsync(file.readAsString);
    expect(html, contains(code));
    expect(html, contains('FICHA DE AMOSTRA - CACAU'));
    expect(html, contains('id="samples-data"'));
    expect(html, contains('Leaflet 1.9.4'));
    await tester.pumpWidget(const SizedBox());
    await settle(tester, steps: 2);
  });
}
