import 'walkaround_capture_outcome.dart';

/// Records one optional walkaround video (max 30 seconds) on device.
///
/// Implementations must keep the original file local and return representative
/// still frames for analysis. Presentation code must not import `camera`.
abstract class WalkaroundVideoCapturePort {
  bool get isSupported;

  /// Records a walkaround. Cancelled/failed results must not imply that a
  /// previously accepted video was cleared — callers keep prior state.
  Future<WalkaroundCaptureOutcome> recordWalkaround();
}

class UnsupportedWalkaroundVideoCapture implements WalkaroundVideoCapturePort {
  const UnsupportedWalkaroundVideoCapture();

  @override
  bool get isSupported => false;

  @override
  Future<WalkaroundCaptureOutcome> recordWalkaround() async {
    return WalkaroundCaptureOutcome.cancelled();
  }
}
