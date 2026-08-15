import 'hour_meter_parser.dart';
import 'ocr_plate_noise.dart';

/// Ranked hour-meter extraction from on-device OCR text.
class HourFieldExtraction {
  const HourFieldExtraction({this.recommended, this.alternatives = const []});

  final HourMeterParseResult? recommended;
  final List<HourMeterParseResult> alternatives;

  bool get hasRecommendation => recommended != null;

  List<HourMeterParseResult> get visibleCandidates => [
    ?recommended,
    ...alternatives,
  ];
}

class HourMeterFieldExtractor {
  const HourMeterFieldExtractor({this.parser = const HourMeterParser()});

  final HourMeterParser parser;

  static const double recommendThreshold = 0.8;
  static const double alternativeThreshold = 0.55;
  static const double labelledScore = 0.95;
  static const double isolatedScore = 0.86;

  static final RegExp _hourLabel = RegExp(
    r'(?:^|[^A-Za-z0-9])(?:'
    r'hours?|hrs?|smh|hobbs|tach(?:ometer)?|hour\s*meter|'
    r'tot(?:al)?\s*hours?'
    r')[\s:.#\-]*'
    r'(\d{1,3}(?:,\d{3})+|\d+)(?:[.,](\d+))?',
    caseSensitive: false,
  );

  HourFieldExtraction extract(Iterable<String> rawTexts) {
    final texts = rawTexts
        .map((raw) => raw.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), ' '))
        .map((raw) => raw.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((raw) => raw.isNotEmpty)
        .toList(growable: false);
    if (texts.isEmpty) return const HourFieldExtraction();

    final combined = texts.join(' ');
    final scored = <String, _ScoredHour>{};

    void consider({
      required HourMeterParseResult parsed,
      required double score,
      required String source,
    }) {
      if (_isRejectedHour(parsed, source) ||
          _isRejectedHour(parsed, combined)) {
        return;
      }
      final key = parsed.displayValue;
      final existing = scored[key];
      if (existing == null || score > existing.score) {
        scored[key] = _ScoredHour(
          parsed: parsed,
          score: score,
          order: existing?.order ?? scored.length,
        );
      }
    }

    for (final text in [...texts, combined]) {
      for (final match in _hourLabel.allMatches(' $text')) {
        final whole = match.group(1)!;
        final fraction = match.group(2);
        final display = fraction == null ? whole : '$whole.$fraction';
        final hours = parser.parse(display.replaceAll(',', ''));
        if (hours == null) continue;
        consider(
          parsed: HourMeterParseResult(
            displayValue: parser.formatHours(hours),
            hours: hours,
            sourceRawText: text,
          ),
          score: labelledScore,
          source: text,
        );
      }
    }

    for (final text in texts) {
      for (final parsed in parser.candidatesFromRawTexts([text])) {
        final labelled = _hourLabel.hasMatch(' $text');
        final yearLike = OcrPlateNoise.yearOnly.hasMatch(parsed.displayValue);
        final score = labelled
            ? labelledScore
            : yearLike
            ? 0.45
            : isolatedScore;
        consider(parsed: parsed, score: score, source: text);
      }
    }

    final ranked = scored.values.toList()
      ..sort((a, b) {
        final scoreCmp = b.score.compareTo(a.score);
        if (scoreCmp != 0) return scoreCmp;
        return a.order.compareTo(b.order);
      });

    if (ranked.isEmpty) return const HourFieldExtraction();

    final best = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;
    final uniqueEnough = second == null || best.score - second.score >= 0.12;
    final labelled = best.score >= labelledScore;
    final recommend =
        (labelled || uniqueEnough) &&
        (best.score >= recommendThreshold ||
            (ranked.length == 1 && best.score >= alternativeThreshold));

    final recommended = recommend ? best.parsed : null;
    final alternatives = [
      for (final item in ranked)
        if (item.parsed.displayValue != recommended?.displayValue &&
            item.score >= alternativeThreshold)
          item.parsed,
    ];

    return HourFieldExtraction(
      recommended: recommended,
      alternatives: alternatives,
    );
  }

  bool _isRejectedHour(HourMeterParseResult parsed, String source) {
    if (parsed.hours < 0) return true;
    final window = OcrPlateNoise.contextWindow(source, parsed.displayValue);
    if (OcrPlateNoise.hasMeasureOrUnit(window)) return true;
    if (OcrPlateNoise.hasDateSignal(window) ||
        OcrPlateNoise.hasDateSignal(source)) {
      if (OcrPlateNoise.yearOnly.hasMatch(parsed.displayValue)) return true;
    }
    if (RegExp(
      r'\b(capacity|weight|load|centre|center|pressure|tyre|tire|mast)\b',
      caseSensitive: false,
    ).hasMatch(window)) {
      return true;
    }
    return false;
  }
}

class _ScoredHour {
  const _ScoredHour({
    required this.parsed,
    required this.score,
    required this.order,
  });

  final HourMeterParseResult parsed;
  final double score;
  final int order;
}
