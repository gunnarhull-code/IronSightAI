import 'package:ironsight_ai/domain/ai/decoded_video_frame.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_outcome.dart';
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

WalkaroundVideo sampleWalkaroundVideo({
  String localPath = '/tmp/walkaround-local.mp4',
  Duration duration = const Duration(seconds: 12),
  int frameCount = 2,
}) {
  return WalkaroundVideo(
    localPath: localPath,
    duration: duration,
    representativeFrames: [
      for (var i = 0; i < frameCount; i++)
        decodedFrame(
          videoPath: localPath,
          bytes: List<int>.filled(4, i + 1),
          timeOffsetMs: i * 1000,
        ),
    ],
    mimeType: 'video/mp4',
    byteSize: 4096,
  );
}

class FakeWalkaroundVideoCapture implements WalkaroundVideoCapturePort {
  FakeWalkaroundVideoCapture({
    this.isSupported = true,
    WalkaroundVideo? video,
    this.error,
    this.outcome,
    List<WalkaroundCaptureOutcome>? queued,
  }) : video = video ?? sampleWalkaroundVideo(),
       queued = queued ?? <WalkaroundCaptureOutcome>[];

  @override
  bool isSupported;

  WalkaroundVideo video;
  Object? error;
  WalkaroundCaptureOutcome? outcome;
  final List<WalkaroundCaptureOutcome> queued;
  int recordCallCount = 0;

  @override
  Future<WalkaroundCaptureOutcome> recordWalkaround() async {
    recordCallCount += 1;
    if (error != null) throw error!;
    if (queued.isNotEmpty) {
      return queued.removeAt(0);
    }
    return outcome ?? WalkaroundCaptureOutcome.success(video);
  }
}
