/// Semantic / accessibility labels for equipment ID capture.
abstract final class EquipmentIdCaptureLabels {
  static const String serialScanButton = 'Scan serial number with camera';
  static const String hourScanButton = 'Scan hour meter with camera';
  static const String serialManualField = 'Serial number manual entry';
  static const String hourManualField = 'Hour meter manual entry';
  static const String confirmButton = 'Confirm identification value';
  static const String clearConfirmationButton = 'Clear confirmation';
  static const String candidatePrefix = 'Detected candidate';
  static const String manualFallbackHint =
      'Manual entry is always available. Detected text is never saved until '
      'you confirm.';
  static const String unsupportedPlatformBanner =
      'Camera scanning is not supported here. Enter the value manually.';
}
