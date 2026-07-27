/// Vendor-neutral OCR text unit produced by a [TextRecognitionPort].
///
/// Must not carry ML Kit / camera package types into domain entities.
class RecognizedTextBlock {
  const RecognizedTextBlock({
    required this.rawText,
    this.confidence,
  });

  final String rawText;

  /// Optional engine confidence in `0.0`–`1.0` when available.
  final double? confidence;
}
