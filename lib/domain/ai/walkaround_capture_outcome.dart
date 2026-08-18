import 'ai_media_review_failure.dart';
import 'walkaround_video.dart';

/// Result of one walkaround recording attempt.
///
/// Cancelled or failed attempts must not clear a previously accepted video.
enum WalkaroundCaptureStatus { success, cancelled, failed }

class WalkaroundCaptureOutcome {
  const WalkaroundCaptureOutcome._({
    required this.status,
    this.video,
    this.failure,
  });

  factory WalkaroundCaptureOutcome.success(WalkaroundVideo video) {
    return WalkaroundCaptureOutcome._(
      status: WalkaroundCaptureStatus.success,
      video: video,
    );
  }

  factory WalkaroundCaptureOutcome.cancelled() {
    return const WalkaroundCaptureOutcome._(
      status: WalkaroundCaptureStatus.cancelled,
    );
  }

  factory WalkaroundCaptureOutcome.failed(AiMediaReviewFailure failure) {
    return WalkaroundCaptureOutcome._(
      status: WalkaroundCaptureStatus.failed,
      failure: failure,
    );
  }

  final WalkaroundCaptureStatus status;
  final WalkaroundVideo? video;
  final AiMediaReviewFailure? failure;

  bool get isSuccess =>
      status == WalkaroundCaptureStatus.success && video != null;
}
