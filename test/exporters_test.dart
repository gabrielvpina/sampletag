import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/csv_exporter.dart';
import 'package:sampletag/services/export/kml_exporter.dart';
import 'package:sampletag/services/export/qr_payload.dart';

void main() {
  final templates = {cacauTemplate.id: cacauTemplate};
  final samples = demoSamples();

  group('CSV', () {
    const csv = CsvExporter();

    test('cabeçalho, BOM e uma linha por amostra', () {
      final out = csv.export(samples, templates);
      expect(out.startsWith('\uFEFF'), isTrue);
      final lines = out.substring(1).trimRight().split('\r\n');
      expect(lines, hasLength(samples.length + 1));
      expect(lines.first, startsWith('codigo;modelo;categoria;data_coleta'));
      // Campos extras do modelo Cacau viram colunas.
      expect(lines.first, contains('Tecido coletado'));
      expect(lines[1], startsWith('CAC-2026-0001;Cacau;Biológica;03/11/2026 09:30'));
      expect(lines[1], contains('-14.793500;-39.172000'));
    });

    test('escapa separador, aspas e quebras de linha', () {
      expect(csv.escape('a;b'), '"a;b"');
      expect(csv.escape('diz "oi"'), '"diz ""oi"""');
      expect(csv.escape('linha1\nlinha2'), '"linha1\nlinha2"');
      expect(csv.escape(' espaço'), '" espaço"');
      expect(csv.escape('simples'), 'simples');
    });

    test('neutraliza injeção de fórmula, mas mantém números negativos', () {
      expect(csv.escape('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      expect(csv.escape('@SUM(A1)'), "'@SUM(A1)");
      expect(csv.escape('-14.79'), '-14.79');
    });

    test('amostra com texto problemático gera CSV válido', () {
      final s = samples.first.copyWith(notes: 'obs; com "aspas"\ne linha');
      final out = csv.export([s], templates);
      expect(out, contains('"obs; com ""aspas""\ne linha"'));
    });
  });

  group('KML', () {
    const kml = KmlExporter();

    test('documento válido com placemarks e coordenadas lon,lat', () {
      final out = kml.export(samples, templates, documentName: 'Teste & <projeto>');
      expect(out, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(out, contains('<name>Teste &amp; &lt;projeto&gt;</name>'));
      expect('<Placemark>'.allMatches(out).length, samples.length);
      expect(out, contains('<coordinates>-39.172,-14.7935,62.0</coordinates>'));
      expect(out, contains('<Data name="Tecido coletado"><value>Folha jovem</value></Data>'));
    });

    test('amostras sem coordenadas ficam de fora', () {
      final noGps = Sample(
        id: 'x',
        sampleCode: 'CAC-2026-0099',
        templateId: cacauTemplateId,
        category: SampleCategory.biological,
        collectedAt: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final out = kml.export([noGps], templates);
      expect(out, isNot(contains('<Placemark>')));
    });

    test('cor KML em aabbggrr', () {
      expect(KmlExporter.kmlColor(0xFF3D5C40), 'ff405c3d');
    });

    test('escape XML remove caracteres de controle', () {
      expect(KmlExporter.xml('a\u0001b<"\'>'), 'ab&lt;&quot;&apos;&gt;');
    });
  });

  group('QR', () {
    test('payload é JSON compacto e reversível', () {
      final payload = qrPayload(samples.first, cacauTemplate);
      final map = jsonDecode(payload) as Map;
      expect(map['c'], 'CAC-2026-0001');
      expect(map['m'], 'Cacau');
      expect(map['mun'], 'Ilhéus/BA');
      expect(codeFromQr(payload), 'CAC-2026-0001');
    });

    test('aceita texto simples e rejeita JSON sem código', () {
      expect(codeFromQr('  CAC-2026-0002 '), 'CAC-2026-0002');
      expect(codeFromQr('{"x":1}'), isNull);
      expect(codeFromQr('{inválido'), isNull);
      expect(codeFromQr(''), isNull);
    });
  });
}
