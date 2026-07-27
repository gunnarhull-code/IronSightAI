/// A still image captured for offline OCR.
///
/// Domain code never depends on camera package types — only bytes + metadata.
class CapturedImage {
  const CapturedImage({
    required this.bytes,
    this.path,
    this.mimeType = 'image/jpeg',
  });

  final List<int> bytes;
  final String? path;
  final String mimeType;

  bool get isEmpty => bytes.isEmpty;
}
