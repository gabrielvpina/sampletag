// Limites territoriais do Brasil (IBGE): leitura, busca de ponto e
// simplificação. Dart puro — usado pelo app, pelo relatório e pelos testes.
//
// Os arquivos ficam em assets/geo/: `br_uf.json` (27 UFs) e
// `municipios/{UF}.json`. Ver assets/geo/FONTE.md.

import 'dart:convert';
import 'dart:math' as math;

/// Siglas e nomes das 27 UFs, em ordem alfabética de sigla.
const brazilStates = <String, String>{
  'AC': 'Acre', 'AL': 'Alagoas', 'AM': 'Amazonas', 'AP': 'Amapá', 'BA': 'Bahia',
  'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo', 'GO': 'Goiás',
  'MA': 'Maranhão', 'MG': 'Minas Gerais', 'MS': 'Mato Grosso do Sul', 'MT': 'Mato Grosso',
  'PA': 'Pará', 'PB': 'Paraíba', 'PE': 'Pernambuco', 'PI': 'Piauí', 'PR': 'Paraná',
  'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte', 'RO': 'Rondônia', 'RR': 'Roraima',
  'RS': 'Rio Grande do Sul', 'SC': 'Santa Catarina', 'SE': 'Sergipe', 'SP': 'São Paulo',
  'TO': 'Tocantins',
};

/// Ponto em graus: x = longitude, y = latitude (ordem do GeoJSON).
typedef GeoPoint = ({double lon, double lat});

/// Anel de polígono (fechado ou não).
typedef Ring = List<GeoPoint>;

/// Polígono = anel externo + buracos.
typedef GeoPolygon = List<Ring>;

class GeoBounds {
  const GeoBounds(this.minLon, this.minLat, this.maxLon, this.maxLat);
  final double minLon, minLat, maxLon, maxLat;

  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;

  bool intersects(GeoBounds o) =>
      !(o.minLon > maxLon || o.maxLon < minLon || o.minLat > maxLat || o.maxLat < minLat);
}

/// Uma área (UF ou município).
class GeoFeature {
  GeoFeature({required this.id, required this.name, required this.polygons})
      : bounds = _boundsOf(polygons);

  /// Sigla da UF ou código IBGE do município.
  final String id;
  final String name;
  final List<GeoPolygon> polygons;
  final GeoBounds bounds;

  static GeoBounds _boundsOf(List<GeoPolygon> polys) {
    var minLon = double.infinity, minLat = double.infinity;
    var maxLon = -double.infinity, maxLat = -double.infinity;
    for (final poly in polys) {
      for (final p in poly.isEmpty ? const <GeoPoint>[] : poly.first) {
        minLon = math.min(minLon, p.lon);
        maxLon = math.max(maxLon, p.lon);
        minLat = math.min(minLat, p.lat);
        maxLat = math.max(maxLat, p.lat);
      }
    }
    return GeoBounds(minLon, minLat, maxLon, maxLat);
  }

  /// Ponto dentro da área (regra par-ímpar, considerando buracos).
  bool contains(double lat, double lon) {
    if (!bounds.contains(lat, lon)) return false;
    for (final poly in polygons) {
      if (poly.isEmpty || !_inRing(poly.first, lat, lon)) continue;
      var inHole = false;
      for (final hole in poly.skip(1)) {
        if (_inRing(hole, lat, lon)) {
          inHole = true;
          break;
        }
      }
      if (!inHole) return true;
    }
    return false;
  }

  static bool _inRing(Ring ring, double lat, double lon) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i], b = ring[j];
      if ((a.lat > lat) != (b.lat > lat) &&
          lon < (b.lon - a.lon) * (lat - a.lat) / (b.lat - a.lat) + a.lon) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Cópia simplificada (Douglas-Peucker) com tolerância em graus.
  /// Anéis que ficariam degenerados são descartados (buracos) ou mantidos
  /// como triângulo (anel externo).
  GeoFeature simplified(double tolerance) {
    final out = <GeoPolygon>[];
    for (final poly in polygons) {
      final rings = <Ring>[];
      for (var i = 0; i < poly.length; i++) {
        final r = simplifyRing(poly[i], tolerance);
        if (r.length >= 4) {
          rings.add(r);
        } else if (i == 0) {
          // Área menor que a tolerância: some no relatório.
          break;
        }
      }
      if (rings.isNotEmpty) out.add(rings);
    }
    return GeoFeature(id: id, name: name, polygons: out);
  }

  /// Geometria GeoJSON (MultiPolygon) com 4 casas decimais.
  Map<String, Object?> toGeoJson(Map<String, Object?> properties) => {
        'type': 'Feature',
        'properties': properties,
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': [
            for (final poly in polygons)
              [
                for (final ring in poly)
                  [for (final p in ring) [_r(p.lon), _r(p.lat)]],
              ],
          ],
        },
      };

  static double _r(double v) => (v * 10000).roundToDouble() / 10000;
}

