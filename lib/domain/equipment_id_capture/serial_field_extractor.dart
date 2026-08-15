import 'ocr_plate_noise.dart';
import 'serial_normalizer.dart';

/// Ranked serial extraction from on-device OCR text.
///
/// Humans remain the authority: this never auto-selects a value. It only
/// recommends a labelled or high-confidence serial and hides plate noise.
class SerialFieldExtraction {
  const SerialFieldExtraction({this.recommended, this.alternatives = const []});

  final SerialFieldCandidate? recommended;
  final List<SerialFieldCandidate> alternatives;

  bool get hasRecommendation => recommended != null;

  List<SerialFieldCandidate> get visibleCandidates => [
    ?recommended,
    ...alternatives,
  ];
}

class SerialFieldCandidate {
  const SerialFieldCandidate({
    required this.value,
    required this.confidence,
    this.sourceRawText,
    this.labelled = false,
  });

  final String value;
  final double confidence;
  final String? sourceRawText;
  final bool labelled;
}

/// Parses and ranks OCR text for equipment serial numbers.
class SerialFieldExtractor {
  const SerialFieldExtractor({this.normalizer = const SerialNormalizer()});

  final SerialNormalizer normalizer;

  static const double recommendThreshold = 0.8;
  static const double alternativeThreshold = 0.55;
  static const double labelledScore = 0.95;
  static const double strongSerialScore = 0.86;
  static const double plausibleSerialScore = 0.68;

  static final RegExp _serialLabel = RegExp(
    r'(?:^|[^A-Za-z0-9])(?:'
    r'serial(?:\s*(?:no\.?|number|num|#))?|'
    r's[\s./\\]+n(?:o\.?)?|'
    r'sn(?:o\.?)?(?=[\s:#])|'
    r'sl\s*no\.?|'
    r'si\s*no\.?'
    r')[\s:.#\-]*'
    r'([A-Za-z0-9][A-Za-z0-9\-\./_]*)',
    caseSensitive: false,
  );

  static final RegExp _modelLabel = RegExp(
    r'(?:^|[^A-Za-z0-9])(?:'
    r'model(?:\s*(?:no\.?|number|#))?|'
    r'type(?:\s*(?:no\.?|number)?)?|'
    r'mod(?:el)?\s*#'
    r')[\s:.#\-]*'
    r'([A-Za-z0-9][A-Za-z0-9\-\./_]*)',
    caseSensitive: false,
  );

  static final RegExp _token = RegExp(r'[A-Za-z0-9][A-Za-z0-9\-\./_]*');

  static final RegExp _modelLike = RegExp(
    r'^\d{1,3}-[A-Za-z0-9]{2,8}$',
    caseSensitive: false,
  );

