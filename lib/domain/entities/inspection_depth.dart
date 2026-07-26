/// Progressive inspection depth for a single inspection engine.
///
/// Quick Appraisal is the default experience. Detailed Inspection is the same
/// engine with category-level checklist depth enabled — not a separate system.
enum InspectionDepth {
  quickAppraisal,
  detailed;

  String get storageValue => switch (this) {
    InspectionDepth.quickAppraisal => 'quick_appraisal',
    InspectionDepth.detailed => 'detailed',
  };

  static InspectionDepth fromStorage(String value) {
    return switch (value) {
      'quick_appraisal' => InspectionDepth.quickAppraisal,
      'detailed' => InspectionDepth.detailed,
      _ => throw FormatException('Invalid inspection depth: $value'),
    };
  }
}
