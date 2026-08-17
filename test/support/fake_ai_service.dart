import 'dart:async';

import 'package:ironsight_ai/domain/ai/ai_media_analysis_request.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_result.dart';
import 'package:ironsight_ai/domain/ai/ai_service.dart';

class FakeAIService implements AIService {
  FakeAIService({
    this.result,
    this.error,
    this.delay = Duration.zero,
    this.hangUntilCancel = false,
  });

  AiMediaReviewResult? result;
  Object? error;
  Duration delay;
  bool hangUntilCancel;
  int analyzeCallCount = 0;
  AiMediaAnalysisRequest? lastRequest;
  bool lastRequestHadVideoMime = false;

  @override
  Future<AiMediaReviewResult> analyzeInspectionMedia(
    AiMediaAnalysisRequest request, {
    AiAnalysisCancelToken? cancelToken,
  }) async {
    analyzeCallCount += 1;
    lastRequest = request;
    lastRequestHadVideoMime = request.containsOriginalVideo;

    if (hangUntilCancel) {
      final completer = Completer<AiMediaReviewResult>();
      cancelToken?.addListener(() {
        if (!completer.isCompleted) {
          completer.completeError(
            AiMediaReviewException(AiMediaReviewFailure.cancelled()),
          );
        }
      });
      if (cancelToken?.isCancelled == true && !completer.isCompleted) {
        completer.completeError(
          AiMediaReviewException(AiMediaReviewFailure.cancelled()),
        );
      }
      return completer.future;
    }

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (cancelToken?.isCancelled == true) {
      throw AiMediaReviewException(AiMediaReviewFailure.cancelled());
    }
    if (error != null) {
      final err = error!;
      if (err is AiMediaReviewException) throw err;
      throw err;
    }
    final resolved = result;
    if (resolved == null) {
      throw AiMediaReviewException(AiMediaReviewFailure.providerFailure());
    }
    return resolved;
  }
}
