/// How a confirmed identification value was produced.
///
/// OCR output is never authoritative on its own — confirmed values always
/// reflect an explicit human action (select + confirm, or manual entry).
enum EquipmentIdCaptureMethod {
  /// User selected an OCR candidate and explicitly confirmed it.
  ocrConfirmed,

  /// User typed or edited the value and explicitly confirmed it.
  manual;

  String get storageValue => switch (this) {
    EquipmentIdCaptureMethod.ocrConfirmed => 'ocr',
    EquipmentIdCaptureMethod.manual => 'manual',
  };

  static EquipmentIdCaptureMethod fromStorage(String value) {
    return switch (value) {
      'ocr' => EquipmentIdCaptureMethod.ocrConfirmed,
      'manual' => EquipmentIdCaptureMethod.manual,
      _ => throw FormatException('Unknown equipment ID capture method: $value'),
    };
  }
}
