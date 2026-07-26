import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/country_catalog.dart';

void main() {
  test('United States is the default and is in the catalog', () {
    expect(defaultCompanyCountry, 'United States');
    expect(countryCatalog, contains(defaultCompanyCountry));
  });

  test('country catalog is alphabetically sorted and unique', () {
    final sorted = [...countryCatalog]..sort();
    expect(countryCatalog, sorted);
    expect(countryCatalog.toSet().length, countryCatalog.length);
  });

  test('legacy region values remain available in dropdown entries', () {
    final entries = countryDropdownEntries(currentValue: 'Midwest');

    expect(entries, contains('Midwest'));
    expect(entries, contains('United States'));
    expect(entries, containsAll(countryCatalog));
  });

  test('isAllowedCompanyCountry accepts empty, catalog, and legacy values', () {
    expect(isAllowedCompanyCountry(null), isTrue);
    expect(isAllowedCompanyCountry(''), isTrue);
    expect(isAllowedCompanyCountry('Canada'), isTrue);
    expect(
      isAllowedCompanyCountry('Midwest', existingRegion: 'Midwest'),
      isTrue,
    );
    expect(isAllowedCompanyCountry('Not A Country'), isFalse);
  });
}
