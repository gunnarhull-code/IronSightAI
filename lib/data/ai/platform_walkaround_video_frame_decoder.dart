import 'package:flutter/services.dart';

import '../../domain/ai/decoded_video_frame.dart';
import '../../domain/ai/video_frame_extraction.dart';
import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_frame_decoder.dart';
import '../../domain/equipment_id_capture/captured_image.dart';

/// Mobile decoder: extracts JPEG stills from a recorded walkaround MP4.
///
/// Uses an in-app MethodChannel backed by MediaMetadataRetriever (Android)
/// and AVAssetImageGenerator (iOS). Avoids the unmaintained `video_thumbnail`
/// plugin, which fails on AGP 9 / new DSL (jcenter + kotlin-android apply).
class PlatformWalkaroundVideoFrameDecoder
    implements WalkaroundVideoFrameDecoder {
  const PlatformWalkaroundVideoFrameDecoder({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName =
      'com.example.ironsight_ai/walkaround_frames';

  final MethodChannel _channel;

  @override
  Future<List<DecodedVideoFrame>> decodeRepresentativeFrames({
    required String videoPath,
    required Duration duration,
    int maxFrames = WalkaroundVideo.maxFrameCount,
  }) async {
    final offsets = VideoFrameExtraction.sampleOffsetsMs(
      duration: duration,
      maxFrames: maxFrames,
    );
    final frames = <DecodedVideoFrame>[];
    for (final offsetMs in offsets) {
      final raw = await _channel.invokeMethod<dynamic>('extractJpegFrame', {
        'path': videoPath,
        'timeMs': offsetMs,
        'maxWidth': 1280,
        'quality': 70,
      });
      if (raw == null) continue;
      final bytes = raw is Uint8List
          ? raw
          : Uint8List.fromList(List<int>.from(raw as List<dynamic>));
      if (bytes.isEmpty) continue;
      frames.add(
        DecodedVideoFrame(
          image: CapturedImage(
            bytes: bytes,
            // Metadata only — bytes already hold the decoded JPEG.
            path: '$videoPath.frame_${offsetMs}ms.jpg',
            mimeType: 'image/jpeg',
          ),
          sourceVideoPath: videoPath,
          timeOffsetMs: offsetMs,
        ),
      );
    }
    return List<DecodedVideoFrame>.unmodifiable(frames);
  }
}
