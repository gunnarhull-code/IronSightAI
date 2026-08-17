import 'decoded_video_frame.dart';
import 'walkaround_video.dart';

/// Decodes a bounded set of representative stills from a local MP4.
///
/// Implementations must read the recorded video file. Capturing separate
/// camera stills before or after recording does not satisfy this contract.
abstract class WalkaroundVideoFrameDecoder {
  /// Extracts up to [WalkaroundVideo.maxFrameCount] JPEG stills from [videoPath].
  Future<List<DecodedVideoFrame>> decodeRepresentativeFrames({
    required String videoPath,
    required Duration duration,
    int maxFrames = WalkaroundVideo.maxFrameCount,
  });
}
