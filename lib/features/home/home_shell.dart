import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../export/export_screen.dart';
import '../map/map_screen.dart';
import '../samples/sample_list_screen.dart';
import '../scanner/scan_screen.dart';
import '../settings/settings_screen.dart';

/// Navegação principal por abas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const SampleListScreen(),
          // O mapa e a câmera só são montados quando a aba está ativa
          // (economiza bateria e libera a câmera).
          _index == 1 ? const MapScreen() : const SizedBox.shrink(),
          _index == 2 ? const ScanScreen() : const SizedBox.shrink(),
          const ExportScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.list_alt_outlined), selectedIcon: const Icon(Icons.list_alt), label: l.navSamples),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: l.navMap),
          NavigationDestination(icon: const Icon(Icons.qr_code_scanner), label: l.navScan),
          NavigationDestination(icon: const Icon(Icons.ios_share_outlined), selectedIcon: const Icon(Icons.ios_share), label: l.navExport),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.navSettings),
        ],
      ),
    );
  }
}
