import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/domain/geo.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/html_report_builder.dart';

void main() {
  late String template;
  setUpAll(() async {
    template = await File('assets/report/template.html').readAsString();
  });

  ReportInput input(List<Sample> samples, {String project = 'Cacau Sul da Bahia', Map<String, List<String>> thumbs = const {}}) =>
      ReportInput(
        samples: samples,
        templates: {cacauTemplate.id: cacauTemplate},
        settings: AppSettings(project: project),
        generatedAt: DateTime(2026, 11, 12, 10, 0),
        templateHtml: template,
        leafletJs: '/* leaflet js */ var L={};',
        leafletCss: '.leaflet{}',
        thumbnails: thumbs,
      );

  Map<String, Object?> embeddedJson(String html) {
    final m = RegExp(r'<script type="application/json" id="samples-data">(.*?)</script>', dotAll: true).firstMatch(html)!;
    return (jsonDecode(m.group(1)!) as Map).cast<String, Object?>();
  }

  group('escapeHtml', () {
    test('escapa os 5 caracteres especiais', () {
      expect(escapeHtml('<a href="x" title=\'y\'>&</a>'),
          '&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;&amp;&lt;/a&gt;');
    });
    test('remove caracteres de controle e mantém acentos', () {
      expect(escapeHtml('Ilhéus\u0000\u0007 °C\n'), 'Ilhéus °C\n');
      expect(escapeHtml(null), '');
    });
  });

  test('jsonForScript não permite fechar a tag script', () {
    final out = jsonForScript({'x': '</script><script>alert(1)</script>&'});
    expect(out, isNot(contains('<')));
    expect(out, isNot(contains('>')));
    expect(jsonDecode(out), {'x': '</script><script>alert(1)</script>&'});
  });

  test('nome do arquivo segue o padrão', () {
    expect(reportFileName('Cacau Sul da Bahia', DateTime(2026, 11, 12)),
        'SampleTag_Relatorio_Cacau_Sul_da_Bahia_2026-11-12.html');
    expect(reportFileName('Expedição Ilhéus/Una', DateTime(2026, 1, 2)),
        'SampleTag_Relatorio_Expedicao_Ilheus_Una_2026-01-02.html');
    expect(reportFileName('', DateTime(2026, 1, 2)), 'SampleTag_Relatorio_Geral_2026-01-02.html');
  });

  group('relatório completo', () {
    late String html;
    setUp(() => html = const HtmlReportBuilder().build(input(demoSamples())));

    test('todos os placeholders foram preenchidos', () {
      expect(RegExp(r'\{\{[A-Z_]+\}\}').hasMatch(html), isFalse);
    });

    test('é autocontido: sem scripts, estilos ou imagens externas', () {
      expect(RegExp(r'<script[^>]+src=').hasMatch(html), isFalse);
      expect(RegExp(r'<link[^>]+stylesheet').hasMatch(html), isFalse);
      expect(RegExp(r'<img[^>]+src="https?:').hasMatch(html), isFalse);
      expect(html, contains('/* leaflet js */'));
      expect(html, contains('.leaflet{}'));
    });

    test('cabeçalho com projeto, período, total e totais por grupo', () {
      expect(html, contains('<h1>Cacau Sul da Bahia</h1>'));
      expect(html, contains('03/11/2026 a 06/11/2026'));
      expect(html, contains('5 amostras'));
      expect(html, contains('Ana Souza <b>2</b>'));
      expect(html, contains('Ilhéus/BA <b>1</b>'));
    });

    test('tabela, fichas, QR SVG e mapa SVG para cada amostra', () {
      expect(RegExp(r'<tr data-idx="\d+"').allMatches(html).length, 5);
      expect(RegExp(r'<article class="card sheet"').allMatches(html).length, 5);
      expect('FICHA DE AMOSTRA - CACAU'.allMatches(html).length, 5);
      expect(RegExp(r'<div class="qr"><svg').allMatches(html).length, 5);
      expect(RegExp(r'<g class="pt" data-idx="\d+"').allMatches(html).length, 5);
      expect(html, contains('Armazenar a -20 °C (Análise de DNA/RNA)'));
    });

    test('JSON bruto contém todos os dados', () {
      final data = embeddedJson(html);
      final samples = data['samples'] as List;
      expect(samples, hasLength(5));
      expect((samples.first as Map)['sampleCode'], 'CAC-2026-0001');
      expect((samples.first as Map)['customFields'], containsPair('tecido', 'Folha jovem'));
      expect(data['csvFileName'], 'SampleTag_Relatorio_Cacau_Sul_da_Bahia_2026-11-12.csv');
    });
  });

  test('ícone no cabeçalho e como favicon; SVG com script é recusado', () async {
    final icon = await File('assets/icon/sampletag_icon.svg').readAsString();
    final base = input(demoSamples());
    ReportInput withIcon(String svg) => ReportInput(
          samples: base.samples, templates: base.templates, settings: base.settings, generatedAt: base.generatedAt,
          templateHtml: base.templateHtml, leafletJs: base.leafletJs, leafletCss: base.leafletCss, iconSvg: svg,
        );
    final html = const HtmlReportBuilder().build(withIcon(icon));
    expect(html, contains('<span class="brand-mark" aria-hidden="true"><svg'));
    expect(html, contains('<link rel="icon" type="image/svg+xml" href="data:image/svg+xml;base64,'));
    final evil = const HtmlReportBuilder().build(withIcon('<svg onload="alert(1)"></svg>'));
    expect(evil, isNot(contains('onload')));
  });

  test('textos do usuário são escapados (injeção de HTML)', () {
    const evil = '<img src=x onerror=alert(1)>';
    final s = demoSamples().first.copyWith(
      sampleCode: 'CAC-<b>1</b>',
      collectorName: evil,
      notes: '</script><script>alert("x")</script>',
      originProperty: '{{SHEETS}}',
      customFields: {'tecido': '"><svg onload=alert(1)>'},
    );
    final html = const HtmlReportBuilder().build(input([s], project: '<script>alert(2)</script>'));
    expect(html, isNot(contains(evil)));
    expect(html, isNot(contains('<script>alert')));
    expect(html, isNot(contains('<svg onload')));
    expect(html, contains('&lt;img src=x onerror=alert(1)&gt;'));
    // O placeholder digitado pelo usuário não é expandido (substituição em uma passada).
    expect(html, contains('{{SHEETS}}'));
    // Só os blocos <script> do template: dados, limites, Leaflet e app.
    expect('<script'.allMatches(html).length, 4);
    // E o JSON continua íntegro.
    final data = embeddedJson(html);
    expect(((data['samples'] as List).first as Map)['collectorName'], evil);
  });

  test('miniaturas viram data URIs e lixo no base64 é removido', () {
    final s = demoSamples().first;
    final html = const HtmlReportBuilder().build(input([s], thumbs: {s.id: ['QUJD"onerror="x', 'REVG']}));
    expect(html, contains('src="data:image/jpeg;base64,QUJDonerror=x"'));
    expect(html, contains('src="data:image/jpeg;base64,REVG"'));
  });

  test('sem amostras e sem coordenadas não quebra', () {
    final empty = const HtmlReportBuilder().build(input(const []));
    expect(empty, contains('Nenhuma amostra'));
    final noGps = demoSamples().first.copyWith();
    final s = Sample.fromJson({...noGps.toJson(), 'latitude': null, 'longitude': null});
    final html = const HtmlReportBuilder().build(input([s]));
    expect(html, contains('Nenhuma amostra com coordenadas.'));
    expect(html, contains('1 amostra sem coordenadas'));
  });

  test('limites IBGE entram no SVG e no JSON de limites', () async {
    final lib = GeoLibrary((path) => File(path).readAsString());
    final geo = await ReportGeo.build(lib, highlighted: {'BA'}, includeMunicipalities: true);
    final base = input(demoSamples());
    final html = const HtmlReportBuilder().build(ReportInput(
      samples: base.samples, templates: base.templates, settings: base.settings, generatedAt: base.generatedAt,
      templateHtml: base.templateHtml, leafletJs: base.leafletJs, leafletCss: base.leafletCss, geo: geo,
    ));
    final m = RegExp(r'<script type="application/json" id="geo-data">(.*?)</script>', dotAll: true).firstMatch(html)!;
    final data = jsonDecode(m.group(1)!) as Map;
    expect((data['states'] as List), hasLength(27));
    expect((data['municipalities'] as List).map((e) => (e as Map)['n']), contains('Ilhéus'));
    // SVG: municípios do enquadramento aparecem com nome.
    expect(html, contains('<title>Ilhéus</title>'));
    // Tamanho sob controle (Bahia inteira com municípios).
    expect(m.group(1)!.length, lessThan(400 * 1024));
  });

  test('mapa SVG tem grade, escala e projeção coerente', () {
    final svg = const HtmlReportBuilder().buildSvgMap(demoSamples(), {cacauTemplate.id: cacauTemplate});
    expect(svg, startsWith('<svg'));
    expect(svg, contains('km</text>'));
    expect(svg, contains('°S'));
    expect(svg, contains('°O'));
    // Ilhéus (lat -14.79) deve ficar acima de Camacan (lat -15.41).
    double cy(String code) {
      final m = RegExp('<title>${RegExp.escape(code)}[^<]*</title><circle cx="([\\d.]+)" cy="([\\d.]+)"').firstMatch(svg)!;
      return double.parse(m.group(2)!);
    }
    expect(cy('CAC-2026-0001'), lessThan(cy('CAC-2026-0005')));
  });
}
