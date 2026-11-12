import 'package:geolocator/geolocator.dart';

import '../core/errors.dart';

/// Leitura de GPS com tratamento de serviço desligado e permissão negada.
class LocationService {
  /// Limite de precisão aceitável (metros); acima disso o app avisa.
  static const goodAccuracyMeters = 20.0;

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
  );

  /// Verifica serviço e permissão. Lança [AppException] com mensagem clara.
  /// A explicação de *por que* pedimos a permissão é mostrada pela tela
  /// antes de chamar este método.
  Future<void> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabled();
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw const AppException('Permissão de localização negada.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDenied();
    }
  }

  Future<bool> needsPermissionPrompt() async =>
      await Geolocator.checkPermission() == LocationPermission.denied;

  /// Uma leitura única.
  Future<Position> current({Duration timeout = const Duration(seconds: 30)}) async {
    await ensureReady();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best, timeLimit: timeout),
      );
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw const AppException(
            'Não foi possível obter sinal de GPS. Vá para um local aberto e tente novamente.');
      }
      rethrow;
    }
  }

  /// Fluxo contínuo de posições, usado em "Aguardar melhor precisão".
  Stream<Position> stream() => Geolocator.getPositionStream(locationSettings: _settings);

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}

class LocationServiceDisabled extends AppException {
  const LocationServiceDisabled() : super('O GPS está desligado. Ative a localização do aparelho.');
}

class LocationPermissionPermanentlyDenied extends AppException {
  const LocationPermissionPermanentlyDenied()
      : super('Permissão de localização bloqueada. Libere nas configurações do app.');
}
