/// A selectable OCR-derived candidate after domain normalization/parsing.
class EquipmentIdCandidate {
  const EquipmentIdCandidate({
    required this.id,
    required this.displayValue,
    this.hours,
    this.sourceRawText,
    this.isRecommended = false,
    this.confidence = 0,
  });

  final String id;
  final String displayValue;

  /// Present only for successfully parsed hour-meter candidates.
  final double? hours;

  final String? sourceRawText;

  /// True when this is the single recommended field value.
  final bool isRecommended;

  /// Deterministic 0.0–1.0 ranking score. Not engine OCR confidence.
  final double confidence;
}
