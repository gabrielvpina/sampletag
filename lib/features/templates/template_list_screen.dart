import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/template_share.dart';
import '../../providers.dart';
import 'template_form_screen.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelos de ficha'),
        actions: [
          IconButton(
            key: const Key('import-template'),
            tooltip: 'Importar modelo recebido',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Novo modelo'),
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            if (i == list.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Para usar o mesmo modelo em outro celular, toque em compartilhar e envie o arquivo. '
                  'No outro celular, salve o arquivo e use o botão de importar no topo desta tela.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            final t = list[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 4),
                leading: TemplateDot(t, size: 28),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${t.codePrefix} · ${t.category.label} · ${t.fields.length} campo(s) extra(s)'),
                trailing: IconButton(
                  tooltip: 'Compartilhar modelo',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _share(context, ref, t),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateFormScreen(existing: t))),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref, SampleTemplate t) async {
    try {
      final svc = ref.read(exportServiceProvider);
      final file = await svc.templateFile(t);
      await svc.share(file, mime: 'application/json', subject: 'Modelo de ficha SampleTag: ${t.name}');
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    // Tipo "qualquer": apps de mensagem às vezes salvam o .json com outro
    // tipo MIME, e o filtro por extensão o esconderia. O conteúdo é validado.
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty || !context.mounted) return;
    try {
      final incoming = decodeTemplateFile(await files.first.readAsBytes());
      final repo = ref.read(templateRepoProvider);
      final local = await repo.getAll();
      final (match, existing) = matchTemplate(incoming, local);
      if (!context.mounted) return;
      switch (match) {
        case TemplateMatch.identical:
          showMessage(context, 'O modelo "${existing!.name}" já está neste aparelho, sem diferenças.');
        case TemplateMatch.none:
          final ok = await confirm(
            context,
            title: 'Importar modelo "${incoming.name}"?',
            message: _describe(incoming),
            confirmLabel: 'Importar',
          );
          if (!ok) return;
          await repo.upsert(incoming);
          if (context.mounted) showMessage(context, 'Modelo "${incoming.name}" importado.');
        case TemplateMatch.differs:
          final choice = await showDialog<String>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('"${existing!.name}" já existe'),
              content: Text('O modelo recebido é diferente do que está neste aparelho.\n\n'
                  'Recebido: ${_describe(incoming)}\n\n'
                  'Atualizar substitui os campos do modelo atual (os dados das amostras já salvas são mantidos). '
                  'Importar como cópia cria um modelo separado.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(c, 'copy'), child: const Text('Importar como cópia')),
                FilledButton(onPressed: () => Navigator.pop(c, 'update'), child: const Text('Atualizar')),
              ],
            ),
          );
          if (choice == null) return;
          final saved = choice == 'update'
              ? SampleTemplate(
                  id: existing!.id,
                  name: incoming.name,
                  codePrefix: incoming.codePrefix,
                  color: incoming.color,
                  defaultStorageInstruction: incoming.defaultStorageInstruction,
                  category: incoming.category,
                  fields: incoming.fields,
                )
              : templateCopy(incoming, 'tpl-${const Uuid().v4()}', local);
          await repo.upsert(saved);
          if (context.mounted) {
            showMessage(context, choice == 'update' ? 'Modelo "${saved.name}" atualizado.' : 'Modelo "${saved.name}" criado.');
          }
      }
    } on FormatException catch (e) {
      if (context.mounted) showMessage(context, e.message, error: true);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static String _describe(SampleTemplate t) {
    final fields = t.fields.map((f) => f.label).join(', ');
    return 'Prefixo ${t.codePrefix}, ${t.category.label.toLowerCase()}, '
        '${t.fields.length} campo(s) extra(s)${fields.isEmpty ? '' : ': $fields'}.';
  }
}
