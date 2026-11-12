import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../providers.dart';
import 'errors.dart';

/// Bolinha com a cor do modelo.
class TemplateDot extends StatelessWidget {
  const TemplateDot(this.template, {super.key, this.size = 12});
  final SampleTemplate? template;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color(template?.color ?? 0xFF3D5C40),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
      );
}

/// Foto salva (nome relativo) exibida como miniatura.
class PhotoThumb extends ConsumerWidget {
  const PhotoThumb(this.name, {super.key, this.size = 64, this.fit = BoxFit.cover, this.radius = 10});
  final String name;
  final double? size;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(photoServiceProvider).resolve(name),
      builder: (context, snap) {
        final placeholder = Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image_outlined),
        );
        if (!snap.hasData) return placeholder;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(snap.data!),
            width: size,
            height: size,
            fit: fit,
            // Decodifica em resolução reduzida para economizar memória.
            cacheWidth: size == null ? null : (size! * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (_, _, _) => placeholder,
          ),
        );
      },
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: error ? scheme.onErrorContainer : null)),
      backgroundColor: error ? scheme.errorContainer : null,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 6 : 3),
    ));
}

void showError(BuildContext context, Object e) => showMessage(context, friendlyError(e), error: true);

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Título de seção usado em formulários e detalhes.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

/// Diálogo com um campo de texto. O controller pertence ao próprio diálogo
/// e é descartado só quando ele sai da árvore (depois da animação de
/// fechamento) — descartar logo após o `pop` causa erro de "controller used
/// after being disposed".
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? message,
  String? label,
  String? hint,
  int? maxLength,
  Key? fieldKey,
  String confirmLabel = 'OK',
  bool cancelable = true,
  TextCapitalization capitalization = TextCapitalization.none,
}) =>
    showDialog<String>(
      context: context,
      barrierDismissible: cancelable,
      builder: (_) => _PromptDialog(
        title: title,
        message: message,
        label: label,
        hint: hint,
        maxLength: maxLength,
        fieldKey: fieldKey,
        confirmLabel: confirmLabel,
        cancelable: cancelable,
        capitalization: capitalization,
      ),
    );

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    this.message,
    this.label,
    this.hint,
    this.maxLength,
    this.fieldKey,
    required this.confirmLabel,
    required this.cancelable,
    required this.capitalization,
  });

  final String title;
  final String? message;
  final String? label;
  final String? hint;
  final int? maxLength;
  final Key? fieldKey;
  final String confirmLabel;
  final bool cancelable;
  final TextCapitalization capitalization;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: 12)],
            TextField(
              key: widget.fieldKey,
              controller: _ctrl,
              autofocus: true,
              maxLength: widget.maxLength,
              textCapitalization: widget.capitalization,
              decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
          ]),
        ),
        actions: [
          if (widget.cancelable) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: Text(widget.confirmLabel)),
        ],
      );
}
