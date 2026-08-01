/// Conservative hour-meter parsing for OCR and manual entry.
///
/// Does not invent digits, does not auto-correct ambiguous OCR (O/0, I/1),
/// and rejects negatives.
class HourMeterParser {
  const HourMeterParser();

  static final RegExp _candidatePattern = RegExp(
    r'(?<![A-Za-z0-9])(\d{1,3}(?:,\d{3})+|\d+)(?:[.,](\d+))?(?![A-Za-z0-9])',
  );

  /// Parses a single user-entered or selected hour value.
  ///
  /// Returns `null` when the text is empty, negative, or not a clear number.
  double? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(RegExp(r'[A-Za-z]'))) return null;
    if (trimmed.startsWith('-')) return null;

    final match = RegExp(
      r'^(\d{1,3}(?:,\d{3})+|\d+)(?:[.,](\d+))?$',
    ).firstMatch(trimmed);
    if (match == null) return null;

    return _toDouble(match.group(1)!, match.group(2));
  }

  /// Extracts unique hour candidates from raw OCR texts conservatively.
  List<HourMeterParseResult> candidatesFromRawTexts(Iterable<String> rawTexts) {
    final seen = <String>{};
    final out = <HourMeterParseResult>[];

    for (final raw in rawTexts) {
      final cleaned = raw
          .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleaned.isEmpty) continue;
      if (cleaned.contains('-') && RegExp(r'-\s*\d').hasMatch(cleaned)) {
        // Negative hour readings are never valid candidates.
        continue;
      }

      for (final match in _candidatePattern.allMatches(cleaned)) {
        final whole = match.group(0)!;
        if (whole.startsWith('-')) continue;
        final hours = _toDouble(match.group(1)!, match.group(2));
        if (hours == null || hours < 0) continue;
        final display = formatHours(hours);
        if (seen.add(display)) {
          out.add(
            HourMeterParseResult(
              displayValue: display,
              hours: hours,
              sourceRawText: raw,
            ),
          );
        }
      }
    }
    return out;
  }

  String formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return hours.round().toString();
    }
    // Preserve fractional precision without inventing trailing zeros.
    var text = hours.toString();
    if (text.contains('.') && text.endsWith('0')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) {
        text = text.substring(0, text.length - 1);
      }
    }
    return text;
  }

  double? _toDouble(String integerPart, String? fractionPart) {
    final whole = integerPart.replaceAll(',', '');
    if (whole.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(whole)) return null;
    if (fractionPart != null && !RegExp(r'^\d+$').hasMatch(fractionPart)) {
      return null;
    }
    final value = fractionPart == null ? whole : '$whole.$fractionPart';
    return double.tryParse(value);
  }
}

class HourMeterParseResult {
  const HourMeterParseResult({
    required this.displayValue,
    required this.hours,
    this.sourceRawText,
  });

  final String displayValue;
  final double hours;
  final String? sourceRawText;
}
