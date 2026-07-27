/// Fixed Quick Condition Scorecard categories for V1.
///
/// Order matches the product scorecard. Category identities are stable storage
/// keys so detailed checklist expansion can attach without UI concerns.
enum ScorecardCategory {
  engine,
  hydraulics,
  undercarriage,
  cab,
  structure,
  attachments,
  cosmetic;

  /// Stable persistence / sync key.
  String get storageValue => name;

  /// Human-readable label for snapshots and future report rendering.
  String get displayLabel => switch (this) {
    ScorecardCategory.engine => 'Engine',
    ScorecardCategory.hydraulics => 'Hydraulics',
    ScorecardCategory.undercarriage => 'Undercarriage',
    ScorecardCategory.cab => 'Cab',
    ScorecardCategory.structure => 'Structure',
    ScorecardCategory.attachments => 'Attachments',
    ScorecardCategory.cosmetic => 'Cosmetic',
  };

  static const List<ScorecardCategory> scorecardOrder =
      ScorecardCategory.values;

  static ScorecardCategory fromStorage(String value) {
    for (final category in ScorecardCategory.values) {
      if (category.storageValue == value) return category;
    }
    throw FormatException('Invalid scorecard category: $value');
  }
}
