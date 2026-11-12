import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../domain/import_plan.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../../services/export/export_service.dart';

/// Prévia da importação de coleta de outro celular: mostra o que será
/// adicionado/atualizado e deixa decidir os conflitos de código.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.preview});
  final ImportPreview preview;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ConflictAction _all = ConflictAction.rename;
  final Map<String, ConflictAction> _perItem = {};
  bool _updateExisting = true;
  bool _busy = false;

  ImportPlan get _plan => widget.preview.plan;

  ConflictAction _actionFor(ImportItem i) => _perItem[i.incoming.id] ?? _all;

  int get _willImport {
    var n = _plan.count(ImportKind.added) + (_updateExisting ? _plan.count(ImportKind.updated) : 0);
    for (final c in _plan.conflicts) {
      if (_actionFor(c) != ConflictAction.skip) n++;
    }
    return n;
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(exportServiceProvider).applyImport(
            widget.preview,
            conflictAction: _actionFor,
            updateExisting: _updateExisting,
          );
      if (!mounted) return;
      Navigator.pop(context, r);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = _plan.source;
    final text = Theme.of(context).textTheme;
    final conflicts = _plan.conflicts;

    Widget stat(String label, int n, IconData icon, {Color? color}) => n == 0
        ? const SizedBox.shrink()
        : ListTile(
            dense: true,
            leading: Icon(icon, color: color),
            title: Text(label),
            trailing: Text('$n', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Importar coleta')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const Key('confirm-import'),
            onPressed: _busy || _willImport == 0 ? null : _import,
            icon: _busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_done),
            label: Text(_willImport == 0 ? 'Nada novo para importar' : 'Importar $_willImport amostra(s)'),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone_android, size: 32),
            title: Text(src.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text([
              if (src.project.isNotEmpty) 'Projeto: ${src.project}',
              if (src.createdAt != null) 'Gerado em ${fmtDateTime(src.createdAt!)}',
              '${widget.preview.package.samples.length} amostra(s) no arquivo',
            ].join('\n')),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            stat('Novas', _plan.count(ImportKind.added), Icons.add_circle_outline, color: Colors.green.shade700),
            stat('Atualizadas (versão recebida mais recente)', _plan.count(ImportKind.updated), Icons.update),
            stat('Já iguais neste aparelho', _plan.count(ImportKind.unchanged), Icons.check_circle_outline),
            stat('Versão deste aparelho é mais recente', _plan.count(ImportKind.olderThanLocal), Icons.history),
            stat('Código repetido', conflicts.length, Icons.warning_amber, color: Colors.orange.shade800),
            stat('Sem modelo de ficha (serão ignoradas)', _plan.count(ImportKind.missingTemplate), Icons.block),
            stat('Modelos de ficha novos', _plan.newTemplates.length, Icons.dashboard_customize_outlined),
          ]),
        ),
        if (_plan.count(ImportKind.updated) > 0)
          SwitchListTile(
            title: const Text('Atualizar amostras já importadas antes'),
            subtitle: const Text('Usa a versão recebida quando ela for mais recente.'),
            value: _updateExisting,
            onChanged: (v) => setState(() => _updateExisting = v),
          ),
        if (conflicts.isNotEmpty) ...[
          const SectionTitle('Códigos repetidos'),
          Text(
            'Estas amostras têm o mesmo código de outras já existentes, mas são amostras diferentes. '
            'Renomear acrescenta uma letra ao código recebido (ex.: CAC-2026-0001-B).',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ConflictAction>(
            segments: [for (final a in ConflictAction.values) ButtonSegment(value: a, label: Text('${a.label} todas'))],
            selected: {_all},
            onSelectionChanged: (s) => setState(() {
              _all = s.first;
              _perItem.clear();
            }),
          ),
          const SizedBox(height: 8),
          for (final c in conflicts)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.incoming.sampleCode, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Recebida: ${_describe(c.incoming)}'),
                  if (c.existing != null) Text('Já existe: ${_describe(c.existing!)}'),
                  const SizedBox(height: 8),
                  DropdownButton<ConflictAction>(
                    value: _actionFor(c),
                    items: [for (final a in ConflictAction.values) DropdownMenuItem(value: a, child: Text(a.label))],
                    onChanged: (a) => setState(() => _perItem[c.incoming.id] = a!),
                  ),
                ]),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'As configurações deste aparelho (coletor, projeto, formato do código) não são alteradas.',
          style: text.bodySmall,
        ),
      ]),
    );
  }

  String _describe(Sample s) => [
        fmtDateTime(s.collectedAt),
        if (s.collectorName.isNotEmpty) s.collectorName,
        if (s.place.isNotEmpty) s.place,
      ].join(' · ');
}
