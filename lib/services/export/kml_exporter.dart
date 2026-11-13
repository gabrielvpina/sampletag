// Exportação KML (Google Earth / QGIS). Dart puro.

import '../../core/format.dart';
import '../../domain/models.dart';

class KmlExporter {
  const KmlExporter();

  /// Gera um documento KML com uma pasta por modelo, estilos coloridos e
  /// `ExtendedData` com todos os campos (o QGIS importa como atributos).
  String export(
    List<Sample> samples,
    Map<String, SampleTemplate> templates, {
    String documentName = 'SampleTag',
    Map<String, String>? codesById,
  }) {
    final codes = codesById ?? codesByIdOf(samples);
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
      ..writeln('<Document>')
      ..writeln('<name>${xml(documentName)}</name>');

    final used = samples.where((s) => s.hasLocation).toList();
    final byTemplate = <String, List<Sample>>{};
    for (final s in used) {
      byTemplate.putIfAbsent(s.templateId, () => []).add(s);
    }

    for (final id in byTemplate.keys) {
      final color = templates[id]?.color ?? 0xFF3D5C40;
      buf
        ..writeln('<Style id="${xml(_styleId(id))}">')
        ..writeln('<IconStyle><color>${kmlColor(color)}</color><scale>1.1</scale>'
            '<Icon><href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href></Icon></IconStyle>')
        ..writeln('</Style>');
    }

    for (final entry in byTemplate.entries) {
      final t = templates[entry.key];
      buf.writeln('<Folder><name>${xml(t?.name ?? entry.key)}</name>');
      for (final s in entry.value) {
        buf
          ..writeln('<Placemark>')
          ..writeln('<name>${xml(s.sampleCode)}</name>')
          ..writeln('<TimeStamp><when>${s.collectedAt.toUtc().toIso8601String()}</when></TimeStamp>')
          ..writeln('<styleUrl>#${xml(_styleId(s.templateId))}</styleUrl>')
          ..writeln('<description>${xml(_description(s, t))}</description>')
          ..writeln('<ExtendedData>');
        void data(String name, String value) =>
            buf.writeln('<Data name="${xml(name)}"><value>${xml(value)}</value></Data>');
        data('modelo', t?.name ?? '');
        data('categoria', s.category.label);
        data('amostra_origem', parentCodeOf(s, codes));
        data('data_coleta', fmtDateTime(s.collectedAt));
        data('coletor', s.collectorName);
        data('clone_genotipo', s.cloneGenotype);
        data('origem_propriedade', s.originProperty);
        data('municipio', s.municipality);
        data('uf', s.state);
        data('altitude_m', s.altitude?.toStringAsFixed(1) ?? '');
        data('precisao_gps_m', s.gpsAccuracyMeters?.toStringAsFixed(1) ?? '');
        data('observacoes', s.notes);
        for (final f in t?.fields ?? const <TemplateField>[]) {
          data(f.label, fmtCustomValue(s.customFields[f.key]));
        }
        buf
          ..writeln('</ExtendedData>')
          // KML usa longitude,latitude[,altitude].
          ..writeln('<Point><coordinates>${s.longitude},${s.latitude}'
              '${s.altitude != null ? ',${s.altitude}' : ''}</coordinates></Point>')
          ..writeln('</Placemark>');
      }
      buf.writeln('</Folder>');
    }

    buf
      ..writeln('</Document>')
      ..writeln('</kml>');
    return buf.toString();
  }

  String _description(Sample s, SampleTemplate? t) => [
        'Data: ${fmtDateTime(s.collectedAt)}',
        if (s.collectorName.isNotEmpty) 'Coletor: ${s.collectorName}',
        if (s.cloneGenotype.isNotEmpty) 'Clone/genótipo: ${s.cloneGenotype}',
        if (s.originProperty.isNotEmpty) 'Origem: ${s.originProperty}',
        if (s.place.isNotEmpty) 'Município: ${s.place}',
      ].join('\n');

  String _styleId(String templateId) =>
      'tpl-${templateId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';

  /// KML usa aabbggrr.
  static String kmlColor(int argb) {
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    final a = (argb >> 24) & 0xFF, r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
    return '${h(a)}${h(b)}${h(g)}${h(r)}';
  }

  /// Escapa texto para XML.
  static String xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      // Remove caracteres de controle inválidos em XML 1.0.
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}
