import '../../domain/equipment_id_capture/camera_permission_port.dart';
import '../../domain/equipment_id_capture/image_capture_port.dart';
import '../../domain/equipment_id_capture/text_recognition_port.dart';
import 'unsupported_and_callback_capture.dart';

/// Default bindings used when the platform cannot host camera + on-device OCR.
class EquipmentIdCaptureBindings {
  const EquipmentIdCaptureBindings({
    required this.imageCapture,
    required this.textRecognition,
    required this.cameraPermission,
  });

  final ImageCapturePort imageCapture;
  final TextRecognitionPort textRecognition;
  final CameraPermissionPort cameraPermission;

  /// Web / unsupported fallback: manual entry only.
  factory EquipmentIdCaptureBindings.unsupported() {
    return const EquipmentIdCaptureBindings(
      imageCapture: UnsupportedImageCapture(),
      textRecognition: UnsupportedTextRecognition(),
      cameraPermission: UnsupportedCameraPermission(),
    );
  }
}
