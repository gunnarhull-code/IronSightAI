import 'captured_image.dart';
import 'equipment_id_capture_failure.dart';

/// Application-owned still-image capture port.
///
/// Presentation and domain code must not import the `camera` package.
abstract class ImageCapturePort {
  /// Whether this implementation can attempt a capture on the current device.
  bool get isSupported;

  /// Captures a still image for offline OCR.
  ///
  /// Throws [EquipmentIdCaptureException] for permission, cancel, or hardware
  /// failures. Never performs network I/O.
  Future<CapturedImage> captureStill();
}

/// Domain exception wrapping a typed [EquipmentIdCaptureFailure].
class EquipmentIdCaptureException implements Exception {
  EquipmentIdCaptureException(this.failure);

  final EquipmentIdCaptureFailure failure;

  @override
  String toString() => 'EquipmentIdCaptureException(${failure.kind})';
}
