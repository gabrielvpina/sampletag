import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../domain/geo.dart';
import '../../domain/models.dart';
import '../../domain/sample_code.dart';
import '../../domain/seed_data.dart';
import '../../providers.dart';
import '../templates/template_list_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _project = TextEditingController();
  final _pattern = TextEditingController();
  final _collectorCode = TextEditingController();
  String _theme = 'system';
  Set<String> _mapStates = {};
  bool _municipal = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepoProvider).get().then((s) {
      if (!mounted) return;
      setState(() {
        _name.text = s.collectorName;
        _contact.text = s.collectorContact;
        _project.text = s.project;
        _pattern.text = s.idPattern;
        _collectorCode.text = s.collectorCode;
        _theme = s.themeMode;
        _mapStates = {...s.mapStates};
        _municipal = s.municipalBoundaries;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _contact, _project, _pattern, _collectorCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(settingsRepoProvider).save(AppSettings(
          collectorName: _name.text.trim(),
          collectorContact: _contact.text.trim(),
          project: _project.text.trim(),
          idPattern: _pattern.text.trim(),
          collectorCode: normalizeCollectorCode(_collectorCode.text),
          themeMode: _theme,
          mapStates: _mapStates,
          municipalBoundaries: _municipal,
        ));
    if (mounted) showMessage(context, 'Configurações salvas.');
  }

  Future<void> _loadDemo() async {
    final ok = await confirm(
      context,
      title: 'Carregar exemplos',
      message: 'Adiciona 5 amostras de exemplo (fazendas de cacau no sul da Bahia) para testar mapa e relatório.',
      confirmLabel: 'Adicionar',
    );
    if (!ok) return;
    final repo = ref.read(sampleRepoProvider);
    final existing = (await repo.getAll()).map((s) => s.sampleCode).toSet();
    final demo = demoSamples().where((s) => !existing.contains(s.sampleCode)).toList();
    await ref.read(templateRepoProvider).upsert(
          await ref.read(templateRepoProvider).getById(cacauTemplateId) ?? cacauTemplate,
        );
    await repo.upsertAll(demo);
    if (mounted) showMessage(context, '${demo.length} amostra(s) de exemplo adicionada(s).');
  }

  String get _collectorTag => _collectorCode.text.trim().isNotEmpty
      ? normalizeCollectorCode(_collectorCode.text)
      : collectorInitials(_name.text);

  /// País (só Brasil por enquanto), UFs extras e limites municipais.
  /// As UFs que aparecem nas amostras entram sempre, automaticamente.
  Widget _mapSection(BuildContext context) {
    final sampleUfs = effectiveStates(
      (ref.watch(samplesProvider).value ?? const <Sample>[]).map((s) => s.state),
      const [],
    );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InputDecorator(
        decoration: const InputDecoration(labelText: 'País'),
        child: Text(AppSettings.country),
      ),
      const SizedBox(height: 12),
      Text('Estados da coleta', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        sampleUfs.isEmpty
            ? 'Escolha os estados que aparecem destacados no mapa e no relatório.'
            : 'Já incluídos pelas amostras: ${(sampleUfs.toList()..sort()).join(', ')}. Escolha outros, se quiser.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final e in brazilStates.entries)
          Tooltip(
            message: e.value,
            child: FilterChip(
              label: Text(e.key),
              selected: _mapStates.contains(e.key) || sampleUfs.contains(e.key),
              onSelected: sampleUfs.contains(e.key)
                  ? null
                  : (v) => setState(() => v ? _mapStates.add(e.key) : _mapStates.remove(e.key)),
            ),
          ),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Limites municipais'),
        subtitle: const Text('Mostra os municípios dos estados em destaque (aumenta o relatório em ~100–300 KB por estado).'),
        value: _municipal,
        onChanged: (v) => setState(() => _municipal = v),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _pattern.text.isEmpty
        ? ''
        : formatSampleCode(
            pattern: _pattern.text,
            prefix: 'CAC',
            date: DateTime.now(),
            sequence: 1,
            collector: _collectorTag,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('Modelos de ficha', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Criar e editar modelos (ex.: Cacau)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateListScreen())),
                  ),
                ),
                const SectionTitle('Coletor padrão'),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contato')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _collectorCode,
                  maxLength: 4,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código do coletor ({COLETOR})',
                    helperText: _collectorCode.text.trim().isEmpty && _collectorTag.isNotEmpty
                        ? 'Vazio: usa as iniciais do nome ($_collectorTag)'
                        : 'Diferente em cada celular, para juntar dados sem conflito',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SectionTitle('Projeto / expedição atual'),
                TextFormField(controller: _project, decoration: const InputDecoration(labelText: 'Nome do projeto')),
                const SectionTitle('Formato do código'),
                TextFormField(
                  controller: _pattern,
                  decoration: InputDecoration(
                    labelText: 'Padrão',
                    helperText: 'Tokens: {PREFIXO} {COLETOR} {AAAA} {AA} {MM} {DD} {SEQ4}\nExemplo: $preview'
                        '${_pattern.text.contains('{COLETOR}') ? '' : '\nAtenção: sem {COLETOR}, dois celulares podem gerar o mesmo código.'}',
                    helperMaxLines: 3,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o padrão';
                    if (!RegExp(r'\{SEQ\d*\}').hasMatch(v)) return 'Inclua {SEQ} ou {SEQn} para numerar';
                    return null;
                  },
                ),
                const SectionTitle('Mapa base (limites IBGE)'),
                _mapSection(context),
                const SectionTitle('Aparência'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('Sistema')),
                    ButtonSegment(value: 'light', label: Text('Claro')),
                    ButtonSegment(value: 'dark', label: Text('Escuro')),
                  ],
                  selected: {_theme},
                  onSelectionChanged: (s) => setState(() => _theme = s.first),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Salvar configurações')),
                const SectionTitle('Demonstração'),
                OutlinedButton.icon(
                  onPressed: _loadDemo,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Carregar 5 amostras de exemplo'),
                ),
              ]),
            ),
    );
  }
}
