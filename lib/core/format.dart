// Formatação de datas, coordenadas e números (pt-BR). Dart puro.

import 'package:intl/intl.dart';

final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
final _date = DateFormat('dd/MM/yyyy');
final _isoDate = DateFormat('yyyy-MM-dd');

String fmtDateTime(DateTime d) => _dateTime.format(d);
String fmtDate(DateTime d) => _date.format(d);
String fmtIsoDate(DateTime d) => _isoDate.format(d);

/// Coordenada decimal com 6 casas (≈ 0,1 m), com ponto como separador
/// para facilitar a cópia para GIS.
String fmtCoord(double? v) => v == null ? '' : v.toStringAsFixed(6);

String fmtMeters(double? v, {int decimals = 1}) =>
    v == null ? '' : '${v.toStringAsFixed(decimals).replaceAll('.', ',')} m';

/// "-14.793500, -39.172000"
String fmtLatLon(double? lat, double? lon) =>
    lat == null || lon == null ? '' : '${fmtCoord(lat)}, ${fmtCoord(lon)}';

/// Valor de campo personalizado como texto.
String fmtCustomValue(Object? v) {
  if (v == null) return '';
  if (v is double) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
  }
  if (v is String) {
    // Datas de campos personalizados são guardadas em ISO (yyyy-MM-dd).
    final d = DateTime.tryParse(v);
    if (d != null && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v)) return fmtDate(d);
  }
  return v.toString();
}

/// Nome seguro para arquivos (sem acentos/espaços/caracteres especiais).
String safeFileName(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const to = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final buf = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
