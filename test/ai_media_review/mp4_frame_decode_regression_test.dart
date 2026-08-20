import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/ai/ai_media_review_payload_codec.dart';
import 'package:ironsight_ai/data/ai/ffmpeg_walkaround_video_frame_decoder.dart';
import 'package:ironsight_ai/domain/ai/ai_media_analysis_request.dart';
import 'package:ironsight_ai/domain/ai/decoded_video_frame.dart';
import 'package:ironsight_ai/domain/ai/video_frame_extraction.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:path/path.dart' as p;

/// Builds a short MP4 with distinct solid colors so decoded frames can be
/// proven to come from the recording (not from separate stills).
Future<File> _buildColorSegmentMp4(Directory dir) async {
  final red = p.join(dir.path, 'red.mp4');
  final green = p.join(dir.path, 'green.mp4');
  final blue = p.join(dir.path, 'blue.mp4');
  final listPath = p.join(dir.path, 'list.txt');
  final outPath = p.join(dir.path, 'walkaround.mp4');

  Future<void> makeSolid(String path, String color) async {
    final result = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'color=c=$color:s=320x240:d=1',
      '-pix_fmt',
      'yuv420p',
      '-y',
      path,
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  }

  await makeSolid(red, 'red');
  await makeSolid(green, 'green');
  await makeSolid(blue, 'blue');
  await File(
    listPath,
  ).writeAsString("file '$red'\nfile '$green'\nfile '$blue'\n");
  final concat = await Process.run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-f',
    'concat',
    '-safe',
    '0',
    '-i',
    listPath,
    '-c',
    'copy',
    '-y',
    outPath,
  ]);
  expect(concat.exitCode, 0, reason: concat.stderr.toString());
  return File(outPath);
}

Future<({int r, int g, int b})> _averageRgbViaFfmpeg(
  List<int> jpegBytes,
  Directory workDir,
) async {
  workDir.createSync(recursive: true);
  final input = File(p.join(workDir.path, 'frame.jpg'));
  final output = File(p.join(workDir.path, 'frame.rgb'));
  await input.writeAsBytes(jpegBytes, flush: true);
  final result = await Process.run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-i',
    input.path,
    '-f',
    'rawvideo',
    '-pix_fmt',
    'rgb24',
    '-y',
    output.path,
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  final bytes = await output.readAsBytes();
  expect(bytes.length, greaterThanOrEqualTo(3));
  var r = 0, g = 0, b = 0, count = 0;
  for (var i = 0; i + 2 < bytes.length; i += 3) {
    r += bytes[i];
    g += bytes[i + 1];
    b += bytes[i + 2];
    count += 1;
  }
  return (r: r ~/ count, g: g ~/ count, b: b ~/ count);
}

