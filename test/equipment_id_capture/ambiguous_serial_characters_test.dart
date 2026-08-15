import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/ambiguous_serial_characters.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/hour_meter_parser.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/serial_field_extractor.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/serial_normalizer.dart';

void main() {
  group('AmbiguousSerialCharacters', () {
    test('flags common OCR look-alikes without rewriting them', () {
      expect(
        AmbiguousSerialCharacters.hasAmbiguousCharacters('50252M6304'),
        isTrue,
      );
      expect(
        AmbiguousSerialCharacters.hasAmbiguousCharacters('SN-O012'),
        isTrue,
      );
      expect(AmbiguousSerialCharacters.hasAmbiguousCharacters('ACD'), isFalse);
      expect(
        AmbiguousSerialCharacters.hasAmbiguousCharacters('CAT-WXYZ'),
        isFalse,
      );

      expect(
        AmbiguousSerialCharacters.preserveAsRead('SN-O012'),
        'SN-O012',
        reason: 'must never silently substitute O/0 or similar',
      );
      expect(
        AmbiguousSerialCharacters.reviewLabel,
        'Check ambiguous characters.',
      );
    });

    test('serial extractor preserves O that OCR may have misread as zero', () {
      const extractor = SerialFieldExtractor();
      final result = extractor.extract(['S/No 5O252M63O4']);
      expect(result.recommended?.value, '5O252M63O4');
      expect(result.recommended?.hasAmbiguousCharacters, isTrue);
      expect(result.recommended?.value.contains('0'), isFalse);
    });

    test('normalizer never substitutes look-alike characters', () {
      const normalizer = SerialNormalizer();
      expect(normalizer.normalizeForStorage('S/No 5O852'), '5O852');
      expect(normalizer.normalize('O0I1S5B8'), 'O0I1S5B8');
    });

    test('hour parser never converts letters into digits', () {
      const parser = HourMeterParser();
      expect(parser.parse('O123'), isNull);
      expect(parser.parse('I234'), isNull);
      expect(parser.parse('12S4'), isNull);
      expect(parser.parse('1234'), 1234);
      expect(
        parser
            .candidatesFromRawTexts(['HOURS O123'])
            .map((c) => c.displayValue),
        isEmpty,
      );
    });
  });
}
