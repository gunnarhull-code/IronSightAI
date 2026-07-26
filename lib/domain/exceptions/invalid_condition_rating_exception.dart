/// Thrown when a condition rating value is not one of the allowed V1 values.
class InvalidConditionRatingException implements Exception {
  const InvalidConditionRatingException(this.message);

  final String message;

  @override
  String toString() => message;
}
