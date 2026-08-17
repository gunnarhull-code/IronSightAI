import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/ai/platform_walkaround_video_frame_decoder.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.ironsight_ai/walkaround_frames');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'platform decoder requests JPEG frames from the recorded MP4 path only',
    () async {
      final requested = <Map<Object?, Object?>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'extractJpegFrame');
            final args = Map<Object?, Object?>.from(call.arguments as Map);
            requested.add(args);
            final offset = args['timeMs'] as int;
            // Distinct JPEG-looking payloads per timestamp.
            return Uint8List.fromList([
              0xFF,
              0xD8,
              offset & 0xFF,
              0xFF,
              0xD9,
            ]);
          });

      const videoPath = '/data/user/0/app/cache/walkaround.mp4';
      final decoder = PlatformWalkaroundVideoFrameDecoder();
      final frames = await decoder.decodeRepresentativeFrames(
        videoPath: videoPath,
        duration: const Duration(seconds: 3),
        maxFrames: 3,
      );

      expect(frames, hasLength(3));
      expect(frames.length, lessThanOrEqualTo(WalkaroundVideo.maxFrameCount));
      expect(frames.every((frame) => frame.originatesFrom(videoPath)), isTrue);
      expect(requested, hasLength(3));
      expect(
        requested.every((args) => args['path'] == videoPath),
        isTrue,
        reason: 'native extraction must target the recorded MP4',
      );
      expect(requested.map((args) => args['timeMs']).toSet().length, 3);
    },
  );

  test(
    'platform decoder skips null native frames without inventing stills',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      final frames = await const PlatformWalkaroundVideoFrameDecoder()
          .decodeRepresentativeFrames(
            videoPath: '/tmp/walkaround.mp4',
            duration: const Duration(seconds: 2),
            maxFrames: 2,
          );
      expect(frames, isEmpty);
    },
  );
}
