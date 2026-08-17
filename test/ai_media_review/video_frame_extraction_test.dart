import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/decoded_video_frame.dart';
import 'package:ironsight_ai/domain/ai/video_frame_extraction.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

const _videoPath = '/tmp/walkaround-local.mp4';

DecodedVideoFrame _frame(int n, {String videoPath = _videoPath}) {
  return DecodedVideoFrame(
    image: CapturedImage(
      bytes: List<int>.filled(4, n),
      path: '/tmp/local-frame-$n.jpg',
      mimeType: 'image/jpeg',
    ),
    sourceVideoPath: videoPath,
    timeOffsetMs: n * 1000,
  );
}

void main() {
  test('rejects walkaround video longer than 30 seconds', () {
    final video = WalkaroundVideo(
      localPath: _videoPath,
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
      localPath: _videoPath,
      duration: const Duration(seconds: 30),
      representativeFrames: [for (var i = 0; i < 12; i++) _frame(i)],
    );
    final frames = VideoFrameExtraction.extractBoundedFrames(video);
    expect(frames, hasLength(VideoFrameExtraction.maxFrameCount));
    expect(frames.first.image.bytes, _frame(0).image.bytes);
    expect(frames.last.image.bytes, _frame(11).image.bytes);
    expect(frames.every((frame) => frame.originatesFrom(_videoPath)), isTrue);
  });

  test('requires at least one representative frame', () {
    final video = WalkaroundVideo(
      localPath: _videoPath,
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

  test('rejects frames that were not decoded from the recorded MP4', () {
    final video = WalkaroundVideo(
      localPath: _videoPath,
      duration: const Duration(seconds: 8),
      representativeFrames: [_frame(1, videoPath: '/tmp/unrelated-still.jpg')],
    );
    expect(video.framesDecodedFromLocalVideo, isFalse);
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

  test('sampleOffsetsMs spreads across the recording', () {
    expect(
      VideoFrameExtraction.sampleOffsetsMs(
        duration: const Duration(seconds: 10),
        maxFrames: 1,
      ),
      [0],
    );
    expect(
      VideoFrameExtraction.sampleOffsetsMs(
        duration: const Duration(seconds: 10),
        maxFrames: 3,
      ),
      [0, 4975, 9950],
    );
    expect(
      VideoFrameExtraction.sampleOffsetsMs(
        duration: const Duration(seconds: 3),
        maxFrames: 3,
      ),
      [0, 1475, 2950],
    );
  });
}
