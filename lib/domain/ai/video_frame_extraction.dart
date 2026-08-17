import '../equipment_id_capture/captured_image.dart';
import 'ai_media_review_failure.dart';
import 'walkaround_video.dart';

/// Bounds and validates representative frames for frame-based video review.
///
/// Does not decode video and never returns original video bytes.
abstract final class VideoFrameExtraction {
  static const int maxFrameCount = WalkaroundVideo.maxFrameCount;
  static const Duration maxDuration = WalkaroundVideo.maxDuration;

  /// Returns at most [maxFrameCount] non-empty frames, evenly sampled when
  /// more frames were captured than allowed.
  static List<CapturedImage> boundFrames(List<CapturedImage> frames) {
    final usable = frames.where((frame) => !frame.isEmpty).toList();
    if (usable.length <= maxFrameCount) {
      return List<CapturedImage>.unmodifiable(usable);
    }
    if (maxFrameCount == 1) {
      return List<CapturedImage>.unmodifiable([usable.first]);
    }
    final sampled = <CapturedImage>[];
    for (var i = 0; i < maxFrameCount; i++) {
      final index = ((usable.length - 1) * i / (maxFrameCount - 1)).round();
      sampled.add(usable[index]);
    }
    return List<CapturedImage>.unmodifiable(sampled);
  }

  /// Validates duration and produces bounded frames, or throws a typed failure.
  static List<CapturedImage> extractBoundedFrames(WalkaroundVideo video) {
    if (video.exceedsMaxDuration) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoTooLong());
    }
    final frames = boundFrames(video.representativeFrames);
    if (frames.isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoFramesMissing());
    }
    return frames;
  }
}
