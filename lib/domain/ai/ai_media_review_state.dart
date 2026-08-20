import 'ai_media_review_failure.dart';
import 'ai_media_review_result.dart';

enum AiMediaReviewPhase {
  ready,
  uploading,
  results,
  offline,
  providerFailure,
  cancelled,
}

/// Snapshot of optional AI media review. Session-local except applied values.
class AiMediaReviewViewState {
  const AiMediaReviewViewState({
    required this.phase,
    this.photoCount = 0,
    this.hasWalkaroundVideo = false,
    this.videoFrameCount = 0,
    this.videoDuration,
    this.result,
    this.failure,
    this.statusAnnouncement,
  });

  final AiMediaReviewPhase phase;
  final int photoCount;
  final bool hasWalkaroundVideo;
  final int videoFrameCount;
  final Duration? videoDuration;
  final AiMediaReviewResult? result;
  final AiMediaReviewFailure? failure;
  final String? statusAnnouncement;

  bool get canAnalyze =>
      (photoCount > 0 || (hasWalkaroundVideo && videoFrameCount > 0)) &&
      !isBusy &&
      (phase == AiMediaReviewPhase.ready ||
          phase == AiMediaReviewPhase.offline ||
          phase == AiMediaReviewPhase.providerFailure ||
          phase == AiMediaReviewPhase.cancelled ||
          phase == AiMediaReviewPhase.results);

  bool get isBusy => phase == AiMediaReviewPhase.uploading;

  bool get hasResults => phase == AiMediaReviewPhase.results && result != null;
}