void main() {
  late Directory workDir;

  setUp(() {
    workDir = Directory.systemTemp.createTempSync('ironsight_mp4_frames_');
  });

  tearDown(() {
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }
  });

  test(
    'uploaded video frames are decoded from the recorded MP4, not separate stills',
    () async {
      final mp4 = await _buildColorSegmentMp4(workDir);
      final decoder = FfmpegWalkaroundVideoFrameDecoder();
      const duration = Duration(seconds: 3);
      final decoded = await decoder.decodeRepresentativeFrames(
        videoPath: mp4.path,
        duration: duration,
        maxFrames: 3,
      );

      expect(decoded, isNotEmpty);
      expect(decoded.length, lessThanOrEqualTo(WalkaroundVideo.maxFrameCount));
      expect(
        decoded.every((frame) => frame.originatesFrom(mp4.path)),
        isTrue,
        reason: 'every frame must declare the recorded MP4 as its source',
      );
      expect(
        decoded.every((frame) => frame.image.mimeType.startsWith('image/')),
        isTrue,
      );
      expect(
        decoded.map((frame) => frame.timeOffsetMs).toSet().length,
        decoded.length,
        reason: 'representative frames should come from distinct timestamps',
      );

      expect(decoded.first.image.bytes.length, greaterThan(500));
      expect(decoded.last.image.bytes.length, greaterThan(500));
      // Distinct timestamps inside the recorded MP4 must yield distinct stills.
      expect(
        decoded.first.image.bytes,
        isNot(equals(decoded.last.image.bytes)),
        reason: 'frames decoded from different MP4 timestamps must differ',
      );

      final first = await _averageRgbViaFfmpeg(
        decoded.first.image.bytes,
        Directory(p.join(workDir.path, 'avg0')),
      );
      final last = await _averageRgbViaFfmpeg(
        decoded.last.image.bytes,
        Directory(p.join(workDir.path, 'avg1')),
      );
      // First second is red-dominant; last second is blue-dominant.
      // Allow generous tolerance for yuv420p encode/decode drift.
      expect(first.r, greaterThan(first.g));
      expect(first.r, greaterThan(first.b));
      expect(last.b, greaterThan(last.r));
      expect(last.b, greaterThan(last.g));

      final video = WalkaroundVideo(
        localPath: mp4.path,
        duration: duration,
        representativeFrames: decoded,
        byteSize: await mp4.length(),
      );
      expect(video.framesDecodedFromLocalVideo, isTrue);
      final bounded = VideoFrameExtraction.extractBoundedFrames(video);

      final request = AiMediaAnalysisRequest(
        companyId: 'company-a',
        inspectionId: 'insp-1',
        includesVideoFrames: true,
        images: [
          AiMediaImage(
            id: 'photo-1',
            role: AiMediaImageRole.inspectionPhoto,
            label: 'Front-left overview',
            slot: InspectionPhotoSlot.frontLeftOverview,
            image: CapturedImage(
              bytes: Uint8List.fromList(bounded.first.image.bytes),
              mimeType: 'image/jpeg',
            ),
          ),
          for (var i = 0; i < bounded.length; i++)
            AiMediaImage(
              id: 'walkaround-frame-$i',
              role: AiMediaImageRole.videoFrame,
              label: 'Walkaround video frame ${i + 1}',
              frameIndex: i,
              image: bounded[i].image,
            ),
        ],
      );

      expect(request.containsOriginalVideo, isFalse);
      final payload = AiMediaReviewPayloadCodec.encode(request);
      expect(AiMediaReviewPayloadCodec.containsVideoMime(payload), isFalse);
      expect(payload.containsKey('video'), isFalse);
      expect(payload.containsKey('video_base64'), isFalse);
      expect(payload.toString().contains(mp4.path), isFalse);
      expect(
        (payload['images'] as List).where(
          (item) => item is Map && item['role'] == 'video_frame',
        ),
        hasLength(bounded.length),
      );
    },
  );

  test('separate stills cannot masquerade as decoded video frames', () async {
    final mp4 = await _buildColorSegmentMp4(workDir);
    final stillPath = p.join(workDir.path, 'separate-still.jpg');
    final still = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'color=c=yellow:s=320x240:d=0.1',
      '-frames:v',
      '1',
      '-y',
      stillPath,
    ]);
    expect(still.exitCode, 0);

    final stillBytes = await File(stillPath).readAsBytes();
    final video = WalkaroundVideo(
      localPath: mp4.path,
      duration: const Duration(seconds: 3),
      representativeFrames: [
        DecodedVideoFrame(
          image: CapturedImage(
            bytes: stillBytes,
            path: stillPath,
            mimeType: 'image/jpeg',
          ),
          // Separate still path — not the recorded MP4.
          sourceVideoPath: stillPath,
          timeOffsetMs: 0,
        ),
      ],
    );
    expect(video.framesDecodedFromLocalVideo, isFalse);
    expect(
      () => VideoFrameExtraction.extractBoundedFrames(video),
      throwsA(isA<Object>()),
    );
  });
}
