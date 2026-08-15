import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/serial_normalizer.dart';

void main() {
  const normalizer = SerialNormalizer();

  group('SerialNormalizer', () {
    test('trims and collapses whitespace', () {
      expect(normalizer.normalize('  ABC  123  '), 'ABC 123');
      expect(normalizer.normalize('ABC\t\n123'), 'ABC 123');
    });

    test('preserves leading zeros', () {
      expect(normalizer.normalize('001234'), '001234');
      expect(normalizer.normalize(' 00056 '), '00056');
    });

    test('preserves letters, digits, and meaningful separators', () {
      expect(normalizer.normalize('CAT-320-0A1'), 'CAT-320-0A1');
      expect(normalizer.normalize('PIN/1234.56'), 'PIN/1234.56');
      expect(normalizer.normalize('SN_00_99'), 'SN_00_99');
    });

    test('strips leading serial labels from storage form', () {
      expect(normalizer.normalizeForStorage('S/N 50252M6304'), '50252M6304');
      expect(normalizer.normalizeForStorage('S/No 50252M6304'), '50252M6304');
      expect(
        normalizer.normalizeForStorage('SERIAL NO 50252M6304'),
        '50252M6304',
      );
      expect(normalizer.normalizeForStorage('SERIAL 50252M6304'), '50252M6304');
      expect(normalizer.normalizeForStorage('SlNo 50252M6304'), '50252M6304');
      expect(normalizer.normalizeForStorage('SINo 50252M6304'), '50252M6304');
      expect(normalizer.normalizeForStorage('Serial: ABC123'), 'ABC123');
    });

    test(
      'collapses consecutive ASCII hyphens without changing letters/digits',
      () {
        expect(normalizer.normalize('ABC--123'), 'ABC-123');
        expect(normalizer.normalize('ABC---123'), 'ABC-123');
        expect(normalizer.normalize('ABC-123'), 'ABC-123');
        expect(normalizer.normalizeForStorage('ABC--123'), 'ABC-123');
        expect(normalizer.normalizeForStorage('S/No ABC--123'), 'ABC-123');
      },
    );

    test('preserves legitimate single internal hyphens', () {
      expect(normalizer.normalize('SN-0099'), 'SN-0099');
      expect(normalizer.normalizeForStorage('SN-0099'), 'SN-0099');
      expect(normalizer.normalize('CAT-320-0A1'), 'CAT-320-0A1');
    });

    test('does not strip SN- hyphenated serials', () {
      expect(normalizer.normalizeForStorage('SN-0099'), 'SN-0099');
      expect(normalizer.normalizeForStorage('  SN-ABC-99  '), 'SN-ABC-99');
      expect(normalizer.normalizeForStorage('SN--0099'), 'SN-0099');
    });

    test('removes obvious formatting noise without inventing characters', () {
      expect(normalizer.normalize('#CAT-320*'), 'CAT-320');
      expect(normalizer.normalize('"ABC123"'), 'ABC123');
      expect(normalizer.normalize('Serial: ABC123'), 'Serial ABC123');
    });

    test('strips zero-width noise', () {
      expect(normalizer.normalize('AB\u200BC123'), 'ABC123');
    });

    test('does not auto-correct ambiguous O/0 or I/1', () {
      expect(normalizer.normalize('O0I1'), 'O0I1');
      expect(normalizer.normalize('SERIALO'), 'SERIALO');
    });

    test('builds unique candidates and skips empty/noise-only', () {
      final candidates = normalizer.candidatesFromRawTexts([
        '  CAT-001  ',
        'CAT-001',
        '***',
        '  ',
        'MODEL 320',
        'PIN: 00A1',
      ]);
      expect(candidates, ['CAT-001', 'MODEL 320', 'PIN 00A1']);
    });

    test('handles multiple ambiguous serial-like candidates', () {
      final candidates = normalizer.candidatesFromRawTexts([
        'ABC123',
        'ABC124',
        'MODEL320',
      ]);
      expect(candidates, ['ABC123', 'ABC124', 'MODEL320']);
    });
  });
}
