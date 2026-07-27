/// Normalizes OCR/manual serial text without inventing or correcting characters.
///
/// Preserves letters, digits, leading zeros, and meaningful separators
/// (`-`, `/`, `.`, `_`). Only whitespace and obvious formatting noise are
/// cleaned.
class SerialNormalizer {
  const SerialNormalizer();

  /// Characters treated as meaningful serial content (kept as-is).
  static final RegExp _meaningful = RegExp(r'[A-Za-z0-9\-\./_]');

  /// Whitespace including unicode space variants.
  static final RegExp _whitespace = RegExp(
    r'[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]+',
  );

  /// Zero-width / BOM noise that OCR sometimes injects.
  static final RegExp _zeroWidth = RegExp(
    r'[\u200B-\u200D\uFEFF\u2060]',
  );

  String normalize(String input) {
    var text = input.replaceAll(_zeroWidth, '');
    text = text.replaceAll(_whitespace, ' ').trim();
    if (text.isEmpty) return '';

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (char == ' ') {
        // Keep a single space only when it separates meaningful tokens.
        if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
          buffer.write(' ');
        }
        continue;
      }
      if (_meaningful.hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      // Drop obvious framing/noise punctuation (e.g. *, #, :, surrounding
      // quotes) without altering letters, digits, or meaningful separators.
    }

    return buffer.toString().replaceAll(RegExp(r' +'), ' ').trim();
  }

  /// Builds unique serial candidates from raw OCR blocks.
  ///
  /// Ambiguous / empty / noise-only blocks are skipped — never auto-corrected.
  List<String> candidatesFromRawTexts(Iterable<String> rawTexts) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in rawTexts) {
      final normalized = normalize(raw);
      if (normalized.isEmpty) continue;
      if (!_hasLetterOrDigit(normalized)) continue;
      if (seen.add(normalized)) {
        out.add(normalized);
      }
    }
    return out;
  }

  bool _hasLetterOrDigit(String value) {
    return RegExp(r'[A-Za-z0-9]').hasMatch(value);
  }
}
