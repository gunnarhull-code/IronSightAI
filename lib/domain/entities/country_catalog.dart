/// Fixed V1 list of selectable company countries.
///
/// Values are persisted in the existing `companies.region` column — the
/// database field is intentionally not renamed in this sprint. The UI label
/// is "Country"; [defaultCompanyCountry] is applied when a company is first
/// created. Adding a country here is a deliberate content change.
const String defaultCompanyCountry = 'United States';

/// Supported countries shown in the company Country dropdown.
///
/// Sorted alphabetically by English short name for searchable selection.
const List<String> countryCatalog = [
  'Argentina',
  'Australia',
  'Austria',
  'Belgium',
  'Brazil',
  'Canada',
  'Chile',
  'China',
  'Colombia',
  'Czech Republic',
  'Denmark',
  'Finland',
  'France',
  'Germany',
  'India',
  'Indonesia',
  'Ireland',
  'Italy',
  'Japan',
  'Malaysia',
  'Mexico',
  'Netherlands',
  'New Zealand',
  'Norway',
  'Peru',
  'Philippines',
  'Poland',
  'Portugal',
  'Singapore',
  'South Africa',
  'South Korea',
  'Spain',
  'Sweden',
  'Switzerland',
  'Thailand',
  'Turkey',
  'United Arab Emirates',
  'United Kingdom',
  'United States',
  'Vietnam',
];

/// Dropdown entries for [currentValue], preserving legacy free-text regions
/// that are not in [countryCatalog] so existing company rows still load.
List<String> countryDropdownEntries({String? currentValue}) {
  final current = currentValue?.trim();
  if (current == null || current.isEmpty || countryCatalog.contains(current)) {
    return countryCatalog;
  }

  return [...countryCatalog, current]..sort();
}

/// Whether [value] is an allowed country selection for save.
///
/// Empty values remain allowed (optional field). Non-empty values must be in
/// the supported catalog or match the company's existing legacy region value.
bool isAllowedCompanyCountry(String? value, {String? existingRegion}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return true;
  return countryDropdownEntries(currentValue: existingRegion).contains(trimmed);
}
