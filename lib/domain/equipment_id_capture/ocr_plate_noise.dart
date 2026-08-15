/// Shared heuristics for rejecting unrelated equipment-plate OCR text.
///
/// Used by serial and hour-meter extractors. Never invents missing characters.
abstract final class OcrPlateNoise {
  static final RegExp unitOrMeasure = RegExp(
    r'(?:^|[^A-Za-z])(kg|kgs|lb|lbs|psi|kpa|bar|mm|cm|inch|in|ton|tons|kn|kN)(?:[^A-Za-z]|$)',
    caseSensitive: false,
  );

  static final RegExp descriptiveWord = RegExp(
    r'\b(warning|caution|danger|keep|inflat(?:e|ion)?|pressure|tyre|tire|'
    r'capacity|cap|weight|mast|dimension|height|width|length|load|'
    r'centre|center|production|date|manufactured|mfg|type|rated|'
    r'instruction|notice)\b',
    caseSensitive: false,
  );

  static final RegExp datePattern = RegExp(
    r'(?:\b(?:19|20)\d{2}\b|\b\d{1,2}[/-]\d{1,2}[/-](?:\d{2}|\d{4})\b|'
    r'\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+'
    r'(?:19|20)\d{2}\b)',
    caseSensitive: false,
  );

  static final RegExp yearOnly = RegExp(r'^(?:19|20)\d{2}$');

  /// Short all-letter plate words that are never serials or hour readings.
  static const Set<String> plateWords = {
    'ht',
    'kg',
    'kgs',
    'lb',
    'lbs',
    'mm',
    'cm',
    'psi',
    'kpa',
    'bar',
    'mast',
    'tyre',
    'tire',
    'type',
    'load',
    'cap',
    'date',
    'prod',
    'no',
    'num',
    'serial',
    'model',
    'hours',
    'hour',
    'hrs',
    'hr',
  };

  static String contextWindow(
    String haystack,
    String needle, {
    int radius = 28,
  }) {
    final index = haystack.toLowerCase().indexOf(needle.toLowerCase());
    if (index < 0) return haystack;
    final start = index - radius < 0 ? 0 : index - radius;
    final end = index + needle.length + radius > haystack.length
        ? haystack.length
        : index + needle.length + radius;
    return haystack.substring(start, end);
  }

  static bool looksLikeSentence(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length >= 4) return true;
    return descriptiveWord.hasMatch(text) && words.length >= 3;
  }

  static bool hasMeasureOrUnit(String text) => unitOrMeasure.hasMatch(text);

  static bool hasDateSignal(String text) {
    return datePattern.hasMatch(text) &&
        RegExp(
          r'\b(date|prod(?:uction)?|mfg|manufactured|year)\b',
          caseSensitive: false,
        ).hasMatch(text);
  }

  static bool isPlateWord(String token) =>
      plateWords.contains(token.trim().toLowerCase());
}
