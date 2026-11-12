// Gera um relatório HTML de demonstração com as 5 amostras de exemplo
// (fazendas de cacau no sul da Bahia), sem precisar de aparelho:
//
//   dart run tool/generate_demo_report.dart [pasta-de-saída]
//
// Saída padrão: demo/SampleTag_Relatorio_Cacau_Sul_da_Bahia_<data>.html

import 'dart:io';

import 'package:sampletag/domain/geo.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/html_report_builder.dart';

Future<void> main(List<String> args) async {
  final outDir = Directory(args.isNotEmpty ? args.first : 'demo');
  await outDir.create(recursive: true);

  const settings = AppSettings(
    collectorName: 'Ana Souza',
    project: 'Cacau Sul da Bahia',
  );
  final samples = demoSamples();
  final geo = await ReportGeo.build(
    GeoLibrary((path) => File(path).readAsString()),
    highlighted: effectiveStates(samples.map((s) => s.state), settings.mapStates),
    includeMunicipalities: settings.municipalBoundaries,
  );
  final now = DateTime.now();
  final html = const HtmlReportBuilder().build(ReportInput(
    samples: samples,
    geo: geo,
    templates: {cacauTemplate.id: cacauTemplate},
    settings: settings,
    generatedAt: now,
    templateHtml: await File('assets/report/template.html').readAsString(),
    leafletJs: await File('assets/report/leaflet.min.js').readAsString(),
    leafletCss: await File('assets/report/leaflet.min.css').readAsString(),
    iconSvg: await File('assets/icon/sampletag_icon.svg').readAsString(),
  ));

  final file = File('${outDir.path}/${reportFileName(settings.project, now)}');
  await file.writeAsString(html);
  stdout.writeln('Relatório gerado: ${file.path} (${(html.length / 1024).toStringAsFixed(0)} KB)');
}
