import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/hour_meter_field_extractor.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/hour_meter_parser.dart';

void main() {
  const extractor = HourMeterFieldExtractor();
  const parser = HourMeterParser();

  test('labelled hour meter produces one recommended reading', () {
    final result = extractor.extract(['HOURS 1234', 'TOTAL HOURS 1234']);
    expect(result.recommended?.displayValue, '1234');
    expect(result.recommended?.hours, 1234);
  });

  test('rejects weight, capacity, date and unrelated numbers', () {
    final result = extractor.extract([
      'HT kg 4140 1070',
      'Capacity 2500 kg',
      'Production date 2021',
      'Load centre 500 mm',
    ]);
    expect(result.recommended, isNull);
    expect(result.visibleCandidates, isEmpty);
  });

  test('never invents a missing leading hour digit', () {
    final result = extractor.extract(['HOURS 2345']);
    expect(result.recommended?.displayValue, '2345');
    expect(result.recommended?.hours, 2345);
    expect(parser.parse('12345'), 12345);
  });

  test('incomplete OCR stays editable via manual parse', () {
    expect(parser.parse('2345'), 2345);
    expect(parser.parse('12345'), 12345);
    final result = extractor.extract(['2345']);
    expect(result.recommended?.displayValue, '2345');
  });

  test('ambiguous unlabelled numbers are alternatives only', () {
    final result = extractor.extract(['100', '250']);
    expect(result.recommended, isNull);
    expect(
      result.alternatives.map((c) => c.displayValue).toSet(),
      containsAll(['100', '250']),
    );
  });
}
