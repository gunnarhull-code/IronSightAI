import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/ai/ai_review_diagnostics.dart';

void main() {
  tearDown(AiReviewDiagnostics.reset);

  test('diagnostic logs contain no secret, media, response, or path', () {
    final lines = <String>[];
    AiReviewDiagnostics.sink = lines.add;

    AiReviewDiagnostics.emit(
      requestId: 'req-safe',
      stage: 'request_accepted',
      fields: {
        'path': '/data/user/0/com.example/cache/secret.mp4',
        'bytes': List<int>.filled(8, 1),
        'content': '{"suggestions":[{"value":"CAT123"}]}',
        'prompt': 'Read the serial plate for user@example.com',
        'authorization': 'Bearer sk-not-a-real-key',
        'api_key': 'sk-not-a-real-key',
        'token': 'jwt-secret',
        'image_count': 6,
        'encoded_chars': 1200,
      },
    );

    expect(lines, hasLength(1));
    final line = lines.single;
    expect(line, contains('ironsight.ai_review'));
    expect(line, contains('request_id=req-safe'));
    expect(line, contains('stage=request_accepted'));
    expect(line, contains('image_count=6'));
    expect(line, contains('encoded_chars=1200'));
    expect(line, isNot(contains('/data/user')));
    expect(line, isNot(contains('secret.mp4')));
    expect(line, isNot(contains('CAT123')));
    expect(line, isNot(contains('sk-not-a-real-key')));
    expect(line, isNot(contains('jwt-secret')));
    expect(line, isNot(contains('user@example.com')));
    expect(line.toLowerCase(), isNot(contains('bearer')));
    expect(line, isNot(contains('prompt')));
    expect(line, isNot(contains('content')));
  });
}
