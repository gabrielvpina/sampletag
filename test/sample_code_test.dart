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

  group('{COLETOR}', () {
    const p = '{PREFIXO}-{COLETOR}-{AAAA}-{SEQ4}';

    test('entra no código e separa a numeração por coletor', () {
      expect(formatSampleCode(pattern: p, prefix: 'CAC', date: date, sequence: 1, collector: 'as'), 'CAC-AS-2026-0001');
      final codes = ['CAC-AS-2026-0001', 'CAC-AS-2026-0002', 'CAC-JL-2026-0009'];
      expect(nextSampleCode(existingCodes: codes, pattern: p, prefix: 'CAC', date: date, collector: 'AS'), 'CAC-AS-2026-0003');
      expect(nextSampleCode(existingCodes: codes, pattern: p, prefix: 'CAC', date: date, collector: 'JL'), 'CAC-JL-2026-0010');
      expect(nextSampleCode(existingCodes: codes, pattern: p, prefix: 'CAC', date: date, collector: 'MC'), 'CAC-MC-2026-0001');
    });

    test('iniciais a partir do nome, sem acentos nem preposições', () {
      expect(collectorInitials('Ana Souza'), 'AS');
      expect(collectorInitials('João da Silva Lima'), 'JL');
      expect(collectorInitials('Ângela'), 'AN');
      expect(collectorInitials('  '), '');
    });

    test('código digitado é normalizado', () {
      expect(normalizeCollectorCode(' a-s1x9 '), 'AS1X');
      expect(normalizeCollectorCode('é'), '');
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
