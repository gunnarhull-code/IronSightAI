import 'dart:io' show Platform;

import '../../domain/ai/walkaround_video_frame_decoder.dart';
import 'ffmpeg_walkaround_video_frame_decoder.dart';
import 'platform_walkaround_video_frame_decoder.dart';

WalkaroundVideoFrameDecoder createWalkaroundVideoFrameDecoder() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const PlatformWalkaroundVideoFrameDecoder();
  }
  return FfmpegWalkaroundVideoFrameDecoder();
}
