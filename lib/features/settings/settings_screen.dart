import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
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
  String _theme = 'system';
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
        _theme = s.themeMode;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _contact, _project, _pattern]) {
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
          themeMode: _theme,
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

  @override
  Widget build(BuildContext context) {
    final preview = _pattern.text.isEmpty
        ? ''
        : formatSampleCode(pattern: _pattern.text, prefix: 'CAC', date: DateTime.now(), sequence: 1);
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
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contato')),
                const SectionTitle('Projeto / expedição atual'),
                TextFormField(controller: _project, decoration: const InputDecoration(labelText: 'Nome do projeto')),
                const SectionTitle('Formato do código'),
                TextFormField(
                  controller: _pattern,
                  decoration: InputDecoration(
                    labelText: 'Padrão',
                    helperText: 'Tokens: {PREFIXO} {AAAA} {AA} {MM} {DD} {SEQ4}\nExemplo: $preview',
                    helperMaxLines: 3,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o padrão';
                    if (!RegExp(r'\{SEQ\d*\}').hasMatch(v)) return 'Inclua {SEQ} ou {SEQn} para numerar';
                    return null;
                  },
                ),
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
