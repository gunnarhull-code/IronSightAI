import 'package:ironsight_ai/domain/ai/decoded_video_frame.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video_frame_decoder.dart';

class FakeWalkaroundVideoFrameDecoder implements WalkaroundVideoFrameDecoder {
  FakeWalkaroundVideoFrameDecoder({
    this.frames = const [],
    this.error,
    this.lastVideoPath,
  });

  List<DecodedVideoFrame> frames;
  Object? error;
  String? lastVideoPath;
  int callCount = 0;

  @override
  Future<List<DecodedVideoFrame>> decodeRepresentativeFrames({
    required String videoPath,
    required Duration duration,
    int maxFrames = WalkaroundVideo.maxFrameCount,
  }) async {
    callCount += 1;
    lastVideoPath = videoPath;
    if (error != null) throw error!;
    return List<DecodedVideoFrame>.unmodifiable(
      frames.take(maxFrames).toList(),
    );
  }
}
