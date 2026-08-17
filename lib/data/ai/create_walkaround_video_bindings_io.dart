import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../../domain/ai/walkaround_video_capture_port.dart';
import 'walkaround_video_capture_page.dart';

WalkaroundVideoCapturePort createWalkaroundVideoCapturePort({
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  if (!(Platform.isAndroid || Platform.isIOS) || navigatorKey == null) {
    return const UnsupportedWalkaroundVideoCapture();
  }
  return NavigatorWalkaroundVideoCapture(navigatorKey: navigatorKey);
}
