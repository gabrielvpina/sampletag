import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../../services/export/qr_payload.dart';
import '../labels/label_screen.dart';
import '../map/map_widgets.dart';
import 'sample_form_screen.dart';

class SampleDetailScreen extends ConsumerWidget {
  const SampleDetailScreen({super.key, required this.sampleId});
  final String sampleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sampleByIdProvider(sampleId));
    final templates = ref.watch(templatesByIdProvider);
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $e'))),
      data: (s) {
        if (s == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Amostra não encontrada.')));
        }
        final t = templates[s.templateId];
        return Scaffold(
          appBar: AppBar(
            title: Text(s.sampleCode),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SampleFormScreen(existing: s))),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') await _delete(context, ref, s);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Excluir amostra')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(samples: [s]))),
            icon: const Icon(Icons.print),
            label: const Text('Etiqueta'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _Header(sample: s, template: t),
              if (s.photos.isNotEmpty) ...[
                const SectionTitle('Fotos'),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: s.photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _PhotoViewer(photos: s.photos, initial: i)),
                      ),
                      child: PhotoThumb(s.photos[i], size: 140),
                    ),
                  ),
                ),
              ],
              const SectionTitle('Dados da coleta'),
              _Fields(rows: [
                ('Data/hora', fmtDateTime(s.collectedAt)),
                ('Categoria', s.category.label),
                ('Coletor', s.collectorName),
                ('Contato', s.collectorContact),
                ('Clone/genótipo', s.cloneGenotype),
                ('Origem/propriedade', s.originProperty),
                ('Município/UF', s.place),
                for (final f in t?.fields ?? const <TemplateField>[])
                  (f.label, fmtCustomValue(s.customFields[f.key])),
                ('Observações', s.notes),
                ('Armazenamento', s.storageInstruction),
              ]),
              const SectionTitle('Localização'),
              if (s.hasLocation) ...[
                _Fields(rows: [
                  ('Latitude, longitude', fmtLatLon(s.latitude, s.longitude)),
                  ('Altitude', fmtMeters(s.altitude)),
                  ('Precisão do GPS', s.gpsAccuracyMeters == null ? '' : '±${fmtMeters(s.gpsAccuracyMeters)}'),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(s.latitude!, s.longitude!),
                        initialZoom: 14,
                        backgroundColor: neutralMapBackground,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        osmTileLayer(),
                        MarkerLayer(markers: [sampleMarker(s, t)]),
                      ],
                    ),
                  ),
                ),
              ] else
                const Text('Sem coordenadas registradas.'),
              const SectionTitle('QR code'),
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: qrPayload(s, t),
                    size: 200,
                    backgroundColor: Colors.white,
                    semanticsLabel: 'QR code da amostra ${s.sampleCode}',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: Text(s.sampleCode, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Sample s) async {
    final ok = await confirm(
      context,
      title: 'Excluir ${s.sampleCode}?',
      message: 'A amostra e suas ${s.photos.length} foto(s) serão apagadas deste aparelho. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(sampleRepoProvider).delete(s.id);
    for (final p in s.photos) {
      await ref.read(photoServiceProvider).deleteFile(p);
    }
    if (context.mounted) {
      showMessage(context, 'Amostra excluída.');
      Navigator.pop(context);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sample, required this.template});
  final Sample sample;
  final SampleTemplate? template;

  @override
  Widget build(BuildContext context) {
    final color = Color(template?.color ?? 0xFF3D5C40);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'FICHA DE AMOSTRA - ${(template?.name ?? '').toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(sample.sampleCode,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(children: [
          for (final r in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 130, child: Text(r.$1, style: TextStyle(color: muted))),
                Expanded(child: SelectableText(r.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
          if (visible.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('—')),
        ]),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.photos, required this.initial});
  final List<String> photos;
  final int initial;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PageView.builder(
          controller: PageController(initialPage: initial),
          itemCount: photos.length,
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(child: PhotoThumb(photos[i], size: null, fit: BoxFit.contain, radius: 0)),
          ),
        ),
      );
}
