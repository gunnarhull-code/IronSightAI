/// Semantic / accessibility labels for equipment ID capture.
abstract final class EquipmentIdCaptureLabels {
  static const String serialScanButton = 'Scan serial number with camera';
  static const String hourScanButton = 'Scan hour meter with camera';
  static const String serialManualField = 'Serial number manual entry';
  static const String hourManualField = 'Hour meter manual entry';
  static const String recommendedPrefix = 'Recommended identification value';
  static const String alternativePrefix = 'Other possible identification value';
  static const String otherPossibilities = 'Other possibilities';
  static const String savedStatePrefix = 'Saved identification value';
  static const String saveError = 'Equipment ID save error';
  static const String manualFallbackHint =
      'Manual entry is always available and saves when you finish editing. '
      'Detected text is never saved automatically.';
  static const String unsupportedPlatformBanner =
      'Camera scanning is not supported here. Enter the value manually.';
}
