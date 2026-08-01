import 'package:flutter/widgets.dart';

import '../../domain/equipment_id_capture/image_capture_port.dart';
import 'equipment_id_capture_bindings.dart';

/// Stub entry used when no conditional import matches.
EquipmentIdCaptureBindings createPlatformEquipmentIdCaptureBindings({
  ImageCapturePort? imageCapture,
  GlobalKey<NavigatorState>? navigatorKey,
  bool forceUnsupported = false,
}) {
  return EquipmentIdCaptureBindings.unsupported();
}
