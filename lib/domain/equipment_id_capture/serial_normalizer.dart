/// Normalizes OCR/manual serial text without inventing or correcting characters.
///
/// Preserves letters, digits, leading zeros, and meaningful separators
/// (`-`, `/`, `.`, `_`). Only whitespace and obvious formatting noise are
/// cleaned. Consecutive ASCII hyphens are collapsed to a single hyphen
/// (`ABC--123` → `ABC-123`); letters and digits are never rewritten.
class SerialNormalizer {
  const SerialNormalizer();

  /// Characters treated as meaningful serial content (kept as-is).
  static final RegExp _meaningful = RegExp(r'[A-Za-z0-9\-\./_]');

  /// Whitespace including unicode space variants.
  static final RegExp _whitespace = RegExp(
    r'[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]+',
  );

  /// Zero-width / BOM noise that OCR sometimes injects.
  static final RegExp _zeroWidth = RegExp(r'[\u200B-\u200D\uFEFF\u2060]');

  /// Device OCR sometimes doubles a printed hyphen (`ABC--123`). Consecutive
  /// ASCII hyphens are never allowed in a stored serial — collapse each run.
  static final RegExp _consecutiveAsciiHyphens = RegExp(r'-{2,}');

  /// Leading serial labels, including common OCR substitutions in the label
  /// itself (`SlNo`, `SINo`). Does not treat `SN-…` as a label — that hyphen
  /// is part of the serial.
  static final RegExp _leadingSerialLabel = RegExp(
    r'^(?:'
    r'serial(?:\s*(?:no\.?|number|num|#))?|'
    r's[\s./\\]+n(?:o\.?)?|'
    r'sn(?:o\.?)?(?=[\s:#])|'
    r'sl\s*no\.?|'
    r'si\s*no\.?'
    r')\s*[:#.\-]*\s*',
    caseSensitive: false,
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

    // Collapse OCR-doubled hyphens only. Do not invent, remove, or substitute
    // letters/digits; legitimate single hyphens (e.g. SN-0099) stay intact.
    return buffer
        .toString()
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(_consecutiveAsciiHyphens, '-')
        .trim();
  }

  /// Removes a leading serial label without inventing remaining characters.
  String stripLeadingSerialLabel(String input) {
    final trimmed = input.replaceAll(_zeroWidth, '').trim();
    if (trimmed.isEmpty) return '';
    final match = _leadingSerialLabel.firstMatch(trimmed);
    if (match == null) return trimmed;
    final rest = trimmed.substring(match.end).trim();
    return rest.isEmpty ? trimmed : rest;
  }

  /// Storage form: strip a leading label, then normalize characters.
  String normalizeForStorage(String input) {
    return normalize(stripLeadingSerialLabel(input));
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
