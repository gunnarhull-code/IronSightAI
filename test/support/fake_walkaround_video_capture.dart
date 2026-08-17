import 'package:ironsight_ai/domain/ai/decoded_video_frame.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video_capture_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

DecodedVideoFrame decodedFrame({
  required String videoPath,
  required List<int> bytes,
  int timeOffsetMs = 0,
  String? path,
}) {
  return DecodedVideoFrame(
    image: CapturedImage(
      bytes: bytes,
      path: path ?? '/tmp/decoded-$timeOffsetMs.jpg',
      mimeType: 'image/jpeg',
    ),
    sourceVideoPath: videoPath,
    timeOffsetMs: timeOffsetMs,
  );
}

class FakeWalkaroundVideoCapture implements WalkaroundVideoCapturePort {
  FakeWalkaroundVideoCapture({
    this.isSupported = true,
    WalkaroundVideo? video,
    this.error,
  }) : video =
           video ??
           WalkaroundVideo(
             localPath: '/tmp/walkaround-local.mp4',
             duration: const Duration(seconds: 12),
             representativeFrames: [
               decodedFrame(
                 videoPath: '/tmp/walkaround-local.mp4',
                 bytes: const [1, 2, 3, 4],
                 timeOffsetMs: 0,
               ),
               decodedFrame(
                 videoPath: '/tmp/walkaround-local.mp4',
                 bytes: const [5, 6, 7, 8],
                 timeOffsetMs: 6000,
               ),
             ],
             mimeType: 'video/mp4',
             byteSize: 4096,
           );

  @override
  bool isSupported;

  WalkaroundVideo video;
  Object? error;
  int recordCallCount = 0;

  @override
  Future<WalkaroundVideo> recordWalkaround() async {
    recordCallCount += 1;
    if (error != null) throw error!;
    return video;
  }
}
