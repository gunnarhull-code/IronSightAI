/// Screen-reader and visible copy for optional AI media review.
abstract final class AiMediaReviewLabels {
  static const String actionButton = 'AI Media Review';
  static const String screenTitle = 'AI Media Review';
  static const String optionalBadge = 'Optional';
  static const String suggestionsDisclaimer =
      'AI suggestions only — not verified facts. Humans remain the final '
      'authority. Photos and video frames cannot prove mechanical safety.';
  static const String frameBasedExplanation =
      'Walkaround review is frame-based: up to 6 representative still frames '
      'are decoded from the recorded MP4 on this device. Separate camera '
      'stills taken before or after recording are not used. The original '
      'video stays local and is not uploaded.';
  static const String consentTitle =
      'Before photos or frames leave this device';
  static const String consentBody =
      'Selected inspection photos and extracted walkaround video frames will '
      'be sent securely for AI analysis. The original walkaround video is not '
      'uploaded. Nothing is written to this inspection until you apply a '
      'suggestion.';
  static const String analyzeButton = 'Analyze media online';
  static const String retryButton = 'Retry';
  static const String cancelButton = 'Cancel analysis';
  static const String recordVideoButton =
      'Record walkaround video, maximum 30 seconds';
  static const String removeVideoButton = 'Remove walkaround video';
  static const String continueWithoutAi = 'Continue without AI';
  static const String applyButton = 'Apply suggestion';
  static const String editButton = 'Edit suggestion';
  static const String dismissButton = 'Dismiss suggestion';
  static const String replaceConfirmTitle = 'Replace confirmed value?';
  static const String replaceConfirmBody =
      'This inspection already has a confirmed value. Applying this AI '
      'suggestion will replace it. You can cancel to keep the confirmed value.';
  static const String keepExisting = 'Keep existing value';
  static const String replaceExisting = 'Replace with suggestion';
  static const String confidencePrefix = 'Confidence';
  static const String sourcePrefix = 'Supported by';
  static const String ambiguityNote = 'Check ambiguous characters.';
  static const String loadingAnnouncement =
      'Uploading selected images and extracted video frames. Inspection '
      'unchanged.';
}
