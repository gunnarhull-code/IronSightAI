/// How a confirmed identification value was produced.
///
/// OCR output is never authoritative on its own — confirmed values always
/// reflect an explicit human action (tapping a candidate, finishing
/// manual entry, or choosing an explicit unavailable option).
enum EquipmentIdCaptureMethod {
  /// User tapped an OCR candidate, which immediately persists it.
  ocrConfirmed,

  /// User typed or edited the value and finished editing.
  manual,

  /// User explicitly chose that the serial could not be verified.
  unableToVerify,

  /// User explicitly chose that hours were unavailable / not displayed.
  unavailable;

  String get storageValue => switch (this) {
    EquipmentIdCaptureMethod.ocrConfirmed => 'ocr',
    EquipmentIdCaptureMethod.manual => 'manual',
    EquipmentIdCaptureMethod.unableToVerify => 'unable_to_verify',
    EquipmentIdCaptureMethod.unavailable => 'unavailable',
  };

  bool get isExplicitUnavailable =>
      this == EquipmentIdCaptureMethod.unableToVerify ||
      this == EquipmentIdCaptureMethod.unavailable;

  static EquipmentIdCaptureMethod fromStorage(String value) {
    return switch (value) {
      'ocr' => EquipmentIdCaptureMethod.ocrConfirmed,
      'manual' => EquipmentIdCaptureMethod.manual,
      'unable_to_verify' => EquipmentIdCaptureMethod.unableToVerify,
      'unavailable' => EquipmentIdCaptureMethod.unavailable,
      _ => throw FormatException('Unknown equipment ID capture method: $value'),
    };
  }
}
