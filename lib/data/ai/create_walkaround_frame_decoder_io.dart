import 'dart:io' show Platform;

import '../../domain/ai/walkaround_video_frame_decoder.dart';
import 'ffmpeg_walkaround_video_frame_decoder.dart';
import 'video_thumbnail_walkaround_frame_decoder.dart';

WalkaroundVideoFrameDecoder createWalkaroundVideoFrameDecoder() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const VideoThumbnailWalkaroundFrameDecoder();
  }
  return FfmpegWalkaroundVideoFrameDecoder();
}
