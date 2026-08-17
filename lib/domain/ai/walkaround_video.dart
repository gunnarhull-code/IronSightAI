import '../equipment_id_capture/captured_image.dart';

/// Local walkaround video plus extracted still frames.
///
/// The original video file stays on the device. Only [representativeFrames]
/// may be sent for AI analysis.
class WalkaroundVideo {
  const WalkaroundVideo({
    required this.localPath,
    required this.duration,
    required this.representativeFrames,
    this.mimeType = 'video/mp4',
    this.byteSize = 0,
  });

  /// App-private path of the original recording. Never included in AI payloads.
  final String localPath;
  final Duration duration;
  final List<CapturedImage> representativeFrames;
  final String mimeType;
  final int byteSize;

  static const Duration maxDuration = Duration(seconds: 30);
  static const int maxFrameCount = 6;

  bool get exceedsMaxDuration => duration > maxDuration;

  bool get hasFrames => representativeFrames.isNotEmpty;
}
