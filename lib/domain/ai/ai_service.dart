import 'ai_media_analysis_request.dart';
import 'ai_media_review_failure.dart';
import 'ai_media_review_result.dart';

/// Provider-agnostic cloud AI boundary.
///
/// Flutter and domain code must never call an AI vendor SDK or API directly.
/// Production implementations send bounded still images (and extracted video
/// frames) through a server-side adapter that holds provider credentials.
abstract class AIService {
  /// Analyzes inspection stills and optional walkaround frames.
  ///
  /// Implementations must not accept or upload a complete video file.
  /// Throws [AiMediaReviewException] for offline, timeout, provider, and
  /// malformed-response failures. Honors [cancelToken] without mutating
  /// inspection data.
  Future<AiMediaReviewResult> analyzeInspectionMedia(
    AiMediaAnalysisRequest request, {
    AiAnalysisCancelToken? cancelToken,
  });
}

/// Used when the composition root has no server adapter (tests / offline boot).
class UnavailableAIService implements AIService {
  const UnavailableAIService();

  @override
  Future<AiMediaReviewResult> analyzeInspectionMedia(
    AiMediaAnalysisRequest request, {
    AiAnalysisCancelToken? cancelToken,
  }) async {
    throw AiMediaReviewException(AiMediaReviewFailure.offline());
  }
}

/// Cooperative cancellation for an in-flight analysis request.
class AiAnalysisCancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }
}
