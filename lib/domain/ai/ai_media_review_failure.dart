/// Typed failures for optional cloud AI media review.
///
/// None of these failures may mutate inspection data. Quick Appraisal remains
/// usable offline without AI.
enum AiMediaReviewFailureKind {
  offline,
  timeout,
  cancelled,
  providerFailure,
  malformedResponse,
  noMedia,
  videoTooLong,
  videoFramesMissing,
}

class AiMediaReviewFailure {
  const AiMediaReviewFailure({
    required this.kind,
    required this.message,
    this.announcement,
  });

  final AiMediaReviewFailureKind kind;
  final String message;

  /// Screen-reader announcement. Never relies on color alone.
  final String? announcement;

  String get spokenMessage => announcement ?? message;

  factory AiMediaReviewFailure.offline() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.offline,
      message:
          'AI media review is unavailable offline. Your inspection is saved '
          'on this device and you can continue without AI.',
      announcement:
          'AI media review unavailable offline. Inspection unchanged.',
    );
  }

  factory AiMediaReviewFailure.timeout() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.timeout,
      message:
          'AI media review timed out. Nothing was changed on this inspection. '
          'You can retry when the connection is ready.',
      announcement: 'AI media review timed out. Inspection unchanged.',
    );
  }

  factory AiMediaReviewFailure.cancelled() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.cancelled,
      message:
          'AI media review was cancelled. Your inspection work is still saved '
          'on this device.',
      announcement: 'AI media review cancelled. Inspection unchanged.',
    );
  }

  factory AiMediaReviewFailure.providerFailure([String? detail]) {
    return AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.providerFailure,
      message: detail == null || detail.trim().isEmpty
          ? 'AI media review could not complete. Nothing was changed on this '
                'inspection. You can retry or continue without AI.'
          : detail.trim(),
      announcement: 'AI provider failed. Inspection unchanged.',
    );
  }

  factory AiMediaReviewFailure.malformedResponse() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.malformedResponse,
      message:
          'AI returned a response this app could not use. Nothing was changed '
          'on this inspection. You can retry or continue without AI.',
      announcement: 'AI response unreadable. Inspection unchanged.',
    );
  }

  factory AiMediaReviewFailure.noMedia() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.noMedia,
      message:
          'Capture at least one required inspection photo before analyzing '
          'media online.',
      announcement: 'No inspection photos available for AI review.',
    );
  }

  factory AiMediaReviewFailure.videoTooLong() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.videoTooLong,
      message:
          'Walkaround video must be 30 seconds or less. The original video '
          'stays on this device and was not sent.',
      announcement: 'Walkaround video is longer than 30 seconds.',
    );
  }

  factory AiMediaReviewFailure.videoFramesMissing() {
    return const AiMediaReviewFailure(
      kind: AiMediaReviewFailureKind.videoFramesMissing,
      message:
          'Could not extract representative frames from the walkaround video. '
          'The original video stays on this device. You can analyze photos '
          'or record a shorter video.',
      announcement: 'Walkaround video frames could not be extracted.',
    );
  }
}

class AiMediaReviewException implements Exception {
  AiMediaReviewException(this.failure);

  final AiMediaReviewFailure failure;

  @override
  String toString() => 'AiMediaReviewException(${failure.kind})';
}
