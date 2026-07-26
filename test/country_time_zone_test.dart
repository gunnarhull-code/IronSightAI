import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/country_time_zone.dart';

void main() {
  test('United States uses Eastern standard offset', () {
    final zone = timeZoneForCompanyCountry('United States');
    expect(zone.utcOffsetMinutes, -300);
    expect(zone.label, 'UTC-5');
  });

  test('unknown or empty country falls back to UTC', () {
    expect(timeZoneForCompanyCountry(null).label, 'UTC');
    expect(timeZoneForCompanyCountry('').label, 'UTC');
    expect(timeZoneForCompanyCountry('Midwest').label, 'UTC');
  });

  test('formatCompanyLocalTimestamp shifts by country offset', () {
    final timestamp = DateTime.utc(2026, 1, 2, 3, 4);

    expect(
      formatCompanyLocalTimestamp(
        timestamp,
        companyCountry: 'United States',
      ),
      '2026-01-01 22:04 UTC-5',
    );
    expect(
      formatCompanyLocalTimestamp(timestamp, companyCountry: 'Japan'),
      '2026-01-02 12:04 UTC+9',
    );
    expect(
      formatCompanyLocalTimestamp(timestamp, companyCountry: null),
      '2026-01-02 03:04 UTC',
    );
  });
}
