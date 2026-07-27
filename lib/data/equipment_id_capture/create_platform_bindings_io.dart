import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../../domain/equipment_id_capture/image_capture_port.dart';
import 'camera_capture_page.dart';
import 'equipment_id_capture_bindings.dart';
import 'ml_kit_text_recognition_adapter.dart';
import 'permission_handler_camera_permission.dart';
import 'unsupported_and_callback_capture.dart';

/// Whether this IO host supports the on-device camera + ML Kit path.
bool get isMobileCameraOcrPlatform {
  return Platform.isAndroid || Platform.isIOS;
}

/// Mobile (IO) bindings: camera UI + ML Kit OCR + permission_handler.
///
/// Non-mobile IO targets (desktop) receive the unsupported/manual fallback
/// unless a custom [imageCapture] is supplied for tests.
EquipmentIdCaptureBindings createPlatformEquipmentIdCaptureBindings({
  ImageCapturePort? imageCapture,
  GlobalKey<NavigatorState>? navigatorKey,
  bool forceUnsupported = false,
}) {
  if (forceUnsupported || !isMobileCameraOcrPlatform) {
    if (imageCapture != null) {
      return EquipmentIdCaptureBindings(
        imageCapture: imageCapture,
        textRecognition: const UnsupportedTextRecognition(),
        cameraPermission: const UnsupportedCameraPermission(),
      );
    }
    return EquipmentIdCaptureBindings.unsupported();
  }

  final capture =
      imageCapture ??
      (navigatorKey == null
          ? const UnsupportedImageCapture()
          : NavigatorCameraImageCapture(navigatorKey: navigatorKey));

  return EquipmentIdCaptureBindings(
    imageCapture: capture,
    textRecognition: MlKitTextRecognitionAdapter(),
    cameraPermission: const PermissionHandlerCameraPermission(),
  );
}
