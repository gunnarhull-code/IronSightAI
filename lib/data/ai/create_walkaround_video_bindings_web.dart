import 'package:flutter/widgets.dart';

import '../../domain/ai/walkaround_video_capture_port.dart';

WalkaroundVideoCapturePort createWalkaroundVideoCapturePort({
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return const UnsupportedWalkaroundVideoCapture();
}
