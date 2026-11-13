import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/data/repositories/settings_repository.dart';
import 'package:sampletag/data/repositories/template_repository.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
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

  testWidgets('seleção múltipla: toque longo, selecionar e excluir várias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    await tester.runAsync(() => SampleRepository(db).upsertAll(demoSamples()));
    await pumpApp(tester, db, tmp);
    expect(find.text('5 amostras'), findsOneWidget);

    await tester.longPress(find.text('CAC-2026-0001'));
    await settle(tester, steps: 2);
    expect(find.text('1 selecionada(s)'), findsOneWidget);
    await tester.tap(find.text('CAC-2026-0002'));
    await settle(tester, steps: 2);
    expect(find.text('2 selecionada(s)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-selected')));
    await settle(tester, steps: 3);
    expect(find.text('Excluir 2 amostra(s)?'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await settle(tester);

    final left = await tester.runAsync(() => SampleRepository(db).getAll());
    expect(left!.map((s) => s.sampleCode), isNot(contains('CAC-2026-0001')));
    expect(left, hasLength(3));
    expect(find.text('3 amostras'), findsOneWidget);
    expect(find.byKey(const Key('selection-count')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, steps: 2);
  });

  testWidgets('cria amostra técnica a partir da ficha da amostra de origem', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    // O mini-mapa da ficha pede a pasta de cache dos tiles.
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (_) async => tmp.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null));
    await tester.runAsync(() => SampleRepository(db).upsertAll(demoSamples()));
    await pumpApp(tester, db, tmp);

    await tester.tap(find.text('CAC-2026-0001'));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('new-child-sample')), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('new-child-sample')));
    await settle(tester);

    expect(find.text('Nova amostra técnica'), findsOneWidget);
    expect(find.text('Derivada de CAC-2026-0001'), findsOneWidget);
    final code = tester.widget<TextFormField>(find.byKey(const Key('code-field'))).controller!.text;
    expect(code, 'CAC-2026-0001-01');

    await tester.tap(find.byKey(const Key('save-sample')));
    await settle(tester);

    final all = await tester.runAsync(() => SampleRepository(db).getAll());
    final child = all!.firstWhere((s) => s.sampleCode == 'CAC-2026-0001-01');
    final parent = all.firstWhere((s) => s.sampleCode == 'CAC-2026-0001');
    expect(child.parentId, parent.id);
    expect(child.category, SampleCategory.technical);
    expect((child.latitude, child.municipality, child.cloneGenotype),
        (parent.latitude, parent.municipality, parent.cloneGenotype));
    expect(child.photos, isEmpty);

    // A ficha da origem lista a filha.
    expect(find.text('Amostras técnicas (1)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, steps: 2);
  });
}
