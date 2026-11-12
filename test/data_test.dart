import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/data/repositories/settings_repository.dart';
import 'package:sampletag/data/repositories/template_repository.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/sample_filter.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/label_pdf.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('banco novo vem com o modelo Cacau', () async {
    final list = await TemplateRepository(db).getAll();
    expect(list.map((t) => t.name), ['Cacau']);
    final cacau = list.single;
    expect(cacau.codePrefix, 'CAC');
    expect(cacau.defaultStorageInstruction, defaultDnaStorage);
    expect(cacau.fields.map((f) => f.key), containsAll(['tecido', 'numero_planta', 'sanidade']));
  });

  test('CRUD de amostras, busca por código e próximo código', () async {
    final repo = SampleRepository(db);
    await repo.upsertAll(demoSamples());
    expect(await repo.getAll(), hasLength(5));
    expect((await repo.getByCode('cac-2026-0003'))?.cloneGenotype, 'TSH-1188');
    expect(await repo.codeExists('CAC-2026-0001'), isTrue);
    expect(await repo.codeExists('CAC-2026-0001', exceptId: 'demo-1'), isFalse);
    expect(
      await repo.nextCode(pattern: AppSettings.defaultIdPattern, prefix: 'CAC', date: DateTime(2026, 12)),
      'CAC-2026-0006',
    );

    final s = (await repo.getById('demo-1'))!;
    await repo.upsert(s.copyWith(notes: 'editado', photos: ['a.jpg', 'b.jpg']));
    final edited = (await repo.getById('demo-1'))!;
    expect(edited.notes, 'editado');
    expect(edited.photos, ['a.jpg', 'b.jpg']);
    expect(edited.customFields['idade_planta'], 12);

    await repo.delete('demo-1');
    expect(await repo.getById('demo-1'), isNull);
  });

  test('configurações e rascunhos', () async {
    final repo = SettingsRepository(db);
    expect((await repo.get()).idPattern, AppSettings.defaultIdPattern);
    await repo.save(const AppSettings(collectorName: 'Ana', project: 'P1'));
    expect((await repo.get()).project, 'P1');

    await repo.saveDraft('new', {'code': 'CAC-1'});
    expect(await repo.loadDraft('new'), {'code': 'CAC-1'});
    await repo.clearDraft('new');
    expect(await repo.loadDraft('new'), isNull);
  });

  test('modelo em uso é contado', () async {
    await SampleRepository(db).upsertAll(demoSamples());
    expect(await TemplateRepository(db).usageCount(cacauTemplateId), 5);
  });

  group('filtros', () {
    final t = {cacauTemplate.id: cacauTemplate};
    final all = demoSamples();

    test('busca sem acento e por campo personalizado', () {
      expect(const SampleFilter(query: 'ilheus').apply(all, t).single.sampleCode, 'CAC-2026-0001');
      expect(const SampleFilter(query: 'vassoura').apply(all, t).single.sampleCode, 'CAC-2026-0003');
    });

    test('coletor, município, período e ordenação', () {
      expect(const SampleFilter(collector: 'João Lima').apply(all, t), hasLength(2));
      expect(const SampleFilter(municipality: 'Una').apply(all, t), hasLength(1));
      final f = SampleFilter(from: DateTime(2026, 11, 4), to: DateTime(2026, 11, 5), sort: SampleSort.oldest);
      expect(f.apply(all, t).map((s) => s.sampleCode), ['CAC-2026-0003', 'CAC-2026-0004']);
      expect(const SampleFilter(sort: SampleSort.newest).apply(all, t).first.sampleCode, 'CAC-2026-0005');
    });
  });

  test('pdfSafe troca caracteres fora do Latin-1', () {
    expect(pdfSafe('Ilhéus – 20 °C… “ok”'), 'Ilhéus - 20 °C... "ok"');
    expect(pdfSafe('日本'), '??');
  });

  test('PDF de etiquetas é gerado nos três tamanhos', () async {
    final t = {cacauTemplate.id: cacauTemplate};
    for (final size in LabelSize.values) {
      final bytes = await const LabelPdf().build(demoSamples(), t, size);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: size.name);
    }
  });
}