/// Simplifica um anel com Douglas-Peucker, preservando o fechamento.
Ring simplifyRing(Ring ring, double tolerance) {
  if (ring.length <= 4 || tolerance <= 0) return ring;
  final keep = List<bool>.filled(ring.length, false);
  keep[0] = keep[ring.length - 1] = true;
  final stack = <(int, int)>[(0, ring.length - 1)];
  final tol2 = tolerance * tolerance;
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    var maxD = 0.0;
    var idx = -1;
    for (var i = a + 1; i < b; i++) {
      final d = _segDist2(ring[i], ring[a], ring[b]);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx >= 0 && maxD > tol2) {
      keep[idx] = true;
      stack
        ..add((a, idx))
        ..add((idx, b));
    }
  }
  return [for (var i = 0; i < ring.length; i++) if (keep[i]) ring[i]];
}

double _segDist2(GeoPoint p, GeoPoint a, GeoPoint b) {
  var dx = b.lon - a.lon, dy = b.lat - a.lat;
  if (dx == 0 && dy == 0) {
    dx = p.lon - a.lon;
    dy = p.lat - a.lat;
    return dx * dx + dy * dy;
  }
  final t = (((p.lon - a.lon) * dx + (p.lat - a.lat) * dy) / (dx * dx + dy * dy)).clamp(0.0, 1.0);
  final x = a.lon + t * dx - p.lon, y = a.lat + t * dy - p.lat;
  return x * x + y * y;
}

/// Lê um FeatureCollection do IBGE já processado.
/// [idKey]/[nameKey]: `uf`/`n` para estados, `c`/`n` para municípios.
List<GeoFeature> parseFeatures(String json, {required String idKey, String nameKey = 'n'}) {
  final data = jsonDecode(json) as Map<String, Object?>;
  final out = <GeoFeature>[];
  for (final f in (data['features'] as List).cast<Map<String, Object?>>()) {
    final props = (f['properties'] as Map).cast<String, Object?>();
    final geom = (f['geometry'] as Map).cast<String, Object?>();
    final coords = geom['coordinates'] as List;
    final polys = switch (geom['type']) {
      'Polygon' => [_polygon(coords)],
      'MultiPolygon' => [for (final p in coords) _polygon(p as List)],
      _ => const <GeoPolygon>[],
    };
    out.add(GeoFeature(id: '${props[idKey]}', name: '${props[nameKey] ?? props[idKey]}', polygons: polys));
  }
  return out;
}

GeoPolygon _polygon(List rings) => [
      for (final r in rings)
        [
          for (final p in (r as List))
            (lon: ((p as List)[0] as num).toDouble(), lat: (p[1] as num).toDouble()),
        ],
    ];

/// Resultado da busca de local offline.
class GeoPlace {
  const GeoPlace({required this.uf, required this.municipality, required this.municipalityCode});
  final String uf;
  final String municipality;
  final String municipalityCode;
}

/// Fornece os textos dos arquivos (rootBundle no app, File na ferramenta).
typedef GeoLoader = Future<String> Function(String assetPath);

/// Biblioteca de limites com cache em memória.
class GeoLibrary {
  GeoLibrary(this._load);

  final GeoLoader _load;
  List<GeoFeature>? _states;
  final Map<String, List<GeoFeature>> _municipalities = {};

  static const statesAsset = 'assets/geo/br_uf.json';
  static String municipalitiesAsset(String uf) => 'assets/geo/municipios/$uf.json';

  Future<List<GeoFeature>> states() async =>
      _states ??= parseFeatures(await _load(statesAsset), idKey: 'uf');

  Future<List<GeoFeature>> municipalities(String uf) async {
    final key = uf.toUpperCase();
    if (!brazilStates.containsKey(key)) return const [];
    return _municipalities[key] ??= parseFeatures(await _load(municipalitiesAsset(key)), idKey: 'c');
  }

