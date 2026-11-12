// Etiquetas em PDF no layout da ficha original. Dart puro (pacote `pdf`).

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../domain/models.dart';
import 'qr_payload.dart';

enum LabelSize {
  small('50 × 30 mm', 50, 30),
  medium('100 × 70 mm', 100, 70),
  a4('A4 (várias etiquetas)', 210, 297);

  const LabelSize(this.label, this.widthMm, this.heightMm);
  final String label;
  final double widthMm;
  final double heightMm;
}

/// As fontes-padrão do PDF (Helvetica) cobrem só Latin-1. Para que textos
/// digitados no campo não virem quadrados, trocamos pontuação tipográfica
/// comum por equivalentes ASCII e o restante por '?'.
String pdfSafe(String s) {
  const map = {
    0x2013: '-', 0x2014: '-', 0x2018: "'", 0x2019: "'", 0x201C: '"', 0x201D: '"',
    0x2026: '...', 0x2022: '·', 0x2192: '->', 0x20AC: 'EUR', 0x00A0: ' ',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    if (map.containsKey(r)) {
      b.write(map[r]);
    } else if (r <= 0xFF) {
      b.writeCharCode(r);
    } else {
      b.write('?');
    }
  }
  return b.toString();
}

class LabelPdf {
  const LabelPdf();

  static const _green = PdfColor.fromInt(0xFF3D5C40);
  static const _sage = PdfColor.fromInt(0xFFA8B08C);

  /// Gera o PDF. Para 50×30 e 100×70 há uma etiqueta por página (formato de
  /// impressoras térmicas); em A4 as etiquetas de 100×70 mm são distribuídas
  /// em grade 2×4 com linhas de corte.
  Future<Uint8List> build(
    List<Sample> samples,
    Map<String, SampleTemplate> templates,
    LabelSize size,
  ) async {
    final doc = pw.Document(title: 'Etiquetas SampleTag', creator: 'SampleTag');
    switch (size) {
      case LabelSize.small:
      case LabelSize.medium:
        final format = PdfPageFormat(size.widthMm * PdfPageFormat.mm, size.heightMm * PdfPageFormat.mm);
        for (final s in samples) {
          doc.addPage(pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (_) => size == LabelSize.small
                ? _small(s, templates[s.templateId])
                : _medium(s, templates[s.templateId]),
          ));
        }
      case LabelSize.a4:
        const perPage = 8;
        const w = 100 * PdfPageFormat.mm, h = 70 * PdfPageFormat.mm;
        for (var i = 0; i < samples.length; i += perPage) {
          final chunk = samples.skip(i).take(perPage).toList();
          doc.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 5 * PdfPageFormat.mm, vertical: 8.5 * PdfPageFormat.mm),
            build: (_) => pw.Wrap(
              children: [
                for (final s in chunk)
                  pw.Container(
                    width: w,
                    height: h,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey500, width: 0.3, style: pw.BorderStyle.dashed),
                    ),
                    child: _medium(s, templates[s.templateId]),
                  ),
              ],
            ),
          ));
        }
    }
    if (samples.isEmpty) {
      doc.addPage(pw.Page(build: (_) => pw.Center(child: pw.Text('Nenhuma amostra selecionada.'))));
    }
    return doc.save();
  }

  pw.Widget _header(SampleTemplate? t, double fontSize, {double padV = 3}) => pw.Container(
        width: double.infinity,
        color: t != null ? PdfColor.fromInt(t.color) : _green,
        padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: padV),
        child: pw.Text(
          pdfSafe('FICHA DE AMOSTRA - ${(t?.name ?? '').toUpperCase()}'),
          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: fontSize),
          maxLines: 1,
        ),
      );

  pw.Widget _footer(String text, double fontSize) => pw.Container(
        width: double.infinity,
        color: _sage,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(pdfSafe(text), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), maxLines: 2),
      );

  pw.Widget _qr(Sample s, SampleTemplate? t, double size) => pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
        data: qrPayload(s, t),
        width: size,
        height: size,
        drawText: false,
      );

  /// 50×30 mm: cabeçalho, código, data, local e QR.
  pw.Widget _small(Sample s, SampleTemplate? t) {
    final small = const pw.TextStyle(fontSize: 5.5);
    return pw.Column(children: [
      _header(t, 5.5, padV: 1.5),
      pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(pdfSafe(s.sampleCode), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(fmtDateTime(s.collectedAt), style: small),
                if (s.cloneGenotype.isNotEmpty) pw.Text(pdfSafe('Clone: ${s.cloneGenotype}'), style: small, maxLines: 1),
                if (s.place.isNotEmpty) pw.Text(pdfSafe(s.place), style: small, maxLines: 1),
                if (s.collectorName.isNotEmpty) pw.Text(pdfSafe(s.collectorName), style: small, maxLines: 1),
              ]),
            ),
            _qr(s, t, 19 * PdfPageFormat.mm),
          ]),
        ),
      ),
      if (s.storageInstruction.isNotEmpty) _footer(s.storageInstruction, 4.5),
    ]);
  }

  /// 100×70 mm: layout completo da ficha.
  pw.Widget _medium(Sample s, SampleTemplate? t) {
    pw.Widget field(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2.2),
          child: pw.RichText(
            maxLines: 1,
            text: pw.TextSpan(children: [
              pw.TextSpan(text: pdfSafe('$label: '), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.TextSpan(text: pdfSafe(value), style: const pw.TextStyle(fontSize: 7.5)),
            ]),
          ),
        );
    final extras = [
      for (final f in t?.fields ?? const <TemplateField>[])
        if (fmtCustomValue(s.customFields[f.key]).isNotEmpty) (f.label, fmtCustomValue(s.customFields[f.key])),
    ].take(3);
    return pw.Column(children: [
      _header(t, 9, padV: 4),
      pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(5, 4, 5, 2),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(pdfSafe(s.sampleCode), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                field('Data', fmtDateTime(s.collectedAt)),
                field('Coletor', s.collectorName),
                if (s.collectorContact.isNotEmpty) field('Contato', s.collectorContact),
                field('Clone/genótipo', s.cloneGenotype),
                field('Origem', s.originProperty),
                field('Município/UF', s.place),
                if (s.hasLocation) field('Lat/Lon', fmtLatLon(s.latitude, s.longitude)),
                for (final e in extras) field(e.$1, e.$2),
              ]),
            ),
            pw.SizedBox(width: 4),
            pw.Column(children: [
              _qr(s, t, 30 * PdfPageFormat.mm),
              pw.SizedBox(height: 2),
              pw.Text(pdfSafe(s.sampleCode), style: const pw.TextStyle(fontSize: 6)),
            ]),
          ]),
        ),
      ),
      if (s.storageInstruction.isNotEmpty) _footer(s.storageInstruction, 7.5),
    ]);
  }
}
