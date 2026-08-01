import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/hour_meter_parser.dart';

void main() {
  const parser = HourMeterParser();

  group('HourMeterParser.parse', () {
    test('parses plain integers', () {
      expect(parser.parse('1234'), 1234);
      expect(parser.parse('0'), 0);
    });

    test('parses decimals with dot or comma', () {
      expect(parser.parse('1234.5'), 1234.5);
      expect(parser.parse('1234,5'), 1234.5);
    });

    test('parses thousands separators conservatively', () {
      expect(parser.parse('1,234'), 1234);
      expect(parser.parse('1,234.5'), 1234.5);
    });

    test('rejects negative hours', () {
      expect(parser.parse('-12'), isNull);
      expect(parser.parse('-0.5'), isNull);
    });

    test('rejects invalid and ambiguous values', () {
      expect(parser.parse(''), isNull);
      expect(parser.parse('abc'), isNull);
      expect(parser.parse('12a3'), isNull);
      expect(parser.parse('O123'), isNull);
      expect(parser.parse('--'), isNull);
    });

    test('does not invent digits for partial junk', () {
      expect(parser.parse('.'), isNull);
      expect(parser.parse(','), isNull);
      expect(parser.parse('1..2'), isNull);
    });
  });

  group('HourMeterParser.candidatesFromRawTexts', () {
    test('extracts multiple hour candidates', () {
      final candidates = parser.candidatesFromRawTexts([
        'HOURS 1234',
        'TOTAL 56.5',
        'SN CAT320',
      ]);
      expect(candidates.map((c) => c.displayValue).toList(), ['1234', '56.5']);
      expect(candidates.map((c) => c.hours).toList(), [1234, 56.5]);
    });

    test('rejects negative hour candidates', () {
      final candidates = parser.candidatesFromRawTexts(['-100', 'hours -12']);
      expect(candidates, isEmpty);
    });

    test('deduplicates identical hour values', () {
      final candidates = parser.candidatesFromRawTexts(['100', '100.0', '100']);
      expect(candidates.map((c) => c.displayValue).toList(), ['100']);
    });
  });
}
