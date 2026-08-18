import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_diagnostics.dart';

void main() {
  tearDown(WalkaroundCaptureDiagnostics.reset);

  test('diagnostics never emit paths, bytes, or secrets', () {
    final events = <String>[];
    final payloads = <Map<String, Object?>>[];
    WalkaroundCaptureDiagnostics.sink = (event, fields) {
      events.add(event);
      payloads.add(fields);
    };

    WalkaroundCaptureDiagnostics.emit('recording_saved', {
      'path': '/data/user/0/com.example/cache/secret.mp4',
      'localPath': '/data/user/0/com.example/cache/secret.mp4',
      'bytes': List<int>.filled(8, 1),
      'apiKey': 'sk-not-a-real-key',
      'pathKind': WalkaroundCaptureDiagnostics.pathKind(
        '/data/user/0/com.example/cache/secret.mp4',
      ),
      'fileExists': true,
      'byteSize': 4096,
      'decodeErrorType': 'videoFramesMissing',
    });

    expect(events, ['recording_saved']);
    final fields = payloads.single;
    expect(fields.containsKey('path'), isFalse);
    expect(fields.containsKey('localPath'), isFalse);
    expect(fields.containsKey('bytes'), isFalse);
    expect(fields.containsKey('apiKey'), isFalse);
    expect(fields['pathKind'], 'absolute_file');
    expect(fields['fileExists'], isTrue);
    expect(fields['byteSize'], 4096);
    expect(fields['decodeErrorType'], 'videoFramesMissing');
    expect(fields.values.join(' '), isNot(contains('/data/user')));
  });
}
