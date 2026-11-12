// Conteúdo do QR code das etiquetas. Dart puro.

import 'dart:convert';

import '../../core/format.dart';
import '../../domain/models.dart';

/// JSON compacto com o código e os dados principais. Chaves curtas para
/// manter o QR pequeno e legível em etiquetas de 50×30 mm.
///
/// `{"c":"CAC-2026-0001","m":"Cacau","d":"2026-11-03","col":"Ana Souza",
///   "cl":"CCN-51","mun":"Ilhéus/BA","lat":-14.7935,"lon":-39.172}`
String qrPayload(Sample s, SampleTemplate? t) {
  final map = <String, Object?>{
    'c': s.sampleCode,
    if (t != null) 'm': t.name,
    'd': fmtIsoDate(s.collectedAt),
    if (s.collectorName.isNotEmpty) 'col': s.collectorName,
    if (s.cloneGenotype.isNotEmpty) 'cl': s.cloneGenotype,
    if (s.place.isNotEmpty) 'mun': s.place,
    if (s.latitude != null) 'lat': double.parse(s.latitude!.toStringAsFixed(6)),
    if (s.longitude != null) 'lon': double.parse(s.longitude!.toStringAsFixed(6)),
  };
  return jsonEncode(map);
}

/// Extrai o código da amostra de um QR lido. Aceita o JSON do SampleTag ou
/// um texto simples contendo só o código.
String? codeFromQr(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  if (text.startsWith('{')) {
    try {
      final v = jsonDecode(text);
      if (v is Map && v['c'] is String) return (v['c'] as String).trim();
    } on FormatException {
      return null;
    }
    return null;
  }
  return text;
}
