import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/data/db/database.dart';
import 'package:sampletag/data/repositories/sample_repository.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/sample_code.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/domain/template_share.dart';
import 'package:sampletag/services/export/csv_exporter.dart';
import 'package:sampletag/services/export/kml_exporter.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('amostras técnicas', () {
    test('código ORIGEM-01, -02… ignorando outros sufixos', () {
      expect(nextChildCode('CAC-AS-2026-0001', const []), 'CAC-AS-2026-0001-01');
      expect(
        nextChildCode('CAC-AS-2026-0001', ['cac-as-2026-0001-01', 'CAC-AS-2026-0001-07', 'CAC-AS-2026-0001-B', 'CAC-AS-2026-0002-09']),
        'CAC-AS-2026-0001-08',
      );
      // Filha de filha.
      expect(nextChildCode('CAC-AS-2026-0001-01', ['CAC-AS-2026-0001-01']), 'CAC-AS-2026-0001-01-01');
    });

    test('código de filha não altera a sequência das amostras normais', () {
      final codes = ['CAC-AS-2026-0001', 'CAC-AS-2026-0001-01', 'CAC-AS-2026-0001-02'];
      expect(
        nextSampleCode(existingCodes: codes, pattern: AppSettings.defaultIdPattern, prefix: 'CAC', date: DateTime(2026), collector: 'AS'),
        'CAC-AS-2026-0002',
      );
    });

    test('parentId vai e volta no JSON e copyWith pode limpar', () {
      final child = demoSamples().first.copyWith(parentId: () => 'demo-2');
      expect(Sample.fromJson(jsonDecode(jsonEncode(child.toJson())) as Map<String, Object?>).parentId, 'demo-2');
      expect(child.copyWith(parentId: () => null).parentId, isNull);
      expect(child.copyWith(notes: 'x').parentId, 'demo-2');
      expect(demoSamples().first.toJson().containsKey('parentId'), isFalse);
    });

    test('banco: filhas, exclusão em lote mantém filhas sem vínculo', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SampleRepository(db);
      final demo = demoSamples();
      await repo.upsertAll(demo);
      final parent = demo.first;
      final c1 = demo[1].copyWith(sampleCode: await repo.nextChildCode(parent.sampleCode), parentId: () => parent.id);
      await repo.upsert(c1);
      final c2 = demo[2].copyWith(sampleCode: await repo.nextChildCode(parent.sampleCode), parentId: () => parent.id);
      await repo.upsert(c2);
      expect([c1.sampleCode, c2.sampleCode], ['${parent.sampleCode}-01', '${parent.sampleCode}-02']);
      expect((await repo.watchChildren(parent.id).first).map((s) => s.id), [c1.id, c2.id]);

      await repo.deleteMany([parent.id, c2.id, demo[4].id]);
      final left = await repo.getAll();
      expect(left.map((s) => s.id).toSet(), {c1.id, demo[3].id});
      expect(left.firstWhere((s) => s.id == c1.id).parentId, isNull);
    });

    test('migração v1 → v2 mantém as amostras e cria parentId', () async {
      final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
        raw.execute('''CREATE TABLE templates (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, code_prefix TEXT NOT NULL,
          color INTEGER NOT NULL, default_storage_instruction TEXT NOT NULL DEFAULT '', category TEXT NOT NULL,
          fields_json TEXT NOT NULL DEFAULT '[]', created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
        raw.execute('''CREATE TABLE samples (id TEXT NOT NULL PRIMARY KEY, sample_code TEXT NOT NULL UNIQUE,
          template_id TEXT NOT NULL REFERENCES templates (id), category TEXT NOT NULL, collected_at INTEGER NOT NULL,
          collector_name TEXT NOT NULL DEFAULT '', collector_contact TEXT NOT NULL DEFAULT '', clone_genotype TEXT NOT NULL DEFAULT '',
          origin_property TEXT NOT NULL DEFAULT '', municipality TEXT NOT NULL DEFAULT '', state TEXT NOT NULL DEFAULT '',
          latitude REAL NULL, longitude REAL NULL, altitude REAL NULL, gps_accuracy_meters REAL NULL,
          photos_json TEXT NOT NULL DEFAULT '[]', notes TEXT NOT NULL DEFAULT '', storage_instruction TEXT NOT NULL DEFAULT '',
          custom_fields_json TEXT NOT NULL DEFAULT '{}', created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
        raw.execute('CREATE TABLE key_values ("key" TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
        raw.execute("INSERT INTO templates VALUES ('tpl-cacau','Cacau','CAC',4282211392,'','biologica','[]',0,0)");
        raw.execute('INSERT INTO samples (id, sample_code, template_id, category, collected_at, created_at, updated_at) '
            "VALUES ('old-1','CAC-2025-0001','tpl-cacau','biologica',1700000000,1700000000,1700000000)");
        raw.execute('PRAGMA user_version = 1');
      }));
      addTearDown(db.close);
      final all = await SampleRepository(db).getAll();
      expect(all.single.sampleCode, 'CAC-2025-0001');
      expect(all.single.parentId, isNull);
      await SampleRepository(db).upsert(all.single.copyWith(sampleCode: 'X-01', parentId: () => 'p'));
      expect((await SampleRepository(db).getById('old-1'))!.parentId, 'p');
    });

    test('CSV e KML trazem o código da amostra de origem', () {
      final demo = demoSamples();
      final child = demo[1].copyWith(sampleCode: '${demo[0].sampleCode}-01', parentId: () => demo[0].id);
      final templates = {cacauTemplate.id: cacauTemplate};
      // Origem fora da exportação: resolvida pelo mapa de códigos.
      final csv = const CsvExporter().export([child], templates, codesById: codesByIdOf(demo));
      final lines = csv.split('\r\n');
      final header = lines.first.split(';');
      final idx = header.indexOf('amostra_origem');
      expect(idx, greaterThan(0));
      expect(lines[1].split(';')[idx], demo[0].sampleCode);
      final kml = const KmlExporter().export([child, demo[0]], templates);
      expect(kml, contains('<Data name="amostra_origem"><value>${demo[0].sampleCode}</value></Data>'));
    });
  });

  group('modelos compartilhados', () {
    test('arquivo vai e volta sem perder campos', () {
      final bytes = utf8.encode(encodeTemplateFile(cacauTemplate));
      final back = decodeTemplateFile(bytes);
      expect(jsonEncode(back.toJson()), jsonEncode(cacauTemplate.toJson()));
      // Com BOM (alguns apps de mensagem acrescentam).
      expect(decodeTemplateFile([0xEF, 0xBB, 0xBF, ...bytes]).name, 'Cacau');
    });

    test('arquivos inválidos dão mensagem clara', () {
      expect(() => decodeTemplateFile(utf8.encode('não é json')), throwsA(isA<FormatException>()));
      expect(() => decodeTemplateFile(utf8.encode('{"format":"sampletag-backup"}')), throwsA(isA<FormatException>()));
      expect(
        () => decodeTemplateFile(utf8.encode('{"format":"sampletag-template","version":99,"template":{}}')),
        throwsA(predicate((e) => e is FormatException && e.message.contains('versão mais nova'))),
      );
      expect(
        () => decodeTemplateFile(utf8.encode('{"format":"sampletag-template","version":1,"template":{"id":"x"}}')),
        throwsA(isA<FormatException>()),
      );
    });

    test('compara com os modelos locais e cria cópia sem repetir nome', () {
      expect(matchTemplate(cacauTemplate, const []).$1, TemplateMatch.none);
      expect(matchTemplate(cacauTemplate, [cacauTemplate]).$1, TemplateMatch.identical);
      final edited = cacauTemplate.copyWith(fields: cacauTemplate.fields.take(1).toList());
      expect(matchTemplate(edited, [cacauTemplate]), (TemplateMatch.differs, cacauTemplate));
      // Mesmo nome e prefixo, outro id (criado à mão em outro celular).
      final other = SampleTemplate.fromJson({...cacauTemplate.toJson(), 'id': 'tpl-outro'});
      expect(matchTemplate(other, [cacauTemplate]).$1, TemplateMatch.identical);
      final copy = templateCopy(cacauTemplate, 'tpl-novo', [cacauTemplate, cacauTemplate.copyWith(name: 'Cacau (2)')]);
      expect((copy.id, copy.name), ('tpl-novo', 'Cacau (3)'));
    });
  });
}
