import 'dart:async';

import 'walkaround_capture_outcome.dart';

/// Delivers a capture outcome even if the recording route is popped without
/// a Navigator result (Android back, unmount during decode).
class WalkaroundCaptureSession {
  WalkaroundCaptureSession();

  final Completer<WalkaroundCaptureOutcome> _completer =
      Completer<WalkaroundCaptureOutcome>();

  bool get isCompleted => _completer.isCompleted;

  void report(WalkaroundCaptureOutcome outcome) {
    if (!_completer.isCompleted) {
      _completer.complete(outcome);
    }
  }

  /// After the capture route finishes, return the reported outcome or cancel.
  Future<WalkaroundCaptureOutcome> finalizeAfterRoute() {
    if (!_completer.isCompleted) {
      _completer.complete(WalkaroundCaptureOutcome.cancelled());
    }
    return _completer.future;
  }
}
