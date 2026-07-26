/// Thrown when an inspection mutation violates allowed local lifecycle rules.
class InvalidInspectionLifecycleException implements Exception {
  const InvalidInspectionLifecycleException(this.message);

  final String message;

  @override
  String toString() => message;
}
