import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video_capture_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

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
             representativeFrames: const [
               CapturedImage(
                 bytes: [1, 2, 3, 4],
                 path: '/tmp/frame-0.jpg',
                 mimeType: 'image/jpeg',
               ),
               CapturedImage(
                 bytes: [5, 6, 7, 8],
                 path: '/tmp/frame-1.jpg',
                 mimeType: 'image/jpeg',
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
