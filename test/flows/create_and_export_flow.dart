// Fluxo compartilhado entre o teste de widget (test/) e o teste de
// integração (integration_test/): cria uma amostra pela interface e exporta
// o relatório HTML.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sampletag/app.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/providers.dart';
import 'package:sampletag/services/export/export_service.dart';

/// Abre o app com o banco [db] e uma pasta temporária [tempDir].
Future<void> pumpApp(WidgetTester tester, AppDatabase db, Directory tempDir) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      exportServiceProvider.overrideWith((ref) => ExportService(
            samples: ref.watch(sampleRepoProvider),
            templates: ref.watch(templateRepoProvider),
            settings: ref.watch(settingsRepoProvider),
            photos: ref.watch(photoServiceProvider),
            db: db,
            tempDir: () async => tempDir,
          )),
    ],
    child: const SampleTagApp(),
  ));
  await settle(tester);
}

/// `pumpAndSettle` não serve com indicadores de progresso infinitos;
/// avança o relógio em passos e deixa o I/O real (SQLite) completar.
Future<void> settle(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Abre "Nova amostra", testa a validação e salva uma amostra Cacau.
/// Retorna o código gerado.
Future<String> createSampleThroughUi(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('new-sample')));
  await settle(tester);

  // Primeira amostra sem coletor configurado: o app pede o código {COLETOR}.
  expect(find.text('Código do coletor'), findsOneWidget);
  await tester.enterText(find.byKey(const Key('collector-code-field')), 'as');
  await tester.tap(find.text('Salvar'));
  await settle(tester);

  // Modelo único (Cacau) já vem selecionado e o código é gerado.
  final codeField = tester.widget<TextFormField>(find.byKey(const Key('code-field')));
  final code = codeField.controller!.text;
  expect(code, matches(RegExp(r'^CAC-AS-\d{4}-0001$')));

  // Salvar sem o campo obrigatório "Tecido coletado" mostra erro.
  await tester.tap(find.byKey(const Key('save-sample')));
  await settle(tester, steps: 4);
  expect(find.text('Campo obrigatório'), findsOneWidget);

  await tester.enterText(find.byKey(const Key('clone-field')), 'CCN-51');
  final tecido = find.byKey(const Key('custom-tecido'));
  await tester.ensureVisible(tecido);
  await tester.pump();
  // Seleciona pelo callback do campo: abrir o menu suspenso em teste
  // depende de animações de rota e torna o teste frágil.
  tester.widget<DropdownButtonFormField<String>>(tecido).onChanged!('Folha jovem');
  await settle(tester, steps: 4);
  expect(find.text('Folha jovem'), findsOneWidget);

  await tester.tap(find.byKey(const Key('save-sample')));
  await settle(tester);
  return code;
}
