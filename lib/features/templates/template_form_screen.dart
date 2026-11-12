import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../providers.dart';

/// Paleta de cores sugeridas (boa leitura com texto branco).
const _palette = [
  0xFF3D5C40, 0xFF6B4F2A, 0xFF8C3B2E, 0xFF2F5D7C, 0xFF5B3F7A,
  0xFF7A6A1F, 0xFF1F6E64, 0xFF9A4A1A, 0xFF4A4A4A, 0xFF2E7D32,
];

class TemplateFormScreen extends ConsumerStatefulWidget {
  const TemplateFormScreen({super.key, this.existing});
  final SampleTemplate? existing;

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _prefix = TextEditingController(text: widget.existing?.codePrefix);
  late final _storage = TextEditingController(text: widget.existing?.defaultStorageInstruction);
  late int _color = widget.existing?.color ?? _palette.first;
  late SampleCategory _category = widget.existing?.category ?? SampleCategory.biological;
  late List<TemplateField> _fields = [...?widget.existing?.fields];

  @override
  void dispose() {
    _name.dispose();
    _prefix.dispose();
    _storage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = SampleTemplate(
      id: widget.existing?.id ?? 'tpl-${const Uuid().v4()}',
      name: _name.text.trim(),
      codePrefix: _prefix.text.trim().toUpperCase(),
      color: _color,
      defaultStorageInstruction: _storage.text.trim(),
      category: _category,
      fields: _fields,
    );
    try {
      await ref.read(templateRepoProvider).upsert(t);
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete() async {
    final t = widget.existing!;
    final used = await ref.read(templateRepoProvider).usageCount(t.id);
    if (!mounted) return;
    if (used > 0) {
      showMessage(context, 'Modelo em uso por $used amostra(s); não pode ser excluído.', error: true);
      return;
    }
    if (await confirm(context, title: 'Excluir modelo "${t.name}"?', message: 'Esta ação não pode ser desfeita.', confirmLabel: 'Excluir', destructive: true)) {
      await ref.read(templateRepoProvider).delete(t.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editField([int? index]) async {
    final result = await showDialog<TemplateField>(
      context: context,
      builder: (_) => _FieldDialog(field: index == null ? null : _fields[index], existingKeys: {
        for (var i = 0; i < _fields.length; i++)
          if (i != index) _fields[i].key,
      }),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _fields = [..._fields, result];
      } else {
        _fields = [..._fields]..[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Novo modelo' : 'Editar modelo'),
        actions: [
          if (widget.existing != null) IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Salvar modelo')),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome (ex.: Cacau) *'),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _prefix,
            decoration: const InputDecoration(labelText: 'Prefixo do código (ex.: CAC) *'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o prefixo' : null,
          ),
          TextFormField(controller: _storage, decoration: const InputDecoration(labelText: 'Instrução de armazenamento padrão')),
          const SizedBox(height: 12),
          SegmentedButton<SampleCategory>(
            segments: [for (final c in SampleCategory.values) ButtonSegment(value: c, label: Text(c.label))],
            selected: {_category},
            onSelectionChanged: (s) => setState(() => _category = s.first),
          ),
          const SectionTitle('Cor'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in _palette)
              Semantics(
                label: 'Cor ${c.toRadixString(16)}',
                selected: c == _color,
                button: true,
                child: InkWell(
                  onTap: () => setState(() => _color = c),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: c == _color ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 3),
                    ),
                    child: c == _color ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
              ),
          ]),
          const SectionTitle('Campos extras'),
          if (_fields.isEmpty) const Text('Nenhum campo extra.'),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (a, b) => setState(() {
              final list = [..._fields];
              final item = list.removeAt(a);
              list.insert(b, item);
              _fields = list;
            }),
            children: [
              for (var i = 0; i < _fields.length; i++)
                Card(
                  key: ValueKey(_fields[i].key),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                    title: Text('${_fields[i].label}${_fields[i].required ? ' *' : ''}'),
                    subtitle: Text([
                      _fields[i].type.label,
                      if (_fields[i].type == FieldType.list) _fields[i].options.join(', '),
                    ].join(' · ')),
                    onTap: () => _editField(i),
                    trailing: IconButton(
                      tooltip: 'Remover campo',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() => _fields = [..._fields]..removeAt(i)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _editField(), icon: const Icon(Icons.add), label: const Text('Adicionar campo')),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _FieldDialog extends StatefulWidget {
  const _FieldDialog({this.field, required this.existingKeys});
  final TemplateField? field;
  final Set<String> existingKeys;

  @override
  State<_FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<_FieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.field?.label);
  late final _options = TextEditingController(text: widget.field?.options.join('\n'));
  late FieldType _type = widget.field?.type ?? FieldType.text;
  late bool _required = widget.field?.required ?? false;

  @override
  void dispose() {
    _label.dispose();
    _options.dispose();
    super.dispose();
  }

  /// Chave estável derivada do rótulo (só para campos novos).
  String _keyFor(String label) {
    var base = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (base.isEmpty) base = 'campo';
    var key = base;
    var n = 2;
    while (widget.existingKeys.contains(key)) {
      key = '${base}_${n++}';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.field == null ? 'Novo campo' : 'Editar campo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Nome do campo'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FieldType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [for (final t in FieldType.values) DropdownMenuItem(value: t, child: Text(t.label))],
              onChanged: (v) => setState(() => _type = v!),
            ),
            if (_type == FieldType.list) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _options,
                decoration: const InputDecoration(labelText: 'Opções (uma por linha)'),
                minLines: 3,
                maxLines: 8,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe ao menos uma opção' : null,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obrigatório'),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              TemplateField(
                key: widget.field?.key ?? _keyFor(_label.text.trim()),
                label: _label.text.trim(),
                type: _type,
                required: _required,
                options: _type == FieldType.list
                    ? _options.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                    : const [],
              ),
            );
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
