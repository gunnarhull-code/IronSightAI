import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/serial_field_extractor.dart';

/// Transcribed Samsung S22 serial-plate OCR evidence (Work Item regression).
const s22PlateBlocks = [
  '25-RC1H S/No 50252M6304 MAST',
  'HT kg 4140 1070',
  'Tyre pressure 900 kPa 10.00 bar',
  'Load centre 500 mm',
  'Capacity 2500 kg',
  'Tyre type 250-15',
  'Production date 2021',
];

void main() {
  const extractor = SerialFieldExtractor();

  group('SerialFieldExtractor ranking', () {
    test('S22 plate recommends labelled serial and hides plate noise', () {
      final result = extractor.extract(s22PlateBlocks);

      expect(result.recommended?.value, '50252M6304');
      expect(result.recommended?.labelled, isTrue);
      expect(result.recommended!.confidence, greaterThanOrEqualTo(0.8));

      final visible = result.visibleCandidates.map((c) => c.value).toList();
      expect(visible, contains('50252M6304'));
      expect(visible, isNot(contains('25-RC1H')));
      expect(visible, isNot(contains('4140')));
      expect(visible, isNot(contains('1070')));
      expect(visible, isNot(contains('900')));
      expect(visible, isNot(contains('500')));
      expect(visible, isNot(contains('2500')));
      expect(visible, isNot(contains('250-15')));
      expect(visible, isNot(contains('2021')));
      expect(visible, isNot(contains('MAST')));
      expect(visible.join(' '), isNot(contains('HT kg')));
    });

    test('combined S22 line still strips the serial label', () {
      final result = extractor.extract(['25-RC1H S/No 50252M6304 MAST']);
      expect(result.recommended?.value, '50252M6304');
    });

    test('model-labelled text is not recommended as a serial', () {
      final result = extractor.extract([
        'MODEL 25-RC1H',
        'SERIAL NO 50252M6304',
      ]);
      expect(result.recommended?.value, '50252M6304');
      expect(
        result.visibleCandidates.map((c) => c.value),
        isNot(contains('25-RC1H')),
      );
    });

    test('does not expose the raw plate line as a candidate', () {
      final result = extractor.extract(['25-RC1H S/No 50252M6304 MAST']);
      expect(
        result.visibleCandidates.map((c) => c.value),
        isNot(contains('25-RC1H S/No 50252M6304 MAST')),
      );
    });

    test('ambiguous serial-like tokens stay under alternatives', () {
      final result = extractor.extract(['SN-100', 'SN-200']);
      expect(result.recommended, isNull);
      expect(
        result.alternatives.map((c) => c.value).toSet(),
        containsAll(['SN-100', 'SN-200']),
      );
    });

    test('ranking is deterministic for equal-confidence alternatives', () {
      final first = extractor.extract(['AAA111', 'BBB222']);
      final second = extractor.extract(['AAA111', 'BBB222']);
      expect(
        first.alternatives.map((c) => c.value).toList(),
        second.alternatives.map((c) => c.value).toList(),
      );
    });

    test('low-confidence noise does not produce a recommendation', () {
      final result = extractor.extract([
        'WARNING KEEP CLEAR',
        'Tyre pressure 100 PSI',
      ]);
      expect(result.recommended, isNull);
      expect(result.visibleCandidates, isEmpty);
    });
  });
}