  SerialFieldExtraction extract(Iterable<String> rawTexts) {
    final texts = rawTexts
        .map((raw) => raw.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), ' '))
        .map((raw) => raw.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((raw) => raw.isNotEmpty)
        .toList(growable: false);
    if (texts.isEmpty) return const SerialFieldExtraction();

    final combined = texts.join(' ');
    final models = <String>{};
    final scored = <String, _ScoredSerial>{};

    void addModel(String raw) {
      final value = normalizer.normalize(raw);
      if (value.isNotEmpty) models.add(value.toUpperCase());
    }

    for (final text in [...texts, combined]) {
      for (final match in _modelLabel.allMatches(' $text')) {
        addModel(match.group(1)!);
      }
      for (final match in _serialLabel.allMatches(' $text')) {
        final before = ' $text'.substring(0, match.start);
        final preceding = _token.allMatches(before).toList();
        if (preceding.isNotEmpty) {
          addModel(preceding.last.group(0)!);
        }
      }
    }

    void consider({
      required String rawValue,
      required double score,
      required String source,
      required bool labelled,
    }) {
      final stored = normalizer.normalizeForStorage(rawValue);
      if (stored.isEmpty) return;
      if (models.contains(stored.toUpperCase())) return;
      if (_isRejectedSerial(stored, source)) return;
      if (_modelLike.hasMatch(stored) && !labelled) return;

      final key = stored.toUpperCase();
      final existing = scored[key];
      if (existing == null || score > existing.score) {
        scored[key] = _ScoredSerial(
          value: stored,
          score: score,
          source: source,
          labelled: labelled,
          order: existing?.order ?? scored.length,
        );
      } else if (labelled && !existing.labelled) {
        scored[key] = _ScoredSerial(
          value: existing.value,
          score: score,
          source: source,
          labelled: true,
          order: existing.order,
        );
      }
    }

    for (final text in [...texts, combined]) {
      for (final match in _serialLabel.allMatches(' $text')) {
        consider(
          rawValue: match.group(1)!,
          score: labelledScore,
          source: text,
          labelled: true,
        );
      }
    }

    for (final text in texts) {
      if (OcrPlateNoise.looksLikeSentence(text)) continue;
      for (final match in _token.allMatches(text)) {
        final token = match.group(0)!;
        consider(
          rawValue: token,
          score: _unlabelledScore(token),
          source: text,
          labelled: false,
        );
      }
    }

    final ranked = scored.values.toList()
      ..sort((a, b) {
        final scoreCmp = b.score.compareTo(a.score);
        if (scoreCmp != 0) return scoreCmp;
        final labelledCmp = (b.labelled ? 1 : 0).compareTo(a.labelled ? 1 : 0);
        if (labelledCmp != 0) return labelledCmp;
        return a.order.compareTo(b.order);
      });

    SerialFieldCandidate toCandidate(_ScoredSerial item) {
      return SerialFieldCandidate(
        value: item.value,
        confidence: item.score,
        sourceRawText: item.source,
        labelled: item.labelled,
      );
    }

    if (ranked.isEmpty) return const SerialFieldExtraction();

    final best = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;
    final uniqueEnough =
        second == null || best.score - second.score >= 0.15 || best.labelled;
    final recommend =
        uniqueEnough &&
        (best.labelled ||
            best.score >= recommendThreshold ||
            (ranked.length == 1 && best.score >= alternativeThreshold));

    final recommended = recommend ? toCandidate(best) : null;
    final alternatives = [
      for (final item in ranked)
        if (item.value != recommended?.value &&
            item.score >= alternativeThreshold)
          toCandidate(item),
    ];

    return SerialFieldExtraction(
      recommended: recommended,
      alternatives: alternatives,
    );
  }

  double _unlabelledScore(String token) {
    final stored = normalizer.normalizeForStorage(token);
    if (stored.isEmpty) return 0;
    if (!RegExp(r'\d').hasMatch(stored)) return 0;
    if (_modelLike.hasMatch(stored)) return 0;
    final compact = stored.replaceAll(RegExp(r'[\s\-\./_]'), '');
    final mixed =
        RegExp(r'[A-Za-z]').hasMatch(compact) &&
        RegExp(r'\d').hasMatch(compact);
    if (compact.length >= 8 && compact.length <= 16 && mixed) {
      return strongSerialScore;
    }
    if (RegExp(r'^SN[-_]', caseSensitive: false).hasMatch(stored) &&
        compact.length >= 4) {
      return plausibleSerialScore;
    }
    if (compact.length >= 6 && mixed) return plausibleSerialScore;
    if (compact.length >= 8 && RegExp(r'^\d+$').hasMatch(compact)) {
      return plausibleSerialScore;
    }
    return 0.4;
  }

  bool _isRejectedSerial(String value, String source) {
    if (OcrPlateNoise.isPlateWord(value)) return true;
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(value)) return true;
    if (!RegExp(r'\d').hasMatch(value)) return true;
    if (OcrPlateNoise.yearOnly.hasMatch(value) &&
        OcrPlateNoise.hasDateSignal(source)) {
      return true;
    }
    final window = OcrPlateNoise.contextWindow(source, value);
    if (OcrPlateNoise.hasMeasureOrUnit(window)) return true;
    if (OcrPlateNoise.descriptiveWord.hasMatch(window) &&
        !RegExp(
          r'(serial|s[\s./\\]*n)',
          caseSensitive: false,
        ).hasMatch(window)) {
      // Tire/capacity/dimension sentences around this token.
      if (OcrPlateNoise.hasMeasureOrUnit(source) ||
          OcrPlateNoise.descriptiveWord.hasMatch(source)) {
        final compact = value.replaceAll(RegExp(r'[\s\-\./_]'), '');
        final mixed =
            RegExp(r'[A-Za-z]').hasMatch(compact) &&
            RegExp(r'\d').hasMatch(compact);
        if (!mixed || compact.length < 8) return true;
      }
    }
    if (OcrPlateNoise.looksLikeSentence(value)) return true;
    return false;
  }
}

class _ScoredSerial {
  const _ScoredSerial({
    required this.value,
    required this.score,
    required this.source,
    required this.labelled,
    required this.order,
  });

  final String value;
  final double score;
  final String source;
  final bool labelled;
  final int order;
}
