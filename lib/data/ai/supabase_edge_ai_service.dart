import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/ai/ai_media_analysis_request.dart';
import '../../domain/ai/ai_media_review_failure.dart';
import '../../domain/ai/ai_media_review_parser.dart';
import '../../domain/ai/ai_media_review_result.dart';
import '../../domain/ai/ai_service.dart';
import '../../domain/exceptions/remote_service_unavailable_exception.dart';
import '../remote/remote_connectivity_failure.dart';
import 'ai_media_review_payload_codec.dart';

/// Server-side adapter: Flutter calls this Edge Function only.
///
/// Provider credentials stay on the function. Vendor replacement does not
/// require inspection UI or domain changes.
class SupabaseEdgeAiService implements AIService {
  SupabaseEdgeAiService({
    required this.endpoint,
    required this.readAccessToken,
    http.Client? httpClient,
    this.timeout = AiMediaAnalysisRequest.timeout,
    this.maxAttempts = 2,
  }) : _http = httpClient ?? http.Client();

  /// Builds an adapter from the current Supabase client.
  ///
  /// Reads the user JWT at call time. Provider API keys are never read here.
  factory SupabaseEdgeAiService.fromSupabase({
    required SupabaseClient client,
    required String supabaseUrl,
    http.Client? httpClient,
  }) {
    final base = supabaseUrl.replaceAll(RegExp(r'/+$'), '');
    return SupabaseEdgeAiService(
      endpoint: Uri.parse('$base/functions/v1/$functionName'),
      readAccessToken: () => client.auth.currentSession?.accessToken ?? '',
      httpClient: httpClient,
    );
  }

  static const String functionName = 'ai-media-review';

  final Uri endpoint;
  final String Function() readAccessToken;
  final Duration timeout;
  final int maxAttempts;
  final http.Client _http;

  @override
  Future<AiMediaReviewResult> analyzeInspectionMedia(
    AiMediaAnalysisRequest request, {
    AiAnalysisCancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    if (request.companyId.trim().isEmpty ||
        request.inspectionId.trim().isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    if (request.containsOriginalVideo) {
      throw StateError('Original walkaround video must never be uploaded.');
    }

    final accessToken = readAccessToken().trim();
    if (accessToken.isEmpty) {
      throw AiMediaReviewException(
        AiMediaReviewFailure.providerFailure(
          'Sign in to analyze media online. Inspection data on this device '
          'is unchanged.',
        ),
      );
    }

    final payload = AiMediaReviewPayloadCodec.encode(request);
    if (AiMediaReviewPayloadCodec.containsVideoMime(payload)) {
      throw StateError('Original walkaround video must never be uploaded.');
    }

    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _throwIfCancelled(cancelToken);
      try {
        final response = await _post(payload, accessToken);
        _throwIfCancelled(cancelToken);
        return _parseResponse(response);
      } on AiMediaReviewException catch (error) {
        lastError = error;
        if (!_shouldRetry(error.failure.kind) || attempt == maxAttempts) {
          rethrow;
        }
      } catch (error, stackTrace) {
        if (error is TimeoutException) {
          lastError = AiMediaReviewException(AiMediaReviewFailure.timeout());
        } else if (mapRemoteFailure(error)
            is RemoteServiceUnavailableException) {
          lastError = AiMediaReviewException(AiMediaReviewFailure.offline());
        } else {
          lastError = AiMediaReviewException(
            AiMediaReviewFailure.providerFailure(),
          );
        }
        final failure = (lastError as AiMediaReviewException).failure;
        if (!_shouldRetry(failure.kind) || attempt == maxAttempts) {
          Error.throwWithStackTrace(lastError, stackTrace);
        }
      }
    }
    throw lastError ??
        AiMediaReviewException(AiMediaReviewFailure.providerFailure());
  }

  Future<http.Response> _post(
    Map<String, dynamic> payload,
    String accessToken,
  ) {
    return _http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(timeout);
  }

  AiMediaReviewResult _parseResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AiMediaReviewException(
        AiMediaReviewFailure.providerFailure(
          'AI media review is not authorized for this company.',
        ),
      );
    }
    if (response.statusCode == 404) {
      throw AiMediaReviewException(
        AiMediaReviewFailure.providerFailure(
          'AI media review is not available in this environment.',
        ),
      );
    }
    if (response.statusCode >= 500) {
      throw AiMediaReviewException(AiMediaReviewFailure.providerFailure());
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiMediaReviewException(AiMediaReviewFailure.providerFailure());
    }

    Object decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    if (decoded is Map && decoded['error'] != null) {
      throw AiMediaReviewException(AiMediaReviewFailure.providerFailure());
    }
    try {
      return AiMediaReviewParser.parse(decoded);
    } on AiMediaReviewException {
      rethrow;
    } on FormatException {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
  }

  bool _shouldRetry(AiMediaReviewFailureKind kind) {
    return kind == AiMediaReviewFailureKind.timeout ||
        kind == AiMediaReviewFailureKind.providerFailure;
  }

  void _throwIfCancelled(AiAnalysisCancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw AiMediaReviewException(AiMediaReviewFailure.cancelled());
    }
  }
}
