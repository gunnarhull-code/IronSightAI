import '../equipment_id_capture/captured_image.dart';

/// One still decoded from a local walkaround MP4.
///
/// Separate camera stills taken before or after recording are not valid
/// [DecodedVideoFrame] values and must not be used for video analysis.
class DecodedVideoFrame {
  const DecodedVideoFrame({
    required this.image,
    required this.sourceVideoPath,
    required this.timeOffsetMs,
  });

  final CapturedImage image;

  /// Absolute path of the MP4 this frame was decoded from.
  final String sourceVideoPath;

  /// Approximate presentation timestamp inside the source video.
  final int timeOffsetMs;

  bool get wasDecodedFromVideo => true;

  bool originatesFrom(String videoPath) => sourceVideoPath == videoPath;
}
