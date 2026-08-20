/// Structured suggestion types returned by AI media review.
enum AiSuggestionKind {
  manufacturer,
  model,
  serialNumber,
  hourMeter,
  visibleDamageOrWear,
  possibleLeak,
  possibleCrack,
  rust,
  dent,
  brokenGlassOrLight,
  tireOrTrackWear,
  visibleAttachment,
  unreadableOrUncertain;

  String get storageValue => switch (this) {
    AiSuggestionKind.manufacturer => 'manufacturer',
    AiSuggestionKind.model => 'model',
    AiSuggestionKind.serialNumber => 'serial_number',
    AiSuggestionKind.hourMeter => 'hour_meter',
    AiSuggestionKind.visibleDamageOrWear => 'visible_damage_or_wear',
    AiSuggestionKind.possibleLeak => 'possible_leak',
    AiSuggestionKind.possibleCrack => 'possible_crack',
    AiSuggestionKind.rust => 'rust',
    AiSuggestionKind.dent => 'dent',
    AiSuggestionKind.brokenGlassOrLight => 'broken_glass_or_light',
    AiSuggestionKind.tireOrTrackWear => 'tire_or_track_wear',
    AiSuggestionKind.visibleAttachment => 'visible_attachment',
    AiSuggestionKind.unreadableOrUncertain => 'unreadable_or_uncertain',
  };

  String get displayLabel => switch (this) {
    AiSuggestionKind.manufacturer => 'Manufacturer',
    AiSuggestionKind.model => 'Model',
    AiSuggestionKind.serialNumber => 'Serial number',
    AiSuggestionKind.hourMeter => 'Hour-meter reading',
    AiSuggestionKind.visibleDamageOrWear => 'Visible damage or wear',
    AiSuggestionKind.possibleLeak => 'Possible leak',
    AiSuggestionKind.possibleCrack => 'Possible crack',
    AiSuggestionKind.rust => 'Rust',
    AiSuggestionKind.dent => 'Dent',
    AiSuggestionKind.brokenGlassOrLight => 'Broken glass or light',
    AiSuggestionKind.tireOrTrackWear => 'Tire or track wear',
    AiSuggestionKind.visibleAttachment => 'Visible attachment',
    AiSuggestionKind.unreadableOrUncertain => 'Unreadable or uncertain',
  };

  bool get isIdentity =>
      this == AiSuggestionKind.manufacturer ||
      this == AiSuggestionKind.model ||
      this == AiSuggestionKind.serialNumber ||
      this == AiSuggestionKind.hourMeter;

  bool get writesConfirmedEquipmentId =>
      this == AiSuggestionKind.serialNumber ||
      this == AiSuggestionKind.hourMeter;

  bool get writesInspectionNotes => !writesConfirmedEquipmentId;

  static AiSuggestionKind fromStorage(String value) {
    for (final kind in AiSuggestionKind.values) {
      if (kind.storageValue == value) return kind;
    }
    throw FormatException('Unknown AI suggestion kind: $value');
  }
}

enum AiSuggestionConfidence {
  high,
  medium,
  low;

  String get storageValue => name;

  String get displayLabel => switch (this) {
    AiSuggestionConfidence.high => 'High',
    AiSuggestionConfidence.medium => 'Medium',
    AiSuggestionConfidence.low => 'Low',
  };

  static AiSuggestionConfidence fromStorage(String value) {
    return switch (value.toLowerCase()) {
      'high' => AiSuggestionConfidence.high,
      'medium' => AiSuggestionConfidence.medium,
      'low' => AiSuggestionConfidence.low,
      _ => throw FormatException('Unknown AI confidence: $value'),
    };
  }
}