  /// UF e município que contêm a coordenada, sem internet.
  /// Retorna `null` fora do Brasil (ex.: no mar).
  Future<GeoPlace?> locate(double lat, double lon) async {
    final st = (await states()).where((s) => s.contains(lat, lon)).firstOrNull;
    if (st == null) return null;
    final mun = (await municipalities(st.id)).where((m) => m.contains(lat, lon)).firstOrNull;
    return GeoPlace(uf: st.id, municipality: mun?.name ?? '', municipalityCode: mun?.id ?? '');
  }
}

/// Camadas de limites prontas para o relatório.
class ReportGeo {
  const ReportGeo({required this.states, required this.highlighted, this.municipalities = const []});

  /// Todas as UFs (contexto), simplificadas.
  final List<GeoFeature> states;

  /// UFs em destaque (das amostras + escolhidas pelo usuário).
  final Set<String> highlighted;

  /// Municípios das UFs em destaque (vazio se desativado).
  final List<GeoFeature> municipalities;

  /// Tolerâncias de simplificação (graus): ~1 km nos estados, ~200 m nos
  /// municípios — suficiente para leitura e mantém o HTML pequeno.
  static const stateTolerance = 0.01;
  static const municipalityTolerance = 0.003;

  static Future<ReportGeo> build(
    GeoLibrary lib, {
    required Set<String> highlighted,
    required bool includeMunicipalities,
  }) async {
    final states = [for (final s in await lib.states()) s.simplified(stateTolerance)];
    final muns = <GeoFeature>[];
    if (includeMunicipalities) {
      for (final uf in highlighted) {
        for (final m in await lib.municipalities(uf)) {
          final s = m.simplified(municipalityTolerance);
          if (s.polygons.isNotEmpty) muns.add(s);
        }
      }
    }
    return ReportGeo(states: states, highlighted: highlighted, municipalities: muns);
  }

  /// Formato compacto embutido no HTML: cada anel vira uma string no
  /// formato "polyline" (deltas inteiros a 1e-4 grau, ~4–5 bytes por ponto,
  /// contra ~20 em GeoJSON). O relatório decodifica em JavaScript.
  Map<String, Object?> toJson() => {
        'precision': polylinePrecision,
        'states': [
          for (final st in states)
            {'uf': st.id, 'n': st.name, 'h': highlighted.contains(st.id), 'p': _encode(st)},
        ],
        'municipalities': [
          for (final m in municipalities) {'c': m.id, 'n': m.name, 'p': _encode(m)},
        ],
      };

  static List<List<String>> _encode(GeoFeature f) => [
        for (final poly in f.polygons) [for (final ring in poly) encodeRing(ring)],
      ];
}

/// Casas decimais usadas na codificação "polyline".
const polylinePrecision = 4;
const _scale = 10000;

/// Codifica um anel no formato polyline (lat, lon), como o do Google, com
/// precisão de [polylinePrecision] casas decimais.
String encodeRing(Ring ring) {
  final b = StringBuffer();
  void enc(int v) {
    var x = v < 0 ? ~(v << 1) : v << 1;
    while (x >= 0x20) {
      b.writeCharCode((0x20 | (x & 0x1f)) + 63);
      x >>= 5;
    }
    b.writeCharCode(x + 63);
  }

  var pLat = 0, pLon = 0;
  for (final p in ring) {
    final lat = (p.lat * _scale).round(), lon = (p.lon * _scale).round();
    enc(lat - pLat);
    enc(lon - pLon);
    pLat = lat;
    pLon = lon;
  }
  return b.toString();
}

/// Inverso de [encodeRing] (usado nos testes; o relatório tem a versão JS).
Ring decodeRing(String s) {
  final out = <GeoPoint>[];
  var i = 0, lat = 0, lon = 0;
  int next() {
    var r = 0, shift = 0, c = 0;
    do {
      c = s.codeUnitAt(i++) - 63;
      r |= (c & 0x1f) << shift;
      shift += 5;
    } while (c >= 0x20);
    return (r & 1) != 0 ? ~(r >> 1) : r >> 1;
  }

  while (i < s.length) {
    lat += next();
    lon += next();
    out.add((lon: lon / _scale, lat: lat / _scale));
  }
  return out;
}

/// UFs em destaque: as das amostras somadas às escolhidas nas configurações.
Set<String> effectiveStates(Iterable<String> sampleUfs, Iterable<String> chosen) => {
      for (final u in [...sampleUfs, ...chosen])
        if (brazilStates.containsKey(u.trim().toUpperCase())) u.trim().toUpperCase(),
    };
