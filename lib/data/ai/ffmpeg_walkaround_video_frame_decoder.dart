import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/ai/decoded_video_frame.dart';
import '../../domain/ai/video_frame_extraction.dart';
import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_frame_decoder.dart';
import '../../domain/equipment_id_capture/captured_image.dart';

/// Decodes representative JPEG stills from a local MP4 using ffmpeg.
///
/// Used by tests and Linux/desktop hosts. Mobile uses
/// [VideoThumbnailWalkaroundFrameDecoder].
class FfmpegWalkaroundVideoFrameDecoder implements WalkaroundVideoFrameDecoder {
  FfmpegWalkaroundVideoFrameDecoder({
    this.ffmpegExecutable = 'ffmpeg',
    Directory Function()? temporaryDirectory,
  }) : _temporaryDirectory =
           temporaryDirectory ??
           (() => Directory.systemTemp.createTempSync('ironsight_frames_'));

  final String ffmpegExecutable;
  final Directory Function() _temporaryDirectory;

  @override
  Future<List<DecodedVideoFrame>> decodeRepresentativeFrames({
    required String videoPath,
    required Duration duration,
    int maxFrames = WalkaroundVideo.maxFrameCount,
  }) async {
    final video = File(videoPath);
    if (!await video.exists()) {
      return const [];
    }
    final offsets = VideoFrameExtraction.sampleOffsetsMs(
      duration: duration,
      maxFrames: maxFrames,
    );
    final workDir = _temporaryDirectory();
    try {
      final frames = <DecodedVideoFrame>[];
      for (var i = 0; i < offsets.length; i++) {
        final offsetMs = offsets[i];
        final outPath = p.join(workDir.path, 'frame_$i.jpg');
        // Seek after -i for accurate short-clip timestamps; fall back earlier
        // if the requested offset is past the last decodable frame.
        final sought = await _extractJpegAt(
          ffmpegExecutable: ffmpegExecutable,
          videoPath: videoPath,
          offsetMs: offsetMs,
          outPath: outPath,
        );
        if (!sought) {
          continue;
        }
        final file = File(outPath);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        frames.add(
          DecodedVideoFrame(
            image: CapturedImage(
              bytes: bytes,
              path: outPath,
              mimeType: 'image/jpeg',
            ),
            sourceVideoPath: videoPath,
            timeOffsetMs: offsetMs,
          ),
        );
      }
      return List<DecodedVideoFrame>.unmodifiable(frames);
    } finally {
      try {
        if (workDir.existsSync()) {
          workDir.deleteSync(recursive: true);
        }
      } catch (_) {
        // Best-effort cleanup; frame bytes are already in memory.
      }
    }
  }

  static Future<bool> _extractJpegAt({
    required String ffmpegExecutable,
    required String videoPath,
    required int offsetMs,
    required String outPath,
  }) async {
    final candidates = <int>{
      offsetMs,
      if (offsetMs > 100) offsetMs - 100,
      if (offsetMs > 250) offsetMs - 250,
    };
    for (final candidate in candidates) {
      final result = await Process.run(ffmpegExecutable, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        videoPath,
        '-ss',
        (candidate / 1000).toStringAsFixed(3),
        '-frames:v',
        '1',
        '-q:v',
        '4',
        '-y',
        outPath,
      ]);
      if (result.exitCode == 0 && File(outPath).existsSync()) {
        return true;
      }
    }
    return false;
  }
}
