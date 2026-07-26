/// Condition rating used by the Quick Condition Scorecard and detailed items.
///
/// Values are fixed for V1. Unknown wire values must be rejected by parsers —
/// never silently coerced.
enum ConditionRating {
  good,
  fair,
  poor,
  notAssessed;

  String get storageValue => switch (this) {
    ConditionRating.good => 'good',
    ConditionRating.fair => 'fair',
    ConditionRating.poor => 'poor',
    ConditionRating.notAssessed => 'not_assessed',
  };

  static ConditionRating fromStorage(String value) {
    return switch (value) {
      'good' => ConditionRating.good,
      'fair' => ConditionRating.fair,
      'poor' => ConditionRating.poor,
      'not_assessed' => ConditionRating.notAssessed,
      _ => throw FormatException('Invalid condition rating: $value'),
    };
  }
}
