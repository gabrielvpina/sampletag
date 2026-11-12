import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/domain/geo.dart';
import 'package:sampletag/domain/models.dart';
import 'package:sampletag/domain/seed_data.dart';

void main() {
  final lib = GeoLibrary((path) => File(path).readAsString());

  test('arquivos do IBGE: 27 UFs e municípios com nome', () async {
    final states = await lib.states();
    expect(states.map((s) => s.id).toSet(), brazilStates.keys.toSet());
    final ba = await lib.municipalities('BA');
    expect(ba, hasLength(417));
    expect(ba.map((m) => m.name), contains('Ilhéus'));
    expect(await lib.municipalities('XX'), isEmpty);
  });

  test('localiza UF e município offline pelas coordenadas das amostras de exemplo', () async {
    for (final s in demoSamples()) {
      final place = await lib.locate(s.latitude!, s.longitude!);
      expect(place?.uf, 'BA', reason: s.sampleCode);
      expect(place?.municipality, s.municipality, reason: s.sampleCode);
    }
    final sp = await lib.locate(-23.5505, -46.6333);
    expect((sp?.uf, sp?.municipality), ('SP', 'São Paulo'));
    // Oceano Atlântico: fora do Brasil.
    expect(await lib.locate(-15.0, -35.0), isNull);
  });

  test('codificação polyline é reversível com 4 casas', () {
    final ring = <GeoPoint>[(lon: -39.1720, lat: -14.7935), (lon: -39.5032, lat: -15.4140), (lon: 0, lat: 0), (lon: -39.1720, lat: -14.7935)];
    final dec = decodeRing(encodeRing(ring));
    expect(dec, hasLength(ring.length));
    for (var i = 0; i < ring.length; i++) {
      expect(dec[i].lon, closeTo(ring[i].lon, 1e-9));
      expect(dec[i].lat, closeTo(ring[i].lat, 1e-9));
    }
    // Caracteres seguros para JSON/HTML (sem < > &).
    expect(encodeRing(ring), isNot(matches(RegExp('[<>&"]'))));
  });

  test('simplificação reduz pontos e mantém anéis válidos', () async {
    final ba = (await lib.states()).firstWhere((s) => s.id == 'BA');
    int count(GeoFeature f) => f.polygons.expand((p) => p).fold(0, (n, r) => n + r.length);
    final simple = ba.simplified(0.01);
    expect(count(simple), lessThan(count(ba)));
    expect(simple.polygons.expand((p) => p).every((r) => r.length >= 4), isTrue);
    expect(simple.contains(-14.79, -39.17), isTrue);
  });

  test('UFs em destaque: amostras + escolhidas, ignorando inválidas', () {
    expect(effectiveStates(['BA', 'ba', '', 'XX'], ['es', 'MG']), {'BA', 'ES', 'MG'});
  });

  test('configurações do mapa sobrevivem ao salvar/ler', () {
    const s = AppSettings(mapStates: {'ES', 'BA'}, municipalBoundaries: false);
    final back = AppSettings.fromMap(s.toMap());
    expect(back.mapStates, {'BA', 'ES'});
    expect(back.municipalBoundaries, isFalse);
    expect(AppSettings.fromMap(const {}).municipalBoundaries, isTrue);
  });

  test('ReportGeo inclui municípios só das UFs em destaque', () async {
    final geo = await ReportGeo.build(lib, highlighted: {'SE'}, includeMunicipalities: true);
    expect(geo.states, hasLength(27));
    expect(geo.municipalities, hasLength(75));
    final json = geo.toJson();
    expect((json['states'] as List).where((s) => (s as Map)['h'] == true), hasLength(1));
    final none = await ReportGeo.build(lib, highlighted: {'SE'}, includeMunicipalities: false);
    expect(none.municipalities, isEmpty);
  });
}
