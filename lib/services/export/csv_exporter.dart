// Exportação CSV. Dart puro.

import '../../core/format.dart';
import '../../domain/models.dart';

/// Gera CSV (UTF-8 com BOM, separador `;` — padrão do Excel em pt-BR).
///
/// Colunas fixas seguidas de uma coluna por campo personalizado (união dos
/// campos de todos os modelos envolvidos, na ordem em que aparecem).
class CsvExporter {
  const CsvExporter({this.delimiter = ';', this.includeBom = true});

  final String delimiter;
  final bool includeBom;

  static const fixedHeaders = [
    'codigo', 'modelo', 'categoria', 'data_coleta', 'coletor', 'contato',
    'clone_genotipo', 'origem_propriedade', 'municipio', 'uf', 'latitude',
    'longitude', 'altitude_m', 'precisao_gps_m', 'fotos', 'observacoes',
    'armazenamento', 'id',
  ];

  String export(List<Sample> samples, Map<String, SampleTemplate> templates) {
    // Campos personalizados: chave -> rótulo, sem repetir.
    final custom = <String, String>{};
    for (final s in samples) {
      for (final f in templates[s.templateId]?.fields ?? const <TemplateField>[]) {
        custom.putIfAbsent(f.key, () => f.label);
      }
      for (final k in s.customFields.keys) {
        custom.putIfAbsent(k, () => k);
      }
    }

    final buf = StringBuffer();
    if (includeBom) buf.write('\uFEFF');
    _row(buf, [...fixedHeaders, ...custom.values]);
    for (final s in samples) {
      _row(buf, [
        s.sampleCode,
        templates[s.templateId]?.name ?? '',
        s.category.label,
        fmtDateTime(s.collectedAt),
        s.collectorName,
        s.collectorContact,
        s.cloneGenotype,
        s.originProperty,
        s.municipality,
        s.state,
        fmtCoord(s.latitude),
        fmtCoord(s.longitude),
        s.altitude?.toStringAsFixed(1) ?? '',
        s.gpsAccuracyMeters?.toStringAsFixed(1) ?? '',
        s.photos.length.toString(),
        s.notes,
        s.storageInstruction,
        s.id,
        for (final k in custom.keys) fmtCustomValue(s.customFields[k]),
      ]);
    }
    return buf.toString();
  }

  void _row(StringBuffer buf, List<String> cells) {
    buf.write(cells.map(escape).join(delimiter));
    buf.write('\r\n');
  }

  /// Aspas quando houver separador, aspas, quebra de linha ou espaços nas
  /// pontas. Também neutraliza injeção de fórmula em planilhas (=, +, -, @)
  /// prefixando com apóstrofo quando o texto não é um número.
  String escape(String v) {
    var out = v;
    if (out.isNotEmpty &&
        '=+-@\t\r'.contains(out[0]) &&
        double.tryParse(out.replaceAll(',', '.')) == null) {
      out = "'$out";
    }
    final needsQuotes = out.contains(delimiter) ||
        out.contains('"') ||
        out.contains('\n') ||
        out.contains('\r') ||
        out != out.trim();
    if (!needsQuotes) return out;
    return '"${out.replaceAll('"', '""')}"';
  }
}
