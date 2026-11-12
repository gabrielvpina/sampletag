import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../samples/sample_detail_screen.dart';
import 'map_widgets.dart';

/// Todas as amostras (respeitando os filtros da lista) no mapa.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();

  @override
  Widget build(BuildContext context) {
    final samples = (ref.watch(filteredSamplesProvider).value ?? const <Sample>[])
        .where((s) => s.hasLocation)
        .toList();
    final templates = ref.watch(templatesByIdProvider);
    final filtered = ref.watch(sampleFilterProvider).isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa (${samples.length})'),
        actions: [
          IconButton(
            tooltip: 'Enquadrar todas',
            icon: const Icon(Icons.fit_screen),
            onPressed: samples.isEmpty ? null : () => _fit(samples),
          ),
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCameraFit: samples.isEmpty ? null : _fitFor(samples),
            initialCenter: const LatLng(-14.8, -39.2),
            initialZoom: samples.isEmpty ? 5 : 10,
            backgroundColor: neutralMapBackground,
            maxZoom: 19,
          ),
          children: [
            ...baseMapLayers(ref.watch(mapGeoProvider).value),
            MarkerLayer(markers: [
              for (final s in samples)
                sampleMarker(s, templates[s.templateId], onTap: () => _showSample(s, templates[s.templateId])),
            ]),
            const SimpleAttributionWidget(source: Text('OpenStreetMap · limites: IBGE')),
          ],
        ),
        if (filtered)
          Positioned(
            left: 12,
            top: 12,
            child: Chip(avatar: const Icon(Icons.filter_list), label: const Text('Filtros da lista aplicados')),
          ),
        if (samples.isEmpty)
          const Center(
            child: Card(
              child: Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma amostra com coordenadas.')),
            ),
          ),
      ]),
    );
  }

  CameraFit _fitFor(List<Sample> samples) {
    if (samples.length == 1) {
      return CameraFit.coordinates(coordinates: [LatLng(samples.first.latitude!, samples.first.longitude!)], maxZoom: 14);
    }
    return CameraFit.coordinates(
      coordinates: [for (final s in samples) LatLng(s.latitude!, s.longitude!)],
      padding: const EdgeInsets.all(48),
      maxZoom: 16,
    );
  }

  void _fit(List<Sample> samples) => _controller.fitCamera(_fitFor(samples));

  void _showSample(Sample s, SampleTemplate? t) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (s.photos.isNotEmpty) ...[PhotoThumb(s.photos.first, size: 72), const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [TemplateDot(t), const SizedBox(width: 6), Text(s.sampleCode, style: Theme.of(c).textTheme.titleLarge)]),
                  Text(fmtDateTime(s.collectedAt)),
                  if (s.collectorName.isNotEmpty) Text('Coletor: ${s.collectorName}'),
                  if (s.cloneGenotype.isNotEmpty) Text('Clone: ${s.cloneGenotype}'),
                  if (s.place.isNotEmpty) Text(s.place),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SampleDetailScreen(sampleId: s.id)));
              },
              child: const Text('Abrir amostra'),
            ),
          ]),
        ),
      ),
    );
  }
}
