import 'package:flutter_test/flutter_test.dart';
import 'package:sampletag/domain/sample_code.dart';

void main() {
  final date = DateTime(2026, 3, 7);
  const pattern = '{PREFIXO}-{AAAA}-{SEQ4}';

  group('formatSampleCode', () {
    test('padrão padrão gera CAC-2026-0001', () {
      expect(formatSampleCode(pattern: pattern, prefix: 'cac', date: date, sequence: 1), 'CAC-2026-0001');
    });

    test('suporta todos os tokens e largura de sequência', () {
      expect(
        formatSampleCode(pattern: '{PREFIXO}{AA}{MM}{DD}.{SEQ6}', prefix: 'X', date: date, sequence: 42),
        'X260307.000042',
      );
      expect(formatSampleCode(pattern: '{SEQ}', prefix: 'X', date: date, sequence: 7), '0007');
    });

    test('sequência maior que a largura não é truncada', () {
      expect(formatSampleCode(pattern: pattern, prefix: 'CAC', date: date, sequence: 12345), 'CAC-2026-12345');
    });
  });

  group('nextSampleCode', () {
    test('primeira amostra', () {
      expect(nextSampleCode(existingCodes: const [], pattern: pattern, prefix: 'CAC', date: date), 'CAC-2026-0001');
    });

    test('usa o maior número existente + 1, ignorando outros prefixos/anos e códigos manuais', () {
      final codes = ['CAC-2026-0001', 'CAC-2026-0007', 'CAC-2025-0099', 'CAF-2026-0050', 'CAC-2026-ESPECIAL'];
      expect(nextSampleCode(existingCodes: codes, pattern: pattern, prefix: 'CAC', date: date), 'CAC-2026-0008');
    });

    test('caracteres especiais no padrão são tratados como literais', () {
      const p = '{PREFIXO}.{AAAA}.{SEQ3}';
      final codes = ['CAC.2026.004', 'CACX2026X009'];
      expect(nextSampleCode(existingCodes: codes, pattern: p, prefix: 'CAC', date: date), 'CAC.2026.005');
    });

    test('padrão sem {SEQ} evita colisão com sufixo', () {
      const p = '{PREFIXO}-{AAAA}{MM}{DD}';
      expect(nextSampleCode(existingCodes: ['CAC-20260307'], pattern: p, prefix: 'CAC', date: date), 'CAC-20260307-2');
    });
  });
}
