import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/sample_filter.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../labels/label_screen.dart';
import 'sample_detail_screen.dart';
import 'sample_form_screen.dart';

class SampleListScreen extends ConsumerStatefulWidget {
  const SampleListScreen({super.key});

  @override
  ConsumerState<SampleListScreen> createState() => _SampleListScreenState();
}

class _SampleListScreenState extends ConsumerState<SampleListScreen> {
  final _search = TextEditingController();

  /// Ids marcados no modo de seleção (ativado com toque longo).
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(Sample s) => setState(() {
    if (!_selected.remove(s.id)) _selected.add(s.id);
  });

  List<Sample> _selectedSamples() =>
      (ref.read(samplesProvider).value ?? const <Sample>[]).where((s) => _selected.contains(s.id)).toList();

  Future<void> _deleteSelected() async {
    final list = _selectedSamples();
    if (list.isEmpty) return;
    final photos = list.fold<int>(0, (n, s) => n + s.photos.length);
    final ok = await confirm(
      context,
      title: 'Excluir ${list.length} amostra(s)?',
      message:
          '${list.length} amostra(s) e $photos foto(s) serão apagadas deste aparelho. '
          'Amostras técnicas derivadas delas que não estiverem selecionadas serão mantidas. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(sampleRepoProvider).deleteMany(list.map((s) => s.id));
      for (final s in list) {
        for (final p in s.photos) {
          await ref.read(photoServiceProvider).deleteFile(p);
        }
      }
      if (!mounted) return;
      setState(_selected.clear);
      showMessage(context, '${list.length} amostra(s) excluída(s).');
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  AppBar _selectionBar(List<Sample> visible) {
    final allSelected = visible.isNotEmpty && visible.every((s) => _selected.contains(s.id));
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancelar seleção',
        icon: const Icon(Icons.close),
        onPressed: () => setState(_selected.clear),
      ),
      title: Text('${_selected.length} selecionada(s)', key: const Key('selection-count')),
      actions: [
        IconButton(
          tooltip: allSelected ? 'Desmarcar todas' : 'Selecionar todas da lista',
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.removeAll(visible.map((s) => s.id));
            } else {
              _selected.addAll(visible.map((s) => s.id));
            }
          }),
        ),
        IconButton(
          tooltip: 'Etiquetas das selecionadas',
          icon: const Icon(Icons.print_outlined),
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(samples: _selectedSamples()))),
        ),
        IconButton(
          key: const Key('delete-selected'),
          tooltip: 'Excluir selecionadas',
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(sampleFilterProvider).query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(sampleFilterProvider);
    final filtered = ref.watch(filteredSamplesProvider);
    final total = ref.watch(samplesProvider).value?.length ?? 0;
    final templates = ref.watch(templatesByIdProvider);
    // Remove da seleção amostras que sumiram (excluídas em outra tela).
    final ids = (ref.watch(samplesProvider).value ?? const <Sample>[]).map((s) => s.id).toSet();
    _selected.retainWhere(ids.contains);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting
            ? _selectionBar(filtered.value ?? const [])
            : AppBar(
                title: Text(l.navSamples),
                actions: [
                  PopupMenuButton<SampleSort>(
                    tooltip: 'Ordenar',
                    icon: const Icon(Icons.sort),
                    initialValue: filter.sort,
                    onSelected: (s) => ref.read(sampleFilterProvider.notifier).update(filter.copyWith(sort: s)),
                    itemBuilder: (_) => [
                      for (final s in SampleSort.values) PopupMenuItem(value: s, child: Text(s.label)),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Etiquetas das amostras listadas',
                    icon: const Icon(Icons.print_outlined),
                    onPressed: () {
                      final list = filtered.value ?? const <Sample>[];
                      if (list.isEmpty) return showMessage(context, 'Nenhuma amostra na lista.');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(samples: list)));
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(72),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('sample-search'),
                            controller: _search,
                            onChanged: (v) {
                              setState(() {}); // atualiza o botão de limpar
                              ref.read(sampleFilterProvider.notifier).setQuery(v);
                            },
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Buscar código, clone, coletor…',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _search.clear();
                                        ref.read(sampleFilterProvider.notifier).setQuery('');
                                      },
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible: filter.activeCount > 0,
                          label: Text('${filter.activeCount}'),
                          child: IconButton.filledTonal(
                            tooltip: 'Filtros',
                            iconSize: 28,
                            icon: const Icon(Icons.filter_list),
                            onPressed: () => _openFilters(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton.extended(
                key: const Key('new-sample'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleFormScreen())),
                icon: const Icon(Icons.add),
                label: Text(l.newSample),
              ),
        body: filtered.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
          data: (list) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          filter.isActive ? '${list.length} de $total amostras' : l.sampleCount(list.length),
                          key: const Key('sample-counter'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (filter.isActive)
                        TextButton.icon(
                          onPressed: () {
                            _search.clear();
                            ref.read(sampleFilterProvider.notifier).clear();
                          },
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Limpar'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? _Empty(hasFilter: filter.isActive)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _SampleCard(
                            sample: list[i],
                            template: templates[list[i].templateId],
                            selecting: _selecting,
                            selected: _selected.contains(list[i].id),
                            onToggle: () => _toggle(list[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({
    required this.sample,
    required this.template,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });
  final Sample sample;
  final SampleTemplate? template;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.secondaryContainer : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onLongPress: onToggle,
        onTap: selecting
            ? onToggle
            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => SampleDetailScreen(sampleId: sample.id))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (selecting) ...[
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                  size: 28,
                ),
                const SizedBox(width: 10),
              ],
              SizedBox(
                width: 72,
                height: 72,
                child: sample.photos.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: Color(template?.color ?? 0xFF3D5C40).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.eco_outlined, size: 32, color: Color(template?.color ?? 0xFF3D5C40)),
                      )
                    : PhotoThumb(sample.photos.first, size: 72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TemplateDot(template),
                        const SizedBox(width: 6),
                        if (sample.isChild) ...[
                          Tooltip(
                            message: 'Amostra técnica derivada',
                            child: Icon(Icons.subdirectory_arrow_right, size: 18, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 2),
                        ],
                        Flexible(
                          child: Text(
                            sample.sampleCode,
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(fmtDateTime(sample.collectedAt), style: text.bodyMedium),
                    Text(
                      [
                        sample.place,
                        if (sample.cloneGenotype.isNotEmpty) sample.cloneGenotype,
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!sample.hasLocation)
                const Tooltip(message: 'Sem coordenadas', child: Icon(Icons.location_off_outlined)),
              if (!selecting) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasFilter ? Icons.search_off : Icons.inventory_2_outlined, size: 56),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Nenhuma amostra corresponde aos filtros.'
                : 'Nenhuma amostra ainda.\nToque em "Nova amostra" para começar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(sampleFilterProvider);
    final notifier = ref.read(sampleFilterProvider.notifier);
    final samples = ref.watch(samplesProvider).value ?? const <Sample>[];
    final templates = ref.watch(templatesProvider).value ?? const <SampleTemplate>[];
    final collectors = samples.map((s) => s.collectorName).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final cities = samples.map((s) => s.municipality).where((e) => e.isNotEmpty).toSet().toList()..sort();

    Widget dropdown(String label, String? value, List<(String, String)> items, void Function(String?) onChanged) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              for (final (v, t) in items) DropdownMenuItem(value: v, child: Text(t)),
            ],
            onChanged: onChanged,
          ),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              dropdown('Modelo', filter.templateId, [
                for (final t in templates) (t.id, t.name),
              ], (v) => notifier.update(filter.copyWith(templateId: () => v))),
              dropdown('Coletor', filter.collector, [
                for (final c in collectors) (c, c),
              ], (v) => notifier.update(filter.copyWith(collector: () => v))),
              dropdown('Município', filter.municipality, [
                for (final c in cities) (c, c),
              ], (v) => notifier.update(filter.copyWith(municipality: () => v))),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  filter.from == null && filter.to == null
                      ? 'Período: todos'
                      : 'Período: ${filter.from == null ? '…' : fmtDate(filter.from!)} a ${filter.to == null ? '…' : fmtDate(filter.to!)}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: filter.from != null && filter.to != null
                        ? DateTimeRange(start: filter.from!, end: filter.to!)
                        : null,
                  );
                  if (range != null) {
                    notifier.update(filter.copyWith(from: () => range.start, to: () => range.end));
                  }
                },
              ),
              if (filter.from != null || filter.to != null)
                TextButton(
                  onPressed: () => notifier.update(filter.copyWith(from: () => null, to: () => null)),
                  child: const Text('Remover período'),
                ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Aplicar')),
            ],
          ),
        ),
      ),
    );
  }
}
