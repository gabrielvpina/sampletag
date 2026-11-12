// QR code como SVG inline (para o relatório HTML). Dart puro.

import 'package:qr/qr.dart';

/// Gera um `<svg>` com o QR code de [data]. Cada módulo escuro vira um
/// trecho de um único `<path>`, o que mantém o SVG pequeno.
String qrSvg(String data, {int size = 140, String title = 'QR code'}) {
  final code = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
  final image = QrImage(code);
  final n = image.moduleCount;
  const quiet = 2; // margem em módulos
  final total = n + quiet * 2;
  final path = StringBuffer();
  for (var y = 0; y < n; y++) {
    var x = 0;
    while (x < n) {
      if (image.isDark(y, x)) {
        // Agrupa módulos escuros consecutivos na mesma linha.
        var run = 1;
        while (x + run < n && image.isDark(y, x + run)) {
          run++;
        }
        path.write('M${x + quiet} ${y + quiet}h${run}v1h-${run}z');
        x += run;
      } else {
        x++;
      }
    }
  }
  final safeTitle = title
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $total $total" '
      'width="$size" height="$size" shape-rendering="crispEdges" role="img">'
      '<title>$safeTitle</title>'
      '<rect width="$total" height="$total" fill="#fff"/>'
      '<path d="$path" fill="#000"/></svg>';
}
