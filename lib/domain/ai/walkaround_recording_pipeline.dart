import 'ai_media_review_failure.dart';
import 'video_frame_extraction.dart';
import 'walkaround_capture_outcome.dart';
import 'walkaround_video.dart';
import 'walkaround_video_frame_decoder.dart';

/// Completes a recorded local MP4 into a capture outcome.
///
/// Never uploads the original video. Rejects frames that did not originate
/// from [recordedPath].
abstract final class WalkaroundRecordingPipeline {
  static Future<WalkaroundCaptureOutcome> complete({
    required WalkaroundVideoFrameDecoder decoder,
    required String recordedPath,
    required Duration recordedDuration,
    required bool fileExists,
    required int byteSize,
  }) async {
    if (!fileExists || byteSize <= 0) {
      return WalkaroundCaptureOutcome.failed(
        AiMediaReviewFailure.videoFramesMissing(),
      );
    }
    if (recordedDuration > WalkaroundVideo.maxDuration) {
      return WalkaroundCaptureOutcome.failed(
        AiMediaReviewFailure.videoTooLong(),
      );
    }

    try {
      final frames = await VideoFrameExtraction.decodeAndBound(
        decoder: decoder,
        videoPath: recordedPath,
        duration: recordedDuration,
      );
      if (frames.isEmpty) {
        return WalkaroundCaptureOutcome.failed(
          AiMediaReviewFailure.videoFramesMissing(),
        );
      }
      return WalkaroundCaptureOutcome.success(
        WalkaroundVideo(
          localPath: recordedPath,
          duration: recordedDuration,
          representativeFrames: frames,
          byteSize: byteSize,
        ),
      );
    } on AiMediaReviewException catch (error) {
      return WalkaroundCaptureOutcome.failed(error.failure);
    } catch (_) {
      return WalkaroundCaptureOutcome.failed(
        AiMediaReviewFailure.videoFramesMissing(),
      );
    }
  }
}
