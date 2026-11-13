// Gerador do relatório HTML autocontido. Dart puro (sem Flutter), para ser
// testável e usável pela ferramenta de demonstração.
//
// O HTML final é montado a partir de `assets/report/template.html`, cujos
// placeholders `{{NOME}}` são substituídos numa única passada — assim, um
// texto digitado pelo usuário contendo "{{SHEETS}}" nunca é reinterpretado.

import 'dart:convert';
import 'dart:math' as math;

import '../../core/format.dart';
import '../../domain/geo.dart';
import '../../domain/models.dart';
import 'qr_payload.dart';
import 'qr_svg.dart';

/// Dados de entrada do relatório.
class ReportInput {
  const ReportInput({
    required this.samples,
    required this.templates,
    required this.settings,
    required this.generatedAt,
    required this.templateHtml,
    required this.leafletJs,
    required this.leafletCss,
    this.thumbnails = const {},
    this.title,
    this.geo,
    this.iconSvg = '',
    this.codesById,
  });

  /// id -> código de todas as amostras do aparelho, para mostrar a amostra
  /// de origem mesmo quando ela não está no relatório.
  final Map<String, String>? codesById;

  final List<Sample> samples;
  final Map<String, SampleTemplate> templates;
  final AppSettings settings;
  final DateTime generatedAt;

  /// Conteúdo de `assets/report/template.html`.
  final String templateHtml;
  final String leafletJs;
  final String leafletCss;

  /// Miniaturas JPEG em base64 por id da amostra (vazio = sem fotos).
  final Map<String, List<String>> thumbnails;
  final String? title;

  /// Limites de estados/municípios para o mapa base offline.
  final ReportGeo? geo;

  /// Ícone do app (assets/icon/sampletag_icon.svg), usado no cabeçalho e
  /// como favicon. Vazio = sem ícone.
  final String iconSvg;
}

