import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_outcome.dart';
import 'package:ironsight_ai/domain/ai/walkaround_recording_pipeline.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';

import '../support/fake_walkaround_video_capture.dart';
import '../support/fake_walkaround_video_frame_decoder.dart';

void main() {
  const recordedPath = '/cache/walkaround.mp4';

  test(
    'successful pipeline returns frames decoded from the recorded MP4',
    () async {
      final decoder = FakeWalkaroundVideoFrameDecoder(
        frames: [
          decodedFrame(
            videoPath: recordedPath,
            bytes: const [1, 2, 3, 4],
            timeOffsetMs: 0,
          ),
          decodedFrame(
            videoPath: recordedPath,
            bytes: const [5, 6, 7, 8],
            timeOffsetMs: 800,
          ),
        ],
      );
      final outcome = await WalkaroundRecordingPipeline.complete(
        decoder: decoder,
        recordedPath: recordedPath,
        recordedDuration: const Duration(seconds: 2),
        fileExists: true,
        byteSize: 2048,
      );
      expect(outcome.status, WalkaroundCaptureStatus.success);
      expect(decoder.lastVideoPath, recordedPath);
      expect(outcome.video, isA<WalkaroundVideo>());
      expect(outcome.video!.localPath, recordedPath);
      expect(outcome.video!.framesDecodedFromLocalVideo, isTrue);
      expect(outcome.video!.representativeFrames, hasLength(2));
      expect(
        outcome.video!.representativeFrames.every(
          (frame) => frame.originatesFrom(recordedPath),
        ),
        isTrue,
      );
    },
  );

  test('missing file is a decode failure, not a silent cancel', () async {
    final outcome = await WalkaroundRecordingPipeline.complete(
      decoder: FakeWalkaroundVideoFrameDecoder(),
      recordedPath: recordedPath,
      recordedDuration: const Duration(seconds: 2),
      fileExists: false,
      byteSize: 0,
    );
    expect(outcome.status, WalkaroundCaptureStatus.failed);
    expect(outcome.failure!.kind, AiMediaReviewFailureKind.videoFramesMissing);
  });

  test('decoder throwing is a failed outcome with no video', () async {
    final decoder = FakeWalkaroundVideoFrameDecoder(
      error: Exception('native_extract_failed'),
    );
    final outcome = await WalkaroundRecordingPipeline.complete(
      decoder: decoder,
      recordedPath: recordedPath,
      recordedDuration: const Duration(seconds: 2),
      fileExists: true,
      byteSize: 4096,
    );
    expect(outcome.status, WalkaroundCaptureStatus.failed);
    expect(outcome.video, isNull);
    expect(outcome.failure!.kind, AiMediaReviewFailureKind.videoFramesMissing);
  });

  test('stills from another path cannot be used as video frames', () async {
    final decoder = FakeWalkaroundVideoFrameDecoder(
      frames: [
        decodedFrame(
          videoPath: '/cache/unrelated-still.jpg',
          bytes: const [9, 9, 9],
        ),
      ],
    );
    final outcome = await WalkaroundRecordingPipeline.complete(
      decoder: decoder,
      recordedPath: recordedPath,
      recordedDuration: const Duration(seconds: 2),
      fileExists: true,
      byteSize: 4096,
    );
    expect(outcome.status, WalkaroundCaptureStatus.failed);
    expect(outcome.failure!.kind, AiMediaReviewFailureKind.videoFramesMissing);
  });
}
