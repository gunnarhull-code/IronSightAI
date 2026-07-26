/// Thrown when a scorecard category value is not one of the fixed V1 categories.
class InvalidScorecardCategoryException implements Exception {
  const InvalidScorecardCategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
