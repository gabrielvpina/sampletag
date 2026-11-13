// Gera um relatório HTML de demonstração com as 5 amostras de exemplo
// (fazendas de cacau no sul da Bahia), sem precisar de aparelho:
//
//   dart run tool/generate_demo_report.dart [pasta-de-saída] [--pontos-proximos]
//
// Inclui uma amostra técnica derivada (DNA extraído da 1ª amostra).
// `--pontos-proximos` acrescenta plantas a poucos metros umas das outras,
// para conferir o zoom dos mapas.
//
// Saída padrão: demo/SampleTag_Relatorio_Cacau_Sul_da_Bahia_<data>.html

import 'dart:io';

import 'package:sampletag/domain/geo.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';
import 'package:sampletag/services/export/html_report_builder.dart';

Future<void> main(List<String> args) async {
  final close = args.contains('--pontos-proximos');
  final paths = args.where((a) => !a.startsWith('--')).toList();
  final outDir = Directory(paths.isNotEmpty ? paths.first : 'demo');
  await outDir.create(recursive: true);

  const settings = AppSettings(
    collectorName: 'Ana Souza',
    project: 'Cacau Sul da Bahia',
  );
  final demo = demoSamples();
  final first = demo.first;
  final samples = [
    ...demo,
    first.copyWith(
      sampleCode: '${first.sampleCode}-01',
      parentId: () => first.id,
      category: SampleCategory.technical,
      collectedAt: first.collectedAt.add(const Duration(days: 2)),
      photos: const [],
      notes: 'DNA extraído (CTAB), 85 ng/µL, A260/280 = 1,92.',
      storageInstruction: 'Armazenar a -80 °C',
    ).withId('demo-1-dna'),
    if (close)
      for (var i = 1; i <= 6; i++)
        first.copyWith(
          sampleCode: '${first.sampleCode.replaceAll('0001', '01')}${i + 1}',
          latitude: first.latitude! + 0.00012 * i,
          longitude: first.longitude! + 0.00009 * (i % 3),
          cloneGenotype: 'Planta $i',
        ).withId('perto-$i'),
  ];
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

extension on Sample {
  Sample withId(String id) => Sample.fromJson({...toJson(), 'id': id});
}
