import '../equipment_id_capture/captured_image.dart';
import 'ai_media_review_failure.dart';
import 'decoded_video_frame.dart';
import 'walkaround_video.dart';
import 'walkaround_video_frame_decoder.dart';

/// Bounds and validates representative frames decoded from a walkaround MP4.
///
/// Never returns original video bytes. Rejects frames that were not decoded
/// from the recorded video path.
abstract final class VideoFrameExtraction {
  static const int maxFrameCount = WalkaroundVideo.maxFrameCount;
  static const Duration maxDuration = WalkaroundVideo.maxDuration;

  /// Even sample offsets across [duration], inclusive of start and a safe
  /// near-end timestamp when more than one frame is requested.
  ///
  /// The final offset stays slightly before EOF so decoders (ffmpeg /
  /// platform thumbnail APIs) can still produce a frame.
  static List<int> sampleOffsetsMs({
    required Duration duration,
    int maxFrames = maxFrameCount,
  }) {
    final capped = maxFrames.clamp(1, maxFrameCount);
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return const [0];
    if (capped == 1) return const [0];
    // Leave a small lead-in before EOF; seeking to duration-1ms often fails.
    final endPadMs = totalMs >= 100 ? 50 : (totalMs > 1 ? 1 : 0);
    final last = totalMs - endPadMs;
    return [
      for (var i = 0; i < capped; i++) ((last * i) / (capped - 1)).round(),
    ];
  }

  static List<DecodedVideoFrame> boundFrames(
    List<DecodedVideoFrame> frames, {
    required String expectedVideoPath,
  }) {
    final usable = <DecodedVideoFrame>[];
    for (final frame in frames) {
      if (frame.image.isEmpty) continue;
      if (!frame.originatesFrom(expectedVideoPath)) continue;
      usable.add(frame);
    }
    if (usable.length <= maxFrameCount) {
      return List<DecodedVideoFrame>.unmodifiable(usable);
    }
    if (maxFrameCount == 1) {
      return List<DecodedVideoFrame>.unmodifiable([usable.first]);
    }
    final sampled = <DecodedVideoFrame>[];
    for (var i = 0; i < maxFrameCount; i++) {
      final index = ((usable.length - 1) * i / (maxFrameCount - 1)).round();
      sampled.add(usable[index]);
    }
    return List<DecodedVideoFrame>.unmodifiable(sampled);
  }

  /// Validates duration/provenance and returns bounded frames.
  static List<DecodedVideoFrame> extractBoundedFrames(WalkaroundVideo video) {
    if (video.exceedsMaxDuration) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoTooLong());
    }
    if (!video.framesDecodedFromLocalVideo) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoFramesMissing());
    }
    final frames = boundFrames(
      video.representativeFrames,
      expectedVideoPath: video.localPath,
    );
    if (frames.isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoFramesMissing());
    }
    return frames;
  }

  /// Decodes up to [maxFrameCount] frames from [videoPath], then bounds them.
  static Future<List<DecodedVideoFrame>> decodeAndBound({
    required WalkaroundVideoFrameDecoder decoder,
    required String videoPath,
    required Duration duration,
    int maxFrames = maxFrameCount,
  }) async {
    if (duration > maxDuration) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoTooLong());
    }
    final decoded = await decoder.decodeRepresentativeFrames(
      videoPath: videoPath,
      duration: duration,
      maxFrames: maxFrames,
    );
    final bounded = boundFrames(decoded, expectedVideoPath: videoPath);
    if (bounded.isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.videoFramesMissing());
    }
    return bounded;
  }

  /// Convenience for tests that still need [CapturedImage] lists.
  static List<CapturedImage> toImages(List<DecodedVideoFrame> frames) {
    return frames.map((frame) => frame.image).toList(growable: false);
  }
}
