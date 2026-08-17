import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  test('maps timeout after retries', () async {
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
    expect(calls, 2);
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
}
