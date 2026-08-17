import '../equipment_id_capture/captured_image.dart';
import 'decoded_video_frame.dart';

/// Local walkaround video plus stills decoded from that same MP4.
///
/// The original video file stays on the device. Only [representativeFrames]
/// may be sent for AI analysis, and every frame must originate from [localPath].
class WalkaroundVideo {
  WalkaroundVideo({
    required this.localPath,
    required this.duration,
    required List<DecodedVideoFrame> representativeFrames,
    this.mimeType = 'video/mp4',
    this.byteSize = 0,
  }) : representativeFrames = List<DecodedVideoFrame>.unmodifiable(
         representativeFrames,
       );

  /// App-private path of the original recording. Never included in AI payloads.
  final String localPath;
  final Duration duration;
  final List<DecodedVideoFrame> representativeFrames;
  final String mimeType;
  final int byteSize;

  static const Duration maxDuration = Duration(seconds: 30);
  static const int maxFrameCount = 6;

  bool get exceedsMaxDuration => duration > maxDuration;

  bool get hasFrames => representativeFrames.isNotEmpty;

  /// True only when every frame was decoded from [localPath].
  bool get framesDecodedFromLocalVideo {
    if (representativeFrames.isEmpty) return false;
    for (final frame in representativeFrames) {
      if (!frame.wasDecodedFromVideo || !frame.originatesFrom(localPath)) {
        return false;
      }
    }
    return true;
  }

  List<CapturedImage> get frameImages =>
      representativeFrames.map((frame) => frame.image).toList(growable: false);
}
