import 'dart:convert';
import 'dart:io';

import 'package:ironsight_ai/data/ai/ffmpeg_walkaround_video_frame_decoder.dart';
import 'package:ironsight_ai/domain/ai/video_frame_extraction.dart';
import 'package:path/path.dart' as p;

/// CLI helper used by `scripts/ai_media_review_poc_demo.sh`.
Future<void> main(List<String> args) async {
  String? video;
  var durationMs = 3000;
  var outDir = Directory.systemTemp.path;
  var manifestPath = 'manifest.json';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (i + 1 >= args.length) {
      throw ArgumentError('Missing value for $arg');
    }
    final value = args[++i];
    if (arg == '--video') {
      video = value;
    } else if (arg == '--duration-ms') {
      durationMs = int.parse(value);
    } else if (arg == '--out-dir') {
      outDir = value;
    } else if (arg == '--manifest') {
      manifestPath = value;
    } else {
      throw ArgumentError('Unknown arg: $arg');
    }
  }

  if (video == null) {
    throw ArgumentError('--video is required');
  }

  final directory = Directory(outDir)..createSync(recursive: true);
  final decoder = FfmpegWalkaroundVideoFrameDecoder();
  final frames = await VideoFrameExtraction.decodeAndBound(
    decoder: decoder,
    videoPath: video,
    duration: Duration(milliseconds: durationMs),
  );

  final written = <Map<String, Object>>[];
  for (var i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final path = p.join(directory.path, 'decoded_frame_$i.jpg');
    await File(path).writeAsBytes(frame.image.bytes, flush: true);
    written.add({
      'path': path,
      'source_video_path': frame.sourceVideoPath,
      'time_offset_ms': frame.timeOffsetMs,
      'byte_length': frame.image.bytes.length,
      'mime_type': frame.image.mimeType,
    });
  }

  final manifest = {
    'video_path': video,
    'duration_ms': durationMs,
    'frame_count': written.length,
    'frames_decoded_from_local_video': written.every(
      (frame) => frame['source_video_path'] == video,
    ),
    'frames': written,
  };
  await File(
    manifestPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('decoded_frames=${written.length}');
  stdout.writeln('manifest=$manifestPath');
}