/// Escapa texto para conteúdo e atributos HTML.
String escapeHtml(String? s) {
  if (s == null || s.isEmpty) return '';
  final b = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x26:
        b.write('&amp;');
      case 0x3C:
        b.write('&lt;');
      case 0x3E:
        b.write('&gt;');
      case 0x22:
        b.write('&quot;');
      case 0x27:
        b.write('&#39;');
      default:
        // Remove caracteres de controle (exceto \t \n \r).
        if (r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D) continue;
        b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// JSON seguro para ficar dentro de `<script type="application/json">`:
/// `<`, `>` e `&` viram escapes Unicode, impedindo `</script>` de fechar o
/// bloco; U+2028/2029 também são escapados.
String jsonForScript(Object? value) => jsonEncode(value)
    .replaceAll('<', r'\u003c')
    .replaceAll('>', r'\u003e')
    .replaceAll('&', r'\u0026')
    .replaceAll('\u2028', r'\u2028')
    .replaceAll('\u2029', r'\u2029');

/// Texto seguro dentro de `<script>`/`<style>` (código de terceiros como o
/// Leaflet): neutraliza qualquer `</script` ou `</style` acidental.
String _rawTextSafe(String code, String tag) =>
    code.replaceAll(RegExp('</($tag)', caseSensitive: false), r'<\/$1');

/// Nome do arquivo: `SampleTag_Relatorio_{projeto}_{AAAA-MM-DD}.html`.
String reportFileName(String project, DateTime date) {
  final p = safeFileName(project);
  return 'SampleTag_Relatorio_${p.isEmpty ? 'Geral' : p}_${fmtIsoDate(date)}.html';
}

class HtmlReportBuilder {
  const HtmlReportBuilder();

  String build(ReportInput input) {
    // Ordena por data de coleta para tabela e fichas.
    final samples = [...input.samples]..sort((a, b) => a.collectedAt.compareTo(b.collectedAt));
    final templates = input.templates;
    final project = input.settings.project.trim();
    final heading = input.title ?? (project.isEmpty ? 'Relatório de amostras' : project);

    final customFields = _customFieldUnion(samples, templates);
    final codes = {...codesByIdOf(samples), ...?input.codesById};

    final values = <String, String>{
      'TITLE': escapeHtml('SampleTag — $heading'),
      'ICON_SVG': _inlineSvg(input.iconSvg),
      'FAVICON': input.iconSvg.isEmpty ? '' : 'data:image/svg+xml;base64,${base64Encode(utf8.encode(input.iconSvg))}',
      'HEADING': escapeHtml(heading),
      'META': _meta(samples, input),
      'STATS': _stats(samples, templates),
      'MAP_NOTICE': escapeHtml(_mapNotice(samples)),
      'SVG_MAP': buildSvgMap(samples, templates, geo: input.geo),
      'LEGEND': _legend(samples, templates),
      'TEMPLATE_OPTIONS': _templateOptions(samples, templates),
      'TABLE_HEAD': _tableHead(customFields),
      'TABLE_ROWS': _tableRows(samples, templates, customFields, codes),
      'SHEETS': _sheets(samples, templates, input.thumbnails, codes),
      'GENERATED_AT': escapeHtml(fmtDateTime(input.generatedAt)),
      'DATA_JSON': jsonForScript(_data(samples, templates, input, codes)),
      'GEO_JSON': jsonForScript(input.geo?.toJson() ?? const {}),
      'LEAFLET_JS': _rawTextSafe(input.leafletJs, 'script'),
      'LEAFLET_CSS': _rawTextSafe(input.leafletCss, 'style'),
    };

    return input.templateHtml.replaceAllMapped(RegExp(r'\{\{([A-Z_]+)\}\}'), (m) {
      return values[m.group(1)] ?? m.group(0)!;
    });
  }

  // ---------------------------------------------------------------------------

  List<TemplateField> _customFieldUnion(List<Sample> samples, Map<String, SampleTemplate> t) {
    final seen = <String>{};
    final out = <TemplateField>[];
    for (final s in samples) {
      for (final f in t[s.templateId]?.fields ?? const <TemplateField>[]) {
        if (seen.add(f.key)) out.add(f);
      }
    }
    return out;
  }

  String _meta(List<Sample> samples, ReportInput input) {
    final parts = <String>[];
    if (input.settings.project.trim().isNotEmpty) {
      parts.add('<span><b>Projeto/expedição:</b> ${escapeHtml(input.settings.project.trim())}</span>');
    }
    if (samples.isNotEmpty) {
      final first = samples.first.collectedAt, last = samples.last.collectedAt;
      final period = fmtDate(first) == fmtDate(last)
          ? fmtDate(first)
          : '${fmtDate(first)} a ${fmtDate(last)}';
      parts.add('<span><b>Período das coletas:</b> ${escapeHtml(period)}</span>');
    }
    parts.add('<span><b>Gerado em:</b> ${escapeHtml(fmtDateTime(input.generatedAt))}</span>');
    parts.add('<span><b>Total:</b> ${samples.length} amostra${samples.length == 1 ? '' : 's'}</span>');
    return parts.join();
  }

  String _stats(List<Sample> samples, Map<String, SampleTemplate> templates) {
    Map<String, int> countBy(String Function(Sample) key) {
      final m = <String, int>{};
      for (final s in samples) {
        final k = key(s).trim().isEmpty ? '(não informado)' : key(s).trim();
        m[k] = (m[k] ?? 0) + 1;
      }
      final entries = m.entries.toList()
        ..sort((a, b) => b.value != a.value ? b.value - a.value : a.key.compareTo(b.key));
      return Map.fromEntries(entries);
    }

    String chips(Map<String, int> m, {String Function(String)? color}) => m.isEmpty
        ? '<span class="chip">—</span>'
        : m.entries
            .map((e) =>
                '<span class="chip">${color != null ? '<span class="dot" style="background:${color(e.key)}"></span>' : ''}'
                '${escapeHtml(e.key)} <b>${e.value}</b></span>')
            .join();

    final byTemplate = countBy((s) => templates[s.templateId]?.name ?? s.templateId);
    final colorByName = {for (final t in templates.values) t.name: t.colorHex};
    final withGps = samples.where((s) => s.hasLocation).length;

    return '''
<div class="card stat"><h3>Total de amostras</h3><div class="big">${samples.length}</div><div class="count">$withGps com coordenadas</div></div>
<div class="card stat"><h3>Por modelo</h3><div class="chips">${chips(byTemplate, color: (n) => _safeColor(colorByName[n]))}</div></div>
<div class="card stat"><h3>Por coletor</h3><div class="chips">${chips(countBy((s) => s.collectorName))}</div></div>
<div class="card stat"><h3>Por município</h3><div class="chips">${chips(countBy((s) => s.place))}</div></div>''';
  }

  String _mapNotice(List<Sample> samples) {
    final missing = samples.where((s) => !s.hasLocation).length;
    return missing == 0 ? '' : '$missing amostra${missing == 1 ? '' : 's'} sem coordenadas não aparece${missing == 1 ? '' : 'm'} no mapa.';
  }

  String _legend(List<Sample> samples, Map<String, SampleTemplate> templates) {
    final ids = samples.map((s) => s.templateId).toSet();
    return ids
        .map((id) => templates[id])
        .whereType<SampleTemplate>()
        .map((t) =>
            '<span class="chip"><span class="dot" style="background:${_safeColor(t.colorHex)}"></span>${escapeHtml(t.name)}</span>')
        .join();
  }

  String _templateOptions(List<Sample> samples, Map<String, SampleTemplate> templates) {
    final ids = samples.map((s) => s.templateId).toSet();
    return ids
        .map((id) => templates[id])
        .whereType<SampleTemplate>()
        .map((t) => '<option value="${escapeHtml(t.id)}">${escapeHtml(t.name)}</option>')
        .join();
  }

  static const _fixedColumns = <(String, bool)>[
    ('Código', false), ('Modelo', false), ('Categoria', false), ('Amostra de origem', false), ('Data da coleta', false),
    ('Coletor', false), ('Contato', false), ('Clone/genótipo', false), ('Origem/propriedade', false),
    ('Município/UF', false), ('Latitude', true), ('Longitude', true), ('Altitude (m)', true),
    ('Precisão GPS (m)', true), ('Fotos', true), ('Observações', false), ('Armazenamento', false),
  ];

  String _tableHead(List<TemplateField> custom) {
    final b = StringBuffer();
    for (final (label, numeric) in _fixedColumns) {
      b.write('<th scope="col"${numeric ? ' data-type="num"' : ''}>${escapeHtml(label)}</th>');
    }
    for (final f in custom) {
      b.write('<th scope="col"${f.type == FieldType.number ? ' data-type="num"' : ''}>${escapeHtml(f.label)}</th>');
    }
    return b.toString();
  }

  String _tableRows(List<Sample> samples, Map<String, SampleTemplate> templates, List<TemplateField> custom,
      Map<String, String> codes) {
    final b = StringBuffer();
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final t = templates[s.templateId];
      String td(String text, {String? sortValue, bool num = false, bool wrap = false}) {
        final cls = [if (num) 'num', if (wrap) 'wrap-text'].join(' ');
        return '<td${cls.isEmpty ? '' : ' class="$cls"'}'
            '${sortValue != null ? ' data-v="${escapeHtml(sortValue)}"' : ''}>${escapeHtml(text)}</td>';
      }

      String n(double? v, int d) => v == null ? '' : v.toStringAsFixed(d);
      b.write('<tr data-idx="$i" data-tpl="${escapeHtml(s.templateId)}">');
      b.write('<td><span class="dot" style="background:${_safeColor(t?.colorHex)}"></span> <b>${escapeHtml(s.sampleCode)}</b></td>');
      b.write(td(t?.name ?? ''));
      b.write(td(s.category.label));
      b.write(td(parentCodeOf(s, codes)));
      b.write(td(fmtDateTime(s.collectedAt), sortValue: s.collectedAt.toIso8601String()));
      b.write(td(s.collectorName));
      b.write(td(s.collectorContact));
      b.write(td(s.cloneGenotype));
      b.write(td(s.originProperty));
      b.write(td(s.place));
      b.write(td(fmtCoord(s.latitude), sortValue: n(s.latitude, 6), num: true));
      b.write(td(fmtCoord(s.longitude), sortValue: n(s.longitude, 6), num: true));
      b.write(td(n(s.altitude, 1), sortValue: n(s.altitude, 3), num: true));
      b.write(td(n(s.gpsAccuracyMeters, 1), sortValue: n(s.gpsAccuracyMeters, 3), num: true));
      b.write(td('${s.photos.length}', sortValue: '${s.photos.length}', num: true));
      b.write(td(s.notes, wrap: true));
      b.write(td(s.storageInstruction, wrap: true));
      for (final f in custom) {
        final v = s.customFields[f.key];
        b.write(td(fmtCustomValue(v),
            sortValue: f.type == FieldType.number ? (v is num ? '$v' : '') : null,
            num: f.type == FieldType.number));
      }
      b.write('</tr>');
    }
    if (samples.isEmpty) {
      b.write('<tr><td class="empty" colspan="${_fixedColumns.length + custom.length}">Nenhuma amostra.</td></tr>');
    }
    return b.toString();
  }

  String _sheets(List<Sample> samples, Map<String, SampleTemplate> templates, Map<String, List<String>> thumbs,
      Map<String, String> codes) {
    if (samples.isEmpty) return '<div class="card empty">Nenhuma amostra.</div>';
    final b = StringBuffer();
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final t = templates[s.templateId];
      final fields = <(String, String)>[
        ('Data/hora da coleta', fmtDateTime(s.collectedAt)),
        ('Categoria', s.category.label),
        ('Amostra de origem', parentCodeOf(s, codes)),
        ('Coletor', s.collectorName),
        ('Contato', s.collectorContact),
        ('Clone/genótipo', s.cloneGenotype),
        ('Origem/propriedade', s.originProperty),
        ('Município/UF', s.place),
        ('Latitude, longitude', fmtLatLon(s.latitude, s.longitude)),
        ('Altitude', fmtMeters(s.altitude)),
        ('Precisão do GPS', fmtMeters(s.gpsAccuracyMeters)),
        for (final f in t?.fields ?? const <TemplateField>[])
          (f.label, fmtCustomValue(s.customFields[f.key])),
        // Campos que existem na amostra mas não (mais) no modelo.
        for (final e in s.customFields.entries)
          if (!(t?.fields.any((f) => f.key == e.key) ?? false)) (e.key, fmtCustomValue(e.value)),
      ];
      final dl = fields
          .where((f) => f.$2.trim().isNotEmpty)
          .map((f) => '<div><dt>${escapeHtml(f.$1)}</dt><dd>${escapeHtml(f.$2)}</dd></div>')
          .join();
      final photos = thumbs[s.id] ?? const [];
      final photoHtml = photos.isEmpty
          ? ''
          : '<div class="photos">${[
              for (var k = 0; k < photos.length; k++)
                '<img loading="lazy" alt="${escapeHtml('Foto ${k + 1} de ${s.sampleCode}')}" '
                    'src="data:image/jpeg;base64,${_base64Only(photos[k])}">',
            ].join()}</div>';

      b.write('<article class="card sheet" id="sheet-$i" style="--tpl:${_safeColor(t?.colorHex)}">');
      b.write('<div class="sheet-head"><span class="t">FICHA DE AMOSTRA - ${escapeHtml((t?.name ?? '').toUpperCase())}</span>'
          '<span class="c">${escapeHtml(s.sampleCode)}</span></div>');
      b.write('<div class="sheet-body"><dl class="fields">$dl</dl>'
          '<div class="qr">${qrSvg(qrPayload(s, t), size: 132, title: 'QR ${s.sampleCode}')}<br>${escapeHtml(s.sampleCode)}</div></div>');
      if (s.notes.trim().isNotEmpty) {
        b.write('<div class="notes"><b>Observações:</b> ${escapeHtml(s.notes)}</div>');
      }
      b.write(photoHtml);
      if (s.storageInstruction.trim().isNotEmpty) {
        b.write('<div class="storage">${escapeHtml(s.storageInstruction)}</div>');
      }
      b.write('</article>');
    }
    return b.toString();
  }

  Map<String, Object?> _data(
      List<Sample> samples, Map<String, SampleTemplate> templates, ReportInput input, Map<String, String> codes) {
    final usedTemplates = samples.map((s) => s.templateId).toSet();
    return {
      'app': 'SampleTag',
      'generatedAt': input.generatedAt.toIso8601String(),
      'project': input.settings.project,
      'csvFileName': reportFileName(input.settings.project, input.generatedAt).replaceAll('.html', '.csv'),
      'templates': [
        for (final id in usedTemplates)
          if (templates[id] != null) templates[id]!.toJson(),
      ],
      'samples': [
        for (final s in samples)
          {
            ...s.toJson(),
            'template': templates[s.templateId]?.name ?? '',
            'categoryLabel': s.category.label,
            'parentCode': parentCodeOf(s, codes),
            'color': _safeColor(templates[s.templateId]?.colorHex),
          },
      ],
    };
  }

  /// SVG do ícone pronto para uso inline: sem declaração XML, sem scripts.
  static String _inlineSvg(String svg) {
    final start = svg.indexOf('<svg');
    if (start < 0) return '';
    final out = svg.substring(start).trim();
    // O ícone é um asset do app, mas por segurança recusa conteúdo ativo.
    if (RegExp(r'<script|\son\w+\s*=|javascript:', caseSensitive: false).hasMatch(out)) return '';
    return out;
  }

  /// Só aceita cores `#RRGGBB` (evita injeção via atributo style).
  static String _safeColor(String? c) =>
      c != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(c) ? c : '#3D5C40';

  static String _base64Only(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

  // ---------------------------------------------------------------------------
  // Mapa SVG offline (projeção equiretangular)
  // ---------------------------------------------------------------------------

  /// Gera o mapa SVG embutido: grade de latitude/longitude, escala em km e
  /// os pontos coloridos por modelo. A projeção é equiretangular com
  /// paralelo-padrão na latitude média (x = lon·cos φ0, y = lat), o que evita
  /// distorção visível em áreas pequenas.
  String buildSvgMap(List<Sample> samples, Map<String, SampleTemplate> templates, {ReportGeo? geo}) {
    final pts = <(int, Sample)>[
      for (var i = 0; i < samples.length; i++)
        if (samples[i].hasLocation) (i, samples[i]),
    ];
    // Sem pontos, enquadra as UFs em destaque (se houver).
    final focus = geo?.states.where((st) => geo.highlighted.contains(st.id)).toList() ?? const <GeoFeature>[];
    if (pts.isEmpty && focus.isEmpty) {
      return '<div class="empty">Nenhuma amostra com coordenadas.</div>';
    }

    double minLat, maxLat, minLon, maxLon;
    if (pts.isNotEmpty) {
      minLat = pts.map((p) => p.$2.latitude!).reduce(math.min);
      maxLat = pts.map((p) => p.$2.latitude!).reduce(math.max);
      minLon = pts.map((p) => p.$2.longitude!).reduce(math.min);
      maxLon = pts.map((p) => p.$2.longitude!).reduce(math.max);
    } else {
      minLat = focus.map((f) => f.bounds.minLat).reduce(math.min);
      maxLat = focus.map((f) => f.bounds.maxLat).reduce(math.max);
      minLon = focus.map((f) => f.bounds.minLon).reduce(math.min);
      maxLon = focus.map((f) => f.bounds.maxLon).reduce(math.max);
    }

    // Garante extensão mínima (~2 km, para dar contexto) e margem de 12%.
    // Pontos mais próximos que isso são separados com o zoom do relatório.
    const minSpan = 0.02;
    double padSpan(double lo, double hi) => math.max(hi - lo, minSpan);
    final latSpan0 = padSpan(minLat, maxLat), lonSpan0 = padSpan(minLon, maxLon);
    final cLat = (minLat + maxLat) / 2, cLon = (minLon + maxLon) / 2;
    minLat = cLat - latSpan0 * 0.62;
    maxLat = cLat + latSpan0 * 0.62;
    minLon = cLon - lonSpan0 * 0.62;
    maxLon = cLon + lonSpan0 * 0.62;

    final k = math.cos(cLat * math.pi / 180).abs().clamp(0.05, 1.0);
    const width = 1000.0;
    // Altura proporcional, limitada para não ficar extrema.
    var height = width * (maxLat - minLat) / ((maxLon - minLon) * k);
    if (height > 900) {
      // Área muito alta: amplia longitude para manter a proporção.
      final need = (maxLat - minLat) / (900 / width) / k;
      minLon = cLon - need / 2;
      maxLon = cLon + need / 2;
      height = 900;
    } else if (height < 360) {
      final need = 360 / width * (maxLon - minLon) * k;
      minLat = cLat - need / 2;
      maxLat = cLat + need / 2;
      height = 360;
    }
    double x(double lon) => (lon - minLon) / (maxLon - minLon) * width;
    double y(double lat) => (maxLat - lat) / (maxLat - minLat) * height;
    String f(double v) => v.toStringAsFixed(1);
    final kmPerUnit = (maxLon - minLon) * 111.32 * k / width;

    // Tudo dentro de #svg-view é ampliado/deslocado pelo zoom do relatório;
    // traços não engrossam (non-scaling-stroke) e pontos/rótulos são
    // reescalados pelo script para manter o tamanho na tela.
    final b = StringBuffer()
      ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${f(width)} ${f(height)}" '
          'data-km-per-unit="${kmPerUnit.toStringAsPrecision(6)}" '
          'role="img" aria-label="Mapa simplificado das amostras" font-family="system-ui,sans-serif">')
      ..write('<rect width="100%" height="100%" fill="#DCE5EA"/>')
      ..write('<g id="svg-view">');

    // Limites IBGE: só as áreas que aparecem no enquadramento.
    if (geo != null) {
      final view = GeoBounds(minLon, minLat, maxLon, maxLat);
      String path(GeoFeature feat) {
        final d = StringBuffer();
        for (final poly in feat.polygons) {
          for (final ring in poly) {
            double? lx, ly;
            var n = 0;
            for (final p in ring) {
              final px = x(p.lon), py = y(p.lat);
              // Pula pontos a menos de ~0,7 unidade do anterior.
              if (lx != null && (px - lx).abs() < 0.7 && (py - ly!).abs() < 0.7) continue;
              d.write(n == 0 ? 'M' : 'L');
              d.write('${f(px)} ${f(py)}');
              lx = px;
              ly = py;
              n++;
            }
            if (n > 0) d.write('Z');
          }
        }
        return d.toString();
      }

      final visibleStates = geo.states.where((st) => st.bounds.intersects(view)).toList();
      b.write('<g fill-rule="evenodd">');
      for (final st in visibleStates) {
        final hl = geo.highlighted.contains(st.id);
        b.write('<path d="${path(st)}" fill="${hl ? '#FBFBF5' : '#ECEEE6'}"/>');
      }
      b.write('</g><g fill="none" stroke="#BCC3B6" stroke-width="0.7" vector-effect="non-scaling-stroke">');
      for (final m in geo.municipalities.where((m) => m.bounds.intersects(view))) {
        b.write('<path d="${path(m)}"><title>${escapeHtml(m.name)}</title></path>');
      }
      b.write('</g><g fill="none" stroke="#7C877A" stroke-width="1.6" stroke-linejoin="round" vector-effect="non-scaling-stroke">');
      for (final st in visibleStates) {
        b.write('<path d="${path(st)}"/>');
      }
      b.write('</g>');
      // Rótulos das UFs no centro do enquadramento de cada uma (se couber).
      b.write('<g class="zoom-hide" fill="#7C877A" font-size="15" font-weight="700" text-anchor="middle" opacity=".55">');
      for (final st in visibleStates) {
        final cx = x(((st.bounds.minLon + st.bounds.maxLon) / 2).clamp(minLon, maxLon));
        final cy = y(((st.bounds.minLat + st.bounds.maxLat) / 2).clamp(minLat, maxLat));
        if (cx > 40 && cx < width - 40 && cy > 30 && cy < height - 30) {
          b.write('<text x="${f(cx)}" y="${f(cy)}">${escapeHtml(st.id)}</text>');
        }
      }
      b.write('</g>');
    }

    // Grade com passo "redondo" (1, 2, 5 × 10^n graus).
    final step = _niceStep((maxLon - minLon) / 6);
    b.write('<g class="zoom-hide" stroke="#C9CEBC" stroke-width="1" vector-effect="non-scaling-stroke">');
    final labels = StringBuffer('<g class="zoom-hide" fill="#5B665C" font-size="13">');
    for (var lon = (minLon / step).ceil() * step; lon <= maxLon; lon += step) {
      b.write('<line x1="${f(x(lon))}" y1="0" x2="${f(x(lon))}" y2="${f(height)}"/>');
      labels.write('<text x="${f(x(lon) + 4)}" y="${f(height - 8)}">${_deg(lon, 'L', 'O', step)}</text>');
    }
    for (var lat = (minLat / step).ceil() * step; lat <= maxLat; lat += step) {
      b.write('<line x1="0" y1="${f(y(lat))}" x2="${f(width)}" y2="${f(y(lat))}"/>');
      labels.write('<text x="6" y="${f(y(lat) - 5)}">${_deg(lat, 'N', 'S', step)}</text>');
    }
    b
      ..write('</g>')
      ..write(labels)
      ..write('</g>');

    // Pontos (rótulo com o código, título com detalhes). Cada ponto fica
    // num grupo posicionado; o grupo interno é reescalado no zoom.
    String g(double v) => v.toStringAsFixed(2);
    b.write('<g id="svg-pts">');
    for (final (i, s) in pts) {
      final t = templates[s.templateId];
      final px = x(s.longitude!), py = y(s.latitude!);
      b.write('<g class="pt" data-idx="$i" tabindex="0" transform="translate(${g(px)} ${g(py)})">'
          '<title>${escapeHtml('${s.sampleCode} — ${s.place} — ${fmtDate(s.collectedAt)}')}</title>'
          '<g class="pt-s"><circle r="9" fill="${_safeColor(t?.colorHex)}" stroke="#fff" stroke-width="2.5"/>'
          '<text x="13" y="4" font-size="13" font-weight="600" fill="#1D241E" '
          'stroke="#F2F4EC" stroke-width="3" paint-order="stroke">${escapeHtml(s.sampleCode)}</text></g></g>');
    }
    b.write('</g></g>'); // fecha #svg-pts e #svg-view

    // Barra de escala (atualizada pelo script conforme o zoom).
    final targetKm = kmPerUnit * 160;
    final barKm = _niceStep(targetKm);
    final barPx = barKm / kmPerUnit;
    final sx = width - barPx - 24, sy = 28.0;
    final label = barKm >= 1 ? '${_trim(barKm)} km' : '${(barKm * 1000).round()} m';
    b.write('<g id="svg-scale" data-right="${f(width - 24)}"><rect x="${f(sx - 8)}" y="${f(sy - 18)}" width="${f(barPx + 16)}" height="34" rx="6" fill="#fff" fill-opacity=".85"/>'
        '<path d="M${f(sx)} ${f(sy)}v8h${f(barPx)}v-8" fill="none" stroke="#1D241E" stroke-width="2"/>'
        '<text x="${f(sx + barPx / 2)}" y="${f(sy - 4)}" text-anchor="middle" font-size="13" fill="#1D241E">${escapeHtml(label)}</text></g>');

    // Norte.
    b.write('<g transform="translate(30 34)"><path d="M0 -16 L7 6 L0 1 L-7 6Z" fill="#3D5C40"/>'
        '<text y="22" text-anchor="middle" font-size="12" font-weight="700" fill="#3D5C40">N</text></g>');
    b.write('</svg>');
    return b.toString();
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final exp = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    final m = raw / base;
    final nice = m < 1.5 ? 1 : m < 3.5 ? 2 : m < 7.5 ? 5 : 10;
    return nice * base;
  }

  static String _deg(double v, String pos, String neg, double step) {
    final decimals = step >= 1 ? 0 : step >= 0.1 ? 1 : step >= 0.01 ? 2 : 3;
    final hemi = v.abs() < 1e-9 ? '' : (v > 0 ? pos : neg);
    return '${v.abs().toStringAsFixed(decimals).replaceAll('.', ',')}°$hemi';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
}
