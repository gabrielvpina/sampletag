import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/widgets.dart';
import '../../providers.dart';
import '../../services/export/qr_payload.dart';
import '../samples/sample_detail_screen.dart';

/// Lê o QR da etiqueta e abre a amostra correspondente.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    _handling = true;
    try {
      await _open(raw);
    } finally {
      _handling = false;
    }
  }

  Future<void> _open(String raw) async {
    final code = codeFromQr(raw);
    if (code == null) {
      showMessage(context, 'QR code não reconhecido.', error: true);
      return;
    }
    final sample = await ref.read(sampleRepoProvider).getByCode(code);
    if (!mounted) return;
    if (sample == null) {
      showMessage(context, 'Amostra $code não está cadastrada neste aparelho.', error: true);
      return;
    }
    await _controller.stop();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SampleDetailScreen(sampleId: sample.id)));
    if (mounted) await _controller.start();
  }

  Future<void> _typeCode() async {
    final code = await promptText(
      context,
      title: 'Digitar código',
      hint: 'CAC-AS-2026-0001',
      confirmLabel: 'Abrir',
      capitalization: TextCapitalization.characters,
    );
    if (code != null && code.trim().isNotEmpty) await _open(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear etiqueta'),
        actions: [
          IconButton(tooltip: 'Lanterna', icon: const Icon(Icons.flashlight_on_outlined), onPressed: _controller.toggleTorch),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _ScannerError(error: error, onType: _typeCode),
        ),
        // Moldura de mira.
        IgnorePointer(
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: FilledButton.icon(
            onPressed: _typeCode,
            icon: const Icon(Icons.keyboard),
            label: const Text('Digitar código'),
          ),
        ),
      ]),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onType});
  final MobileScannerException error;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'O SampleTag precisa da câmera para ler o QR code das etiquetas. '
                      'Libere a permissão nas configurações do aparelho.'
                  : 'Não foi possível abrir a câmera (${error.errorCode.name}).',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}
