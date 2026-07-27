import '../../domain/equipment_id_capture/captured_image.dart';
import '../../domain/equipment_id_capture/image_capture_port.dart';
import '../../domain/equipment_id_capture/recognized_text_block.dart';
import '../../domain/equipment_id_capture/text_recognition_port.dart';
import '../../domain/equipment_id_capture/camera_permission_port.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_failure.dart';

/// Image capture that always reports unsupported (web / desktop fallback).
class UnsupportedImageCapture implements ImageCapturePort {
  const UnsupportedImageCapture();

  @override
  bool get isSupported => false;

  @override
  Future<CapturedImage> captureStill() {
    throw EquipmentIdCaptureException(
      EquipmentIdCaptureFailure.unsupportedPlatform(),
    );
  }
}

/// OCR that always reports unsupported.
class UnsupportedTextRecognition implements TextRecognitionPort {
  const UnsupportedTextRecognition();

  @override
  bool get isSupported => false;

  @override
  Future<List<RecognizedTextBlock>> recognize(CapturedImage image) async {
    throw EquipmentIdCaptureException(
      EquipmentIdCaptureFailure.unsupportedPlatform(),
    );
  }

  @override
  Future<void> dispose() async {}
}

/// Permission port for platforms without a camera permission prompt.
class UnsupportedCameraPermission implements CameraPermissionPort {
  const UnsupportedCameraPermission();

  @override
  Future<CameraPermissionStatus> check() async =>
      CameraPermissionStatus.unavailable;

  @override
  Future<CameraPermissionStatus> request() async =>
      CameraPermissionStatus.unavailable;
}

/// Image capture driven by an injected UI callback (keeps `camera` out of
/// domain / general widgets).
class CallbackImageCapture implements ImageCapturePort {
  CallbackImageCapture({
    required this.capture,
    this.isSupported = true,
  });

  final Future<CapturedImage> Function() capture;

  @override
  final bool isSupported;

  @override
  Future<CapturedImage> captureStill() => capture();
}
