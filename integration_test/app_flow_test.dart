// Teste de integração: criar amostra → exportar relatório, em aparelho ou
// emulador real (path_provider, rootBundle e SQLite nativos).
//
//   flutter test integration_test/app_flow_test.dart -d <device>

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/data/repositories/settings_repository.dart';
import 'package:sampletag/data/repositories/template_repository.dart';
import 'package:sampletag/services/export/export_service.dart';
import 'package:sampletag/services/photo_service.dart';

import '../test/flows/create_and_export_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('criar amostra pela interface e exportar relatório HTML', (tester) async {
    // Banco em memória para não tocar nos dados reais do aparelho.
    final db = AppDatabase(NativeDatabase.memory());
    final tmp = await getTemporaryDirectory();
    await pumpApp(tester, db, tmp);

    final code = await createSampleThroughUi(tester);
    expect(find.text(code), findsOneWidget);

    final svc = ExportService(
      samples: SampleRepository(db),
      templates: TemplateRepository(db),
      settings: SettingsRepository(db),
      photos: PhotoService(),
      db: db,
    );
    final file = await svc.htmlReport(await SampleRepository(db).getAll(), withPhotos: true);
    final html = await file.readAsString();
    expect(html, contains(code));
    expect(html, contains('FICHA DE AMOSTRA - CACAU'));
    expect(html, contains('id="samples-data"'));
    await db.close();
  });
}
