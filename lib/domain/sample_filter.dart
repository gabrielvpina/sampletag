// Filtros e ordenação da lista de amostras. Dart puro.

import 'models.dart';

enum SampleSort {
  newest('Mais recentes'),
  oldest('Mais antigas'),
  code('Código'),
  municipality('Município');

  const SampleSort(this.label);
  final String label;
}

class SampleFilter {
  const SampleFilter({
    this.query = '',
    this.templateId,
    this.collector,
    this.municipality,
    this.from,
    this.to,
    this.sort = SampleSort.newest,
  });

  final String query;
  final String? templateId;
  final String? collector;
  final String? municipality;

  /// Intervalo de datas (inclusivo, por dia).
  final DateTime? from;
  final DateTime? to;
  final SampleSort sort;

  bool get isActive =>
      query.trim().isNotEmpty ||
      templateId != null ||
      collector != null ||
      municipality != null ||
      from != null ||
      to != null;

  /// Quantidade de filtros (sem contar busca e ordenação), para o badge.
  int get activeCount => [templateId, collector, municipality, from ?? to].where((e) => e != null).length;

  SampleFilter copyWith({
    String? query,
    String? Function()? templateId,
    String? Function()? collector,
    String? Function()? municipality,
    DateTime? Function()? from,
    DateTime? Function()? to,
    SampleSort? sort,
  }) =>
      SampleFilter(
        query: query ?? this.query,
        templateId: templateId != null ? templateId() : this.templateId,
        collector: collector != null ? collector() : this.collector,
        municipality: municipality != null ? municipality() : this.municipality,
        from: from != null ? from() : this.from,
        to: to != null ? to() : this.to,
        sort: sort ?? this.sort,
      );

  SampleFilter cleared() => SampleFilter(sort: sort);

  List<Sample> apply(List<Sample> input, Map<String, SampleTemplate> templates) {
    final q = _norm(query.trim());
    final out = input.where((s) {
      if (templateId != null && s.templateId != templateId) return false;
      if (collector != null && s.collectorName != collector) return false;
      if (municipality != null && s.municipality != municipality) return false;
      final day = DateTime(s.collectedAt.year, s.collectedAt.month, s.collectedAt.day);
      if (from != null && day.isBefore(DateTime(from!.year, from!.month, from!.day))) return false;
      if (to != null && day.isAfter(DateTime(to!.year, to!.month, to!.day))) return false;
      if (q.isEmpty) return true;
      final hay = _norm([
        s.sampleCode, s.collectorName, s.cloneGenotype, s.originProperty, s.municipality,
        s.state, s.notes, templates[s.templateId]?.name ?? '',
        ...s.customFields.values.map((v) => v?.toString() ?? ''),
      ].join(' '));
      return hay.contains(q);
    }).toList();

    int cmp(Sample a, Sample b) => switch (sort) {
          SampleSort.newest => b.collectedAt.compareTo(a.collectedAt),
          SampleSort.oldest => a.collectedAt.compareTo(b.collectedAt),
          SampleSort.code => a.sampleCode.compareTo(b.sampleCode),
          SampleSort.municipality => _norm(a.place).compareTo(_norm(b.place)),
        };
    out.sort(cmp);
    return out;
  }

  static String _norm(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }
}
