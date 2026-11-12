import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/geo.dart';
import '../../domain/models.dart';
import '../../providers.dart';

/// Fundo neutro: sem internet (e sem cache) os tiles não aparecem e os
/// pontos ficam sobre esta cor.
const neutralMapBackground = Color(0xFFDCE5EA);

/// Camada OSM. O flutter_map 8 já faz cache local dos tiles
/// (BuiltInMapCachingProvider), então áreas vistas antes funcionam offline.
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.sampletag.sampletag',
      maxNativeZoom: 19,
      // Erros de rede são esperados no campo; não poluir o log.
      errorTileCallback: (_, _, _) {},
    );

Marker sampleMarker(Sample s, SampleTemplate? t, {VoidCallback? onTap}) => Marker(
      point: LatLng(s.latitude!, s.longitude!),
      width: 34,
      height: 34,
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          label: 'Amostra ${s.sampleCode}',
          button: onTap != null,
          child: Container(
            decoration: BoxDecoration(
              color: Color(t?.color ?? 0xFF3D5C40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
            ),
          ),
        ),
      ),
    );

/// Polígonos dos limites IBGE, prontos para o flutter_map.
class MapGeoLayers {
  const MapGeoLayers({this.fills = const [], this.lines = const []});

  /// Preenchimento das UFs (fica abaixo dos tiles: aparece só sem internet).
  final List<Polygon> fills;

  /// Contornos de municípios e UFs (ficam acima dos tiles).
  final List<Polygon> lines;
}

/// UFs em destaque = das amostras + escolhidas em Ajustes.
final mapGeoProvider = FutureProvider<MapGeoLayers>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final samples = await ref.watch(samplesProvider.future);
  final lib = ref.watch(geoLibraryProvider);
  final highlighted = effectiveStates(samples.map((s) => s.state), settings.mapStates);

  List<LatLng> pts(Ring r) => [for (final p in r) LatLng(p.lat, p.lon)];
  Iterable<Polygon> polys(GeoFeature f, {Color? fill, required Color border, required double width}) sync* {
    for (final poly in f.polygons) {
      if (poly.isEmpty) continue;
      yield Polygon(
        points: pts(poly.first),
        holePointsList: [for (final h in poly.skip(1)) pts(h)],
        color: fill,
        borderColor: border,
        borderStrokeWidth: width,
      );
    }
  }

  final states = await lib.states();
  final fills = [
    for (final st in states)
      ...polys(st,
          fill: highlighted.contains(st.id) ? const Color(0xFFFBFBF5) : const Color(0xFFECEEE6),
          border: Colors.transparent,
          width: 0),
  ];
  final lines = <Polygon>[
    if (settings.municipalBoundaries)
      for (final uf in highlighted)
        for (final m in await lib.municipalities(uf)) ...polys(m, border: const Color(0xFF9AA394), width: 0.8),
    for (final st in states) ...polys(st, border: const Color(0xFF6F7A6D), width: 1.8),
  ];
  return MapGeoLayers(fills: fills, lines: lines);
});

/// Camadas do mapa base na ordem certa: preenchimento, tiles, contornos.
List<Widget> baseMapLayers(MapGeoLayers? geo) => [
      if (geo != null) PolygonLayer(polygons: geo.fills, simplificationTolerance: 0.5),
      osmTileLayer(),
      if (geo != null) PolygonLayer(polygons: geo.lines, simplificationTolerance: 0.5),
    ];
