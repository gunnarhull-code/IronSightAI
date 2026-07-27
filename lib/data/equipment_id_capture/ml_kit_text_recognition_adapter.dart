import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/equipment_id_capture/captured_image.dart';
import '../../domain/equipment_id_capture/recognized_text_block.dart';
import '../../domain/equipment_id_capture/text_recognition_port.dart';

/// On-device ML Kit text recognition adapter (Android / iOS).
///
/// Keeps vendor types inside the data layer — domain only sees
/// [RecognizedTextBlock]. Performs no network I/O.
class MlKitTextRecognitionAdapter implements TextRecognitionPort {
  MlKitTextRecognitionAdapter({TextRecognizer? recognizer})
    : _recognizer = recognizer ?? TextRecognizer();

  final TextRecognizer _recognizer;

  @override
  bool get isSupported => true;

  @override
  Future<List<RecognizedTextBlock>> recognize(CapturedImage image) async {
    final input = await _toInputImage(image);
    final recognized = await _recognizer.processImage(input);
    return [
      for (final block in recognized.blocks)
        RecognizedTextBlock(rawText: block.text),
      for (final block in recognized.blocks)
        for (final line in block.lines)
          RecognizedTextBlock(rawText: line.text),
    ];
  }

  Future<InputImage> _toInputImage(CapturedImage image) async {
    final path = image.path;
    if (path != null && path.isNotEmpty) {
      return InputImage.fromFilePath(path);
    }
    if (image.bytes.isEmpty) {
      throw StateError('Captured image has no bytes or path for OCR.');
    }
    // ML Kit is most reliable with a file path; persist bytes to a temp file.
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'ironsight_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(image.bytes, flush: true);
    return InputImage.fromFilePath(file.path);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
