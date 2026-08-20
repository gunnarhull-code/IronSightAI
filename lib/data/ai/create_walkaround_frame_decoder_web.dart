import '../../domain/ai/decoded_video_frame.dart';
import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_frame_decoder.dart';

class UnsupportedWalkaroundVideoFrameDecoder
    implements WalkaroundVideoFrameDecoder {
  const UnsupportedWalkaroundVideoFrameDecoder();

  @override
  Future<List<DecodedVideoFrame>> decodeRepresentativeFrames({
    required String videoPath,
    required Duration duration,
    int maxFrames = WalkaroundVideo.maxFrameCount,
  }) async {
    return const [];
  }
}

WalkaroundVideoFrameDecoder createWalkaroundVideoFrameDecoder() {
  return const UnsupportedWalkaroundVideoFrameDecoder();
}
