import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/format.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../../services/export/label_pdf.dart';

/// Pré-visualização das etiquetas, com impressão e compartilhamento do PDF
/// (barra de ações do `PdfPreview`).
class LabelScreen extends ConsumerStatefulWidget {
  const LabelScreen({super.key, required this.samples});
  final List<Sample> samples;

  @override
  ConsumerState<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends ConsumerState<LabelScreen> {
  late LabelSize _size = widget.samples.length > 1 ? LabelSize.a4 : LabelSize.medium;

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesByIdProvider);
    final fileName = widget.samples.length == 1
        ? 'Etiqueta_${safeFileName(widget.samples.first.sampleCode)}.pdf'
        : 'Etiquetas_SampleTag_${fmtIsoDate(DateTime.now())}.pdf';
    return Scaffold(
      appBar: AppBar(title: Text(widget.samples.length == 1 ? 'Etiqueta' : 'Etiquetas (${widget.samples.length})')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<LabelSize>(
            segments: [
              for (final s in LabelSize.values)
                ButtonSegment(value: s, label: Text(s == LabelSize.a4 ? 'A4' : s.label)),
            ],
            selected: {_size},
            onSelectionChanged: (s) => setState(() => _size = s.first),
          ),
        ),
        Expanded(
          child: PdfPreview(
            key: ValueKey(_size),
            build: (_) => const LabelPdf().build(widget.samples, templates, _size),
            pdfFileName: fileName,
            initialPageFormat: _size == LabelSize.a4
                ? PdfPageFormat.a4
                : PdfPageFormat(_size.widthMm * PdfPageFormat.mm, _size.heightMm * PdfPageFormat.mm),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
          ),
        ),
      ]),
    );
  }
}
