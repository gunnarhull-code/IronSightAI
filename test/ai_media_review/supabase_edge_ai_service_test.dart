import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ironsight_ai/data/ai/ai_review_diagnostics.dart';
import 'package:ironsight_ai/data/ai/supabase_edge_ai_service.dart';
import 'package:ironsight_ai/domain/ai/ai_media_analysis_request.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/ai_service.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

AiMediaAnalysisRequest _request() {
  return AiMediaAnalysisRequest(
    companyId: 'company-a',
    inspectionId: 'insp-1',
    images: [
      AiMediaImage(
        id: 'p1',
        role: AiMediaImageRole.inspectionPhoto,
        label: 'Serial / data plate',
        slot: InspectionPhotoSlot.serialDataPlate,
        image: const CapturedImage(bytes: [1, 2, 3], mimeType: 'image/jpeg'),
      ),
    ],
  );
}

String _okBody() {
  return jsonEncode({
    'review_kind': 'frame_based_video_review',
    'suggestions': [
      {
        'id': 's1',
        'kind': 'manufacturer',
        'value': 'Caterpillar',
        'confidence': 'high',
        'source': {
          'type': 'photo',
          'slot': 'front_left_overview',
          'label': 'Front-left overview',
        },
      },
    ],
  });
}

void main() {
  test('parses a successful edge-function response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, contains('ai-media-review'));
      expect(request.headers['Authorization'], 'Bearer test-jwt');
      expect(request.body.contains('video/'), isFalse);
      expect(request.body.contains('video_base64'), isFalse);
      return http.Response(_okBody(), 200);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
    );
    final result = await service.analyzeInspectionMedia(_request());
    expect(result.suggestions.single.value, 'Caterpillar');
  });

  test('maps connectivity failure to offline', () async {
    final client = MockClient((request) async {
      throw http.ClientException('failed host lookup');
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
      maxAttempts: 1,
    );
    expect(
      () => service.analyzeInspectionMedia(_request()),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.offline,
        ),
      ),
    );
  });

  test('maps client timeout without a billable retry', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      await Future<void>.delayed(const Duration(seconds: 5));
      return http.Response(_okBody(), 200);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
      timeout: const Duration(milliseconds: 20),
      maxAttempts: 2,
    );
    await expectLater(
      service.analyzeInspectionMedia(_request()),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.timeout,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('malformed JSON is a typed failure', () async {
    final client = MockClient((request) async {
      return http.Response('not-json', 200);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
      maxAttempts: 1,
    );
    expect(
      () => service.analyzeInspectionMedia(_request()),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
  });

  test('honors cancellation before the request is sent', () async {
    final client = MockClient((request) async {
      fail('HTTP must not run after cancel');
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
    );
    final token = AiAnalysisCancelToken()..cancel();
    expect(
      () => service.analyzeInspectionMedia(_request(), cancelToken: token),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.cancelled,
        ),
      ),
    );
  });

  test('provider 502 is a provider failure', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'error': 'provider_failure'}), 502);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
      maxAttempts: 1,
    );
    expect(
      () => service.analyzeInspectionMedia(_request()),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.providerFailure,
        ),
      ),
    );
  });

  test('maps provider timeout, auth, quota, and HTTP failures', () async {
    Future<void> expectCode(
      String code,
      int status,
      AiMediaReviewFailureKind kind,
    ) async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': code, 'request_id': 'req-1'}),
          status,
        );
      });
      final service = SupabaseEdgeAiService(
        endpoint: Uri.parse(
          'http://127.0.0.1:54321/functions/v1/ai-media-review',
        ),
        readAccessToken: () => 'test-jwt',
        httpClient: client,
      );
      await expectLater(
        service.analyzeInspectionMedia(_request()),
        throwsA(
          isA<AiMediaReviewException>().having(
            (e) => e.failure.kind,
            'kind',
            kind,
          ),
        ),
      );
    }

    await expectCode('provider_timeout', 504, AiMediaReviewFailureKind.timeout);
    await expectCode(
      'provider_auth',
      502,
      AiMediaReviewFailureKind.authentication,
    );
    await expectCode('provider_quota', 502, AiMediaReviewFailureKind.quota);
    await expectCode(
      'provider_http',
      502,
      AiMediaReviewFailureKind.providerFailure,
    );
    await expectCode(
      'provider_empty',
      502,
      AiMediaReviewFailureKind.providerFailure,
    );
    await expectCode(
      'provider_refusal',
      502,
      AiMediaReviewFailureKind.providerFailure,
    );
    await expectCode(
      'provider_incomplete',
      502,
      AiMediaReviewFailureKind.providerFailure,
    );
    await expectCode(
      'provider_invalid_json',
      422,
      AiMediaReviewFailureKind.malformedResponse,
    );
    await expectCode(
      'provider_schema_invalid',
      422,
      AiMediaReviewFailureKind.malformedResponse,
    );
  });

  test('maps provider 401, 429, and 5xx status codes', () async {
    Future<void> expectStatus(int status, AiMediaReviewFailureKind kind) async {
      final client = MockClient((request) async {
        return http.Response('{}', status);
      });
      final service = SupabaseEdgeAiService(
        endpoint: Uri.parse(
          'http://127.0.0.1:54321/functions/v1/ai-media-review',
        ),
        readAccessToken: () => 'test-jwt',
        httpClient: client,
      );
      await expectLater(
        service.analyzeInspectionMedia(_request()),
        throwsA(
          isA<AiMediaReviewException>().having(
            (e) => e.failure.kind,
            'kind',
            kind,
          ),
        ),
      );
    }

    await expectStatus(401, AiMediaReviewFailureKind.authentication);
    await expectStatus(429, AiMediaReviewFailureKind.quota);
    await expectStatus(500, AiMediaReviewFailureKind.providerFailure);
    await expectStatus(503, AiMediaReviewFailureKind.providerFailure);
  });

  test('never automatically retries a billable provider failure', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      return http.Response(jsonEncode({'error': 'provider_http'}), 502);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
      maxAttempts: 3,
    );
    await expectLater(
      service.analyzeInspectionMedia(_request()),
      throwsA(isA<AiMediaReviewException>()),
    );
    expect(calls, 1);
  });

  test('sends a request id and never logs secrets or media', () async {
    final lines = <String>[];
    AiReviewDiagnostics.sink = lines.add;
    addTearDown(AiReviewDiagnostics.reset);
    final client = MockClient((request) async {
      expect(request.headers['x-request-id'], isNotEmpty);
      expect(request.headers['Authorization'], 'Bearer test-jwt');
      return http.Response(_okBody(), 200);
    });
    final service = SupabaseEdgeAiService(
      endpoint: Uri.parse(
        'http://127.0.0.1:54321/functions/v1/ai-media-review',
      ),
      readAccessToken: () => 'test-jwt',
      httpClient: client,
    );
    await service.analyzeInspectionMedia(_request());
    expect(lines, isNotEmpty);
    final joined = lines.join('\n');
    expect(joined, contains('ironsight.ai_review'));
    expect(joined, contains('stage=request_accepted'));
    expect(joined, contains('stage=normalized_success'));
    expect(joined.toLowerCase(), isNot(contains('bearer')));
    expect(joined, isNot(contains('test-jwt')));
    expect(joined, isNot(contains('/tmp')));
    expect(joined, isNot(contains('Caterpillar')));
  });
}
