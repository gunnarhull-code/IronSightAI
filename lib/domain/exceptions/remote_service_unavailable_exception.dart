/// Thrown when a remote service call cannot be completed because the service
/// is unreachable (no connectivity / transport failure).
///
/// This is intentionally distinct from authorization, RLS, authentication,
/// malformed-response, and server application errors. Callers may degrade to
/// safe local behavior only for this failure kind.
class RemoteServiceUnavailableException implements Exception {
  const RemoteServiceUnavailableException([this.message, this.cause]);

  final String? message;
  final Object? cause;

  @override
  String toString() {
    final detail = message?.trim();
    if (detail != null && detail.isNotEmpty) {
      return 'RemoteServiceUnavailableException: $detail';
    }
    return 'RemoteServiceUnavailableException';
  }
}
