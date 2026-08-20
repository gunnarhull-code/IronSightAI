import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'ai_review_diagnostics.dart';

/// Server-side adapter: Flutter calls this Edge Function only.
///
/// Provider credentials stay on the function. Vendor replacement does not
/// require inspection UI or domain changes. One Analyze tap produces at most
/// one HTTP request — billable retries are a deliberate user action.
class SupabaseEdgeAiService implements AIService {
  SupabaseEdgeAiService({
    required this.endpoint,
    required this.readAccessToken,
    http.Client? httpClient,
    this.timeout = AiMediaAnalysisRequest.timeout,
    this.maxAttempts = 1,
    Random? random,
  }) : _http = httpClient ?? http.Client(),
       _random = random ?? Random.secure();

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

  /// Kept for call-site compatibility. Automatic retries are never performed.
  final int maxAttempts;
  final http.Client _http;
  final Random _random;

  @override
  Future<AiMediaReviewResult> analyzeInspectionMedia(
    AiMediaAnalysisRequest request, {
    AiAnalysisCancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    if (maxAttempts < 1) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'must be at least 1',
      );
    }
    if (request.companyId.trim().isEmpty ||
        request.inspectionId.trim().isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    if (request.containsOriginalVideo) {
      throw StateError('Original walkaround video must never be uploaded.');
    }

    final requestId = _newRequestId();
    final accessToken = readAccessToken().trim();
    if (accessToken.isEmpty) {
      AiReviewDiagnostics.emit(requestId: requestId, stage: 'provider_auth');
      throw AiMediaReviewException(AiMediaReviewFailure.authentication());
    }

    final payload = AiMediaReviewPayloadCodec.encode(request);
    if (AiMediaReviewPayloadCodec.containsVideoMime(payload)) {
      throw StateError('Original walkaround video must never be uploaded.');
    }

    final encodedChars = _encodedCharCount(payload);
    AiReviewDiagnostics.emit(
      requestId: requestId,
      stage: 'request_accepted',
      fields: {
        'image_count': request.images.length,
        'encoded_chars': encodedChars,
        'approx_bytes': (encodedChars * 3) ~/ 4,
        'video_frame_count': request.videoFrames.length,
      },
    );

    _throwIfCancelled(cancelToken);
    try {
      AiReviewDiagnostics.emit(requestId: requestId, stage: 'provider_started');
      final started = DateTime.now();
      final response = await _post(payload, accessToken, requestId);
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: 'provider_http_status',
        fields: {
          'http_status': response.statusCode,
          'latency_ms': DateTime.now().difference(started).inMilliseconds,
        },
      );
      _throwIfCancelled(cancelToken);
      return _parseResponse(response, requestId);
    } on AiMediaReviewException catch (error) {
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: _stageFor(error.failure.kind),
      );
      rethrow;
    } on TimeoutException {
      AiReviewDiagnostics.emit(requestId: requestId, stage: 'provider_timeout');
      throw AiMediaReviewException(AiMediaReviewFailure.timeout());
    } catch (error, stackTrace) {
      if (mapRemoteFailure(error) is RemoteServiceUnavailableException) {
        AiReviewDiagnostics.emit(requestId: requestId, stage: 'offline');
        Error.throwWithStackTrace(
          AiMediaReviewException(AiMediaReviewFailure.offline()),
          stackTrace,
        );
      }
      AiReviewDiagnostics.emit(requestId: requestId, stage: 'provider_http');
      Error.throwWithStackTrace(
        AiMediaReviewException(AiMediaReviewFailure.providerFailure()),
        stackTrace,
      );
    }
  }

  Future<http.Response> _post(
    Map<String, dynamic> payload,
    String accessToken,
    String requestId,
  ) {
    return _http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'x-request-id': requestId,
          },
          body: jsonEncode(payload),
        )
        .timeout(timeout);
  }

  AiMediaReviewResult _parseResponse(http.Response response, String requestId) {
    final decoded = _tryDecode(response.body);
    final errorCode = _errorCode(decoded);

    if (errorCode != null) {
      final failure = failureForProviderError(
        errorCode,
        httpStatus: response.statusCode,
      );
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: _stageFor(failure.kind),
        fields: {'error_code': errorCode, 'http_status': response.statusCode},
      );
      throw AiMediaReviewException(failure);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AiMediaReviewException(AiMediaReviewFailure.authentication());
    }
    if (response.statusCode == 429) {
      throw AiMediaReviewException(AiMediaReviewFailure.quota());
    }
    if (response.statusCode == 504) {
      throw AiMediaReviewException(AiMediaReviewFailure.timeout());
    }
    if (response.statusCode == 404) {
      throw AiMediaReviewException(
        AiMediaReviewFailure.providerFailure(
          'AI media review is not available in this environment.',
        ),
      );
    }
    if (response.statusCode >= 500) {
      throw AiMediaReviewException(
        AiMediaReviewFailure.providerFailure(
          'The AI provider returned an HTTP error. Nothing was changed on '
          'this inspection. You can retry or continue without AI.',
        ),
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiMediaReviewException(AiMediaReviewFailure.providerFailure());
    }

    if (decoded == null) {
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: 'provider_invalid_json',
      );
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }

    try {
      final result = AiMediaReviewParser.parse(decoded);
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: 'normalized_success',
        fields: {'suggestion_count': result.suggestions.length},
      );
      return result;
    } on AiMediaReviewException {
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: 'provider_schema_invalid',
      );
      rethrow;
    } on FormatException {
      AiReviewDiagnostics.emit(
        requestId: requestId,
        stage: 'provider_schema_invalid',
      );
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
  }

  static Object? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String? _errorCode(Object? decoded) {
    if (decoded is! Map) return null;
    final error = decoded['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();
    return null;
  }

  static int _encodedCharCount(Map<String, dynamic> payload) {
    final images = payload['images'];
    if (images is! List) return 0;
    var total = 0;
    for (final item in images) {
      if (item is! Map) continue;
      final encoded = item['content_base64'];
      if (encoded is String) total += encoded.length;
    }
    return total;
  }

  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static String _stageFor(AiMediaReviewFailureKind kind) {
    return switch (kind) {
      AiMediaReviewFailureKind.timeout => 'provider_timeout',
      AiMediaReviewFailureKind.authentication => 'provider_auth',
      AiMediaReviewFailureKind.quota => 'provider_quota',
      AiMediaReviewFailureKind.malformedResponse => 'provider_schema_invalid',
      AiMediaReviewFailureKind.offline => 'offline',
      AiMediaReviewFailureKind.cancelled => 'cancelled',
      AiMediaReviewFailureKind.providerFailure => 'provider_http',
      AiMediaReviewFailureKind.noMedia => 'no_media',
      AiMediaReviewFailureKind.videoTooLong => 'video_too_long',
      AiMediaReviewFailureKind.videoFramesMissing => 'video_frames_missing',
    };
  }

  void _throwIfCancelled(AiAnalysisCancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw AiMediaReviewException(AiMediaReviewFailure.cancelled());
    }
  }

  /// Maps stable Edge Function / provider error codes to typed failures.
  static AiMediaReviewFailure failureForProviderError(
    String code, {
    int? httpStatus,
  }) {
    switch (code) {
      case 'provider_timeout':
        return AiMediaReviewFailure.timeout();
      case 'provider_auth':
      case 'unauthorized':
      case 'forbidden':
      case 'tenant_mismatch':
        return AiMediaReviewFailure.authentication();
      case 'provider_quota':
        return AiMediaReviewFailure.quota();
      case 'provider_empty':
        return AiMediaReviewFailure.providerFailure(
          'The AI provider returned an empty completion. Nothing was changed '
          'on this inspection. You can retry or continue without AI.',
        );
      case 'provider_refusal':
        return AiMediaReviewFailure.providerFailure(
          'The AI provider refused this request. Nothing was changed on this '
          'inspection. You can retry or continue without AI.',
        );
      case 'provider_incomplete':
        return AiMediaReviewFailure.providerFailure(
          'The AI response was incomplete. Nothing was changed on this '
          'inspection. You can retry or continue without AI.',
        );
      case 'provider_invalid_json':
      case 'provider_schema_invalid':
        return AiMediaReviewFailure.malformedResponse();
      case 'provider_http':
        return AiMediaReviewFailure.providerFailure(
          'The AI provider returned an HTTP error. Nothing was changed on '
          'this inspection. You can retry or continue without AI.',
        );
      case 'provider_unconfigured':
        return AiMediaReviewFailure.providerFailure(
          'AI media review is not configured in this environment. Nothing was '
          'changed on this inspection.',
        );
      default:
        if (httpStatus == 401 || httpStatus == 403) {
          return AiMediaReviewFailure.authentication();
        }
        if (httpStatus == 429) {
          return AiMediaReviewFailure.quota();
        }
        if (httpStatus == 504) {
          return AiMediaReviewFailure.timeout();
        }
        if (httpStatus == 422) {
          return AiMediaReviewFailure.malformedResponse();
        }
        return AiMediaReviewFailure.providerFailure();
    }
  }
}
