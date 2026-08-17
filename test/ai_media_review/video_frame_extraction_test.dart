import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/video_frame_extraction.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

CapturedImage _frame(int n) => CapturedImage(
  bytes: List<int>.filled(4, n),
  path: '/tmp/local-frame-$n.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  test('rejects walkaround video longer than 30 seconds', () {
    final video = WalkaroundVideo(
      localPath: '/tmp/walkaround-local.mp4',
      duration: const Duration(seconds: 31),
      representativeFrames: [_frame(1)],
      mimeType: 'video/mp4',
    );
    expect(video.exceedsMaxDuration, isTrue);
    expect(
      () => VideoFrameExtraction.extractBoundedFrames(video),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.videoTooLong,
        ),
      ),
    );
  });

  test('accepts a 30 second video and bounds frames to six', () {
    final video = WalkaroundVideo(
      localPath: '/tmp/walkaround-local.mp4',
      duration: const Duration(seconds: 30),
      representativeFrames: [for (var i = 0; i < 12; i++) _frame(i)],
    );
    final frames = VideoFrameExtraction.extractBoundedFrames(video);
    expect(frames, hasLength(VideoFrameExtraction.maxFrameCount));
    expect(frames.first.bytes, _frame(0).bytes);
    expect(frames.last.bytes, _frame(11).bytes);
  });

  test('requires at least one representative frame', () {
    final video = WalkaroundVideo(
      localPath: '/tmp/walkaround-local.mp4',
      duration: const Duration(seconds: 8),
      representativeFrames: const [],
    );
    expect(
      () => VideoFrameExtraction.extractBoundedFrames(video),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.videoFramesMissing,
        ),
      ),
    );
  });
}
