import 'dart:async';

import '../../domain/exceptions/remote_service_unavailable_exception.dart';

/// Returns true when [error] indicates the remote host could not be reached.
///
/// Narrow transport/connectivity failures only. Authorization, authentication,
/// RLS denials, HTTP application responses, malformed payloads, and unexpected
/// programming errors must return false so callers never treat them as offline.
///
/// Uses [TimeoutException] plus well-known transport type names so this helper
/// stays free of `dart:io` (web-safe) and does not import Supabase types.
bool isRemoteConnectivityFailure(Object error) {
  if (error is TimeoutException) return true;
  if (error is RemoteServiceUnavailableException) return true;

  switch (error.runtimeType.toString()) {
    case 'SocketException':
    case 'ClientException':
    case 'HandshakeException':
    case 'TlsException':
    case 'WebSocketException':
      return true;
    default:
      return false;
  }
}

/// Maps a caught remote [error] to [RemoteServiceUnavailableException] when it
/// is a connectivity failure; otherwise returns the original error unchanged.
Object mapRemoteFailure(Object error) {
  if (error is RemoteServiceUnavailableException) return error;
  if (isRemoteConnectivityFailure(error)) {
    return RemoteServiceUnavailableException(
      'Remote service unreachable',
      error,
    );
  }
  return error;
}

/// Rethrows [error] after applying [mapRemoteFailure], preserving [stackTrace].
Never rethrowMappedRemoteFailure(Object error, StackTrace stackTrace) {
  Error.throwWithStackTrace(mapRemoteFailure(error), stackTrace);
}
