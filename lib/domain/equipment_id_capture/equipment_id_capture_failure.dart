/// Failure kinds the capture UX must surface honestly (never as false success).
enum EquipmentIdCaptureFailureKind {
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  captureCancelled,
  ocrFailure,
  noTextDetected,
  unsupportedPlatform,
}

/// Structured capture failure with user-facing guidance.
class EquipmentIdCaptureFailure {
  const EquipmentIdCaptureFailure({
    required this.kind,
    required this.message,
    this.guidance,
  });

  final EquipmentIdCaptureFailureKind kind;
  final String message;

  /// Extra guidance (e.g. open system settings after permanent denial).
  final String? guidance;

  factory EquipmentIdCaptureFailure.permissionDenied() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.permissionDenied,
      message: 'Camera permission was denied.',
      guidance: 'Allow camera access to scan, or enter the value manually.',
    );
  }

  factory EquipmentIdCaptureFailure.permissionPermanentlyDenied() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.permissionPermanentlyDenied,
      message: 'Camera permission is permanently denied.',
      guidance:
          'Open system settings, enable Camera for IronSight AI, then try '
          'again — or enter the value manually below.',
    );
  }

  factory EquipmentIdCaptureFailure.cameraUnavailable() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.cameraUnavailable,
      message: 'Camera is unavailable on this device.',
      guidance: 'Enter the value manually below.',
    );
  }

  factory EquipmentIdCaptureFailure.captureCancelled() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.captureCancelled,
      message: 'Capture was cancelled.',
      guidance: 'Try again, or enter the value manually below.',
    );
  }

  factory EquipmentIdCaptureFailure.ocrFailure([String? detail]) {
    return EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.ocrFailure,
      message: detail == null || detail.isEmpty
          ? 'On-device text recognition failed.'
          : 'On-device text recognition failed: $detail',
      guidance: 'Try another photo, or enter the value manually below.',
    );
  }

  factory EquipmentIdCaptureFailure.noTextDetected() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.noTextDetected,
      message: 'No text was detected in the photo.',
      guidance: 'Retake the photo, or enter the value manually below.',
    );
  }

  factory EquipmentIdCaptureFailure.unsupportedPlatform() {
    return const EquipmentIdCaptureFailure(
      kind: EquipmentIdCaptureFailureKind.unsupportedPlatform,
      message: 'Camera scanning is not supported on this platform.',
      guidance:
          'Use manual entry below. On-device scan is available on Android '
          'and iOS.',
    );
  }
}
