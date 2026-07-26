/// Primary UTC offset and label for a company country.
///
/// Multi-zone countries use one representative business timezone (capital /
/// primary commercial center). Offsets are standard (non-DST) minutes east of
/// UTC so timestamps can be localized without a timezone database dependency.
class CountryTimeZone {
  const CountryTimeZone({
    required this.utcOffsetMinutes,
    required this.label,
  });

  /// Minutes east of UTC (negative for west).
  final int utcOffsetMinutes;

  /// Short zone label shown next to formatted timestamps (e.g. `UTC-5`).
  final String label;
}

/// Fallback when the company has no country or an unrecognized legacy region.
const CountryTimeZone utcTimeZone = CountryTimeZone(
  utcOffsetMinutes: 0,
  label: 'UTC',
);

/// Representative time zones for [countryCatalog] entries.
const Map<String, CountryTimeZone> countryTimeZones = {
  'Argentina': CountryTimeZone(utcOffsetMinutes: -180, label: 'UTC-3'),
  'Australia': CountryTimeZone(utcOffsetMinutes: 600, label: 'UTC+10'),
  'Austria': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Belgium': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Brazil': CountryTimeZone(utcOffsetMinutes: -180, label: 'UTC-3'),
  'Canada': CountryTimeZone(utcOffsetMinutes: -300, label: 'UTC-5'),
  'Chile': CountryTimeZone(utcOffsetMinutes: -240, label: 'UTC-4'),
  'China': CountryTimeZone(utcOffsetMinutes: 480, label: 'UTC+8'),
  'Colombia': CountryTimeZone(utcOffsetMinutes: -300, label: 'UTC-5'),
  'Czech Republic': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Denmark': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Finland': CountryTimeZone(utcOffsetMinutes: 120, label: 'UTC+2'),
  'France': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Germany': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'India': CountryTimeZone(utcOffsetMinutes: 330, label: 'UTC+5:30'),
  'Indonesia': CountryTimeZone(utcOffsetMinutes: 420, label: 'UTC+7'),
  'Ireland': CountryTimeZone(utcOffsetMinutes: 0, label: 'UTC'),
  'Italy': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Japan': CountryTimeZone(utcOffsetMinutes: 540, label: 'UTC+9'),
  'Malaysia': CountryTimeZone(utcOffsetMinutes: 480, label: 'UTC+8'),
  'Mexico': CountryTimeZone(utcOffsetMinutes: -360, label: 'UTC-6'),
  'Netherlands': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'New Zealand': CountryTimeZone(utcOffsetMinutes: 720, label: 'UTC+12'),
  'Norway': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Peru': CountryTimeZone(utcOffsetMinutes: -300, label: 'UTC-5'),
  'Philippines': CountryTimeZone(utcOffsetMinutes: 480, label: 'UTC+8'),
  'Poland': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Portugal': CountryTimeZone(utcOffsetMinutes: 0, label: 'UTC'),
  'Singapore': CountryTimeZone(utcOffsetMinutes: 480, label: 'UTC+8'),
  'South Africa': CountryTimeZone(utcOffsetMinutes: 120, label: 'UTC+2'),
  'South Korea': CountryTimeZone(utcOffsetMinutes: 540, label: 'UTC+9'),
  'Spain': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Sweden': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Switzerland': CountryTimeZone(utcOffsetMinutes: 60, label: 'UTC+1'),
  'Thailand': CountryTimeZone(utcOffsetMinutes: 420, label: 'UTC+7'),
  'Turkey': CountryTimeZone(utcOffsetMinutes: 180, label: 'UTC+3'),
  'United Arab Emirates': CountryTimeZone(utcOffsetMinutes: 240, label: 'UTC+4'),
  'United Kingdom': CountryTimeZone(utcOffsetMinutes: 0, label: 'UTC'),
  'United States': CountryTimeZone(utcOffsetMinutes: -300, label: 'UTC-5'),
  'Vietnam': CountryTimeZone(utcOffsetMinutes: 420, label: 'UTC+7'),
};

/// Resolves the display time zone for a stored company country / region value.
CountryTimeZone timeZoneForCompanyCountry(String? country) {
  final trimmed = country?.trim();
  if (trimmed == null || trimmed.isEmpty) return utcTimeZone;
  return countryTimeZones[trimmed] ?? utcTimeZone;
}

/// Formats [timestamp] in the representative zone for [companyCountry].
///
/// Instant is always taken as UTC; the company country only affects display.
String formatCompanyLocalTimestamp(
  DateTime timestamp, {
  String? companyCountry,
}) {
  final zone = timeZoneForCompanyCountry(companyCountry);
  final local = timestamp.toUtc().add(
    Duration(minutes: zone.utcOffsetMinutes),
  );
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)} ${zone.label}';
}
