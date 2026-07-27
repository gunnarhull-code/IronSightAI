import 'package:flutter/widgets.dart';

import '../../domain/equipment_id_capture/image_capture_port.dart';
import 'equipment_id_capture_bindings.dart';

/// Web bindings: camera/OCR unsupported — manual entry only.
EquipmentIdCaptureBindings createPlatformEquipmentIdCaptureBindings({
  ImageCapturePort? imageCapture,
  GlobalKey<NavigatorState>? navigatorKey,
  bool forceUnsupported = true,
}) {
  return EquipmentIdCaptureBindings.unsupported();
}
