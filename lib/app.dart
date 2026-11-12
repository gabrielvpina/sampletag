import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'features/home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';

class SampleTagApp extends ConsumerWidget {
  const SampleTagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider).value?.themeMode ?? 'system';
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('pt'), Locale('en')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Pacotes que ainda usam package:flutter/material.dart (flutter_map,
      // printing, mobile_scanner) precisam desta ponte de tema/localização.
      // A ponte é marcada como temporária; remover quando esses pacotes
      // migrarem para material_ui.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
      home: const HomeShell(),
    );
  }
}
