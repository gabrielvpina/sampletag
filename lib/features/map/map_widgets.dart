import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';

/// Fundo neutro: sem internet (e sem cache) os tiles não aparecem e os
/// pontos ficam sobre esta cor.
const neutralMapBackground = Color(0xFFE4E7DD);

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
