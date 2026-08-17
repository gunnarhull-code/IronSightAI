import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../domain/ai/decoded_video_frame.dart';
import '../../domain/ai/video_frame_extraction.dart';
import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_frame_decoder.dart';
import '../../domain/equipment_id_capture/captured_image.dart';

/// Mobile decoder: extracts JPEG stills from the recorded walkaround MP4.
class VideoThumbnailWalkaroundFrameDecoder
    implements WalkaroundVideoFrameDecoder {
  const VideoThumbnailWalkaroundFrameDecoder();

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
    final tempDir = await getTemporaryDirectory();
    final frames = <DecodedVideoFrame>[];
    for (final offsetMs in offsets) {
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: offsetMs,
        quality: 70,
        maxWidth: 1280,
      );
      if (bytes == null || bytes.isEmpty) continue;
      frames.add(
        DecodedVideoFrame(
          image: CapturedImage(
            bytes: Uint8List.fromList(bytes),
            path: '${tempDir.path}/walkaround_${offsetMs}ms.jpg',
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
