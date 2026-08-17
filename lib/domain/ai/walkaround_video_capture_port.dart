import 'walkaround_video.dart';

/// Records one optional walkaround video (max 30 seconds) on device.
///
/// Implementations must keep the original file local and return representative
/// still frames for analysis. Presentation code must not import `camera`.
abstract class WalkaroundVideoCapturePort {
  bool get isSupported;

  Future<WalkaroundVideo> recordWalkaround();
}

class UnsupportedWalkaroundVideoCapture implements WalkaroundVideoCapturePort {
  const UnsupportedWalkaroundVideoCapture();

  @override
  bool get isSupported => false;

  @override
  Future<WalkaroundVideo> recordWalkaround() {
    throw StateError(
      'Walkaround video capture is not supported on this device.',
    );
  }
}
