import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';

/// Resultado da geocodificação reversa.
class PlaceInfo {
  const PlaceInfo({required this.municipality, required this.state});
  final String municipality;
  final String state;
}

/// Geocodificação reversa (coordenadas -> município/UF). Só funciona com
/// internet; falhas retornam `null` silenciosamente, pois os campos são
/// editáveis manualmente.
class GeocodingService {
  GeocodingService() : _geo = Geocoding(locale: const Locale('pt', 'BR'));

  final Geocoding _geo;

  Future<PlaceInfo?> reverse(double lat, double lon) async {
    try {
      final list = await _geo
          .placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 8));
      if (list.isEmpty) return null;
      final p = list.first;
      // No Brasil o município costuma vir em subAdministrativeArea; em alguns
      // aparelhos vem em locality.
      final city = (p.subAdministrativeArea?.isNotEmpty ?? false)
          ? p.subAdministrativeArea!
          : (p.locality ?? '');
      return PlaceInfo(municipality: city, state: ufFromStateName(p.administrativeArea ?? ''));
    } on Object {
      return null;
    }
  }
}

const _ufByName = {
  'acre': 'AC', 'alagoas': 'AL', 'amapá': 'AP', 'amazonas': 'AM', 'bahia': 'BA',
  'ceará': 'CE', 'distrito federal': 'DF', 'espírito santo': 'ES', 'goiás': 'GO',
  'maranhão': 'MA', 'mato grosso': 'MT', 'mato grosso do sul': 'MS',
  'minas gerais': 'MG', 'pará': 'PA', 'paraíba': 'PB', 'paraná': 'PR',
  'pernambuco': 'PE', 'piauí': 'PI', 'rio de janeiro': 'RJ',
  'rio grande do norte': 'RN', 'rio grande do sul': 'RS', 'rondônia': 'RO',
  'roraima': 'RR', 'santa catarina': 'SC', 'são paulo': 'SP', 'sergipe': 'SE',
  'tocantins': 'TO',
};

/// Converte "Bahia" -> "BA". Se já for sigla, mantém; se desconhecido,
/// devolve o texto original.
String ufFromStateName(String name) {
  final n = name.trim();
  if (n.length == 2) return n.toUpperCase();
  final cleaned = n.toLowerCase().replaceFirst(RegExp(r'^(state of|estado d[eao])\s+'), '');
  return _ufByName[cleaned] ?? n;
}
