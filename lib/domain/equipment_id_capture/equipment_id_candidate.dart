/// A selectable OCR-derived candidate after domain normalization/parsing.
class EquipmentIdCandidate {
  const EquipmentIdCandidate({
    required this.id,
    required this.displayValue,
    this.hours,
    this.sourceRawText,
  });

  final String id;
  final String displayValue;

  /// Present only for successfully parsed hour-meter candidates.
  final double? hours;

  final String? sourceRawText;
}
