import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../providers.dart';

/// Exportações: relatório HTML, CSV, KML, backup ZIP e restauração.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _onlyFiltered = false;
  bool _withPhotos = true;
  String? _busy;

  List<Sample> _selection() => _onlyFiltered
      ? ref.read(filteredSamplesProvider).value ?? const []
      : ref.read(samplesProvider).value ?? const [];

  Future<void> _run(String label, Future<File> Function(List<Sample>) make, String mime) async {
    final list = _selection();
    if (list.isEmpty && label != 'backup') {
      showMessage(context, 'Nenhuma amostra para exportar.', error: true);
      return;
    }
    setState(() => _busy = label);
    try {
      final file = await make(list);
      await ref.read(exportServiceProvider).share(file, mime: mime);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _restore() async {
    final ok = await confirm(
      context,
      title: 'Restaurar backup',
      message: 'As amostras e modelos do backup serão mesclados aos atuais. '
          'Registros com o mesmo identificador serão substituídos pela versão do backup.',
      confirmLabel: 'Escolher arquivo',
    );
    if (!ok) return;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
    if (files.isEmpty) return;
    setState(() => _busy = 'restore');
    try {
      final r = await ref.read(exportServiceProvider).restore(await files.first.readAsBytes());
      if (mounted) {
        showMessage(context, 'Restaurado: ${r.samples} amostra(s), ${r.templates} modelo(s), ${r.photos} foto(s).');
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(samplesProvider).value?.length ?? 0;
    final filtered = ref.watch(filteredSamplesProvider).value?.length ?? 0;
    final filterActive = ref.watch(sampleFilterProvider).isActive;
    final svc = ref.read(exportServiceProvider);

    Widget action({
      required String id,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool primary = false,
    }) {
      final busy = _busy == id;
      return Card(
        color: primary ? Theme.of(context).colorScheme.primaryContainer : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: busy ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator()) : Icon(icon, size: 32),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          subtitle: Text(subtitle),
          enabled: _busy == null,
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Exportar')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              RadioGroup<bool>(
                groupValue: _onlyFiltered,
                onChanged: (v) => setState(() => _onlyFiltered = v ?? false),
                child: Column(children: [
                  RadioListTile<bool>(value: false, title: Text('Todas as amostras ($total)')),
                  RadioListTile<bool>(
                    value: true,
                    enabled: filterActive,
                    title: Text('Somente as filtradas na lista ($filtered)'),
                    subtitle: filterActive ? null : const Text('Nenhum filtro ativo na lista'),
                  ),
                ]),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Incluir fotos no relatório'),
                subtitle: const Text('Miniaturas de ~400 px embutidas no HTML'),
                value: _withPhotos,
                onChanged: (v) => setState(() => _withPhotos = v),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        action(
          id: 'html',
          primary: true,
          icon: Icons.description_outlined,
          title: 'Relatório HTML',
          subtitle: 'Arquivo único com mapa, tabela, fichas e QR codes. Abre em qualquer navegador, mesmo offline.',
          onTap: () => _run('html', (l) => svc.htmlReport(l, withPhotos: _withPhotos), 'text/html'),
        ),
        const SizedBox(height: 8),
        action(
          id: 'csv',
          icon: Icons.table_chart_outlined,
          title: 'Planilha CSV',
          subtitle: 'Separador ";" (Excel pt-BR), UTF-8.',
          onTap: () => _run('csv', svc.csv, 'text/csv'),
        ),
        const SizedBox(height: 8),
        action(
          id: 'kml',
          icon: Icons.public,
          title: 'KML',
          subtitle: 'Para Google Earth e QGIS (amostras com coordenadas).',
          onTap: () => _run('kml', svc.kml, 'application/vnd.google-earth.kml+xml'),
        ),
        const SizedBox(height: 24),
        Text('Backup', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        action(
          id: 'backup',
          icon: Icons.archive_outlined,
          title: 'Criar backup (ZIP)',
          subtitle: 'Banco de dados completo + todas as fotos. Sempre inclui todas as amostras.',
          onTap: () => _run('backup', (_) => svc.backup(), 'application/zip'),
        ),
        const SizedBox(height: 8),
        action(
          id: 'restore',
          icon: Icons.unarchive_outlined,
          title: 'Restaurar backup',
          subtitle: 'Importa um ZIP gerado pelo SampleTag.',
          onTap: _restore,
        ),
        const SizedBox(height: 16),
        Text(
          'Nenhum dado sai do aparelho sem sua ação: os arquivos são gerados localmente '
          'e você escolhe para onde enviá-los.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}
