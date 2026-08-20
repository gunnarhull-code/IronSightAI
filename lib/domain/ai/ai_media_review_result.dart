import 'ai_suggestion.dart';

/// Session-local AI review payload. Not persisted until the user applies items.
class AiMediaReviewResult {
  const AiMediaReviewResult({
    required this.suggestions,
    this.disclaimer = defaultDisclaimer,
    this.reviewKind = frameBasedReviewKind,
  });

  static const String defaultDisclaimer =
      'AI suggestions only — not verified facts. Humans remain the final '
      'authority. Photographs and frames cannot prove mechanical safety.';

  static const String frameBasedReviewKind = 'frame_based_video_review';

  final List<AiSuggestion> suggestions;
  final String disclaimer;
  final String reviewKind;

  bool get isFrameBasedVideoReview => reviewKind == frameBasedReviewKind;

  AiMediaReviewResult withSuggestions(List<AiSuggestion> next) {
    return AiMediaReviewResult(
      suggestions: List<AiSuggestion>.unmodifiable(next),
      disclaimer: disclaimer,
      reviewKind: reviewKind,
    );
  }
}
