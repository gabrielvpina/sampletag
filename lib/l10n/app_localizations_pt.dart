// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'SampleTag';

  @override
  String get navSamples => 'Amostras';

  @override
  String get navMap => 'Mapa';

  @override
  String get navScan => 'Escanear';

  @override
  String get navExport => 'Exportar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get newSample => 'Nova amostra';

  @override
  String get editSample => 'Editar amostra';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String sampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amostras',
      one: '1 amostra',
      zero: 'Nenhuma amostra',
    );
    return '$_temp0';
  }
}
