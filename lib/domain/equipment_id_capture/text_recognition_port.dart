import 'captured_image.dart';
import 'recognized_text_block.dart';

/// Application-owned on-device text recognition port.
///
/// Implementations must stay offline and must not leak vendor OCR types into
/// domain entities.
abstract class TextRecognitionPort {
  bool get isSupported;

  /// Recognizes text in [image] entirely on-device.
  Future<List<RecognizedTextBlock>> recognize(CapturedImage image);

  /// Releases native OCR resources when the host no longer needs them.
  Future<void> dispose();
}
