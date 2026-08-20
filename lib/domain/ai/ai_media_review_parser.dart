import '../equipment_id_capture/ambiguous_serial_characters.dart';
import '../equipment_id_capture/hour_meter_parser.dart';
import '../equipment_id_capture/serial_normalizer.dart';
import 'ai_media_review_failure.dart';
import 'ai_media_review_result.dart';
import 'ai_media_source.dart';
import 'ai_suggestion.dart';
import 'ai_suggestion_kind.dart';

/// Parses and validates a provider-agnostic AI media review JSON payload.
///
/// Drops invented serial characters and hour digits rather than guessing.
abstract final class AiMediaReviewParser {
  static const int maxSuggestions = 40;
  static const int maxValueLength = 500;
  static const int maxUncertaintyLength = 400;

  static const SerialNormalizer _serials = SerialNormalizer();
  static const HourMeterParser _hours = HourMeterParser();

  static final RegExp _missingDigitPlaceholder = RegExp(r'[?*Xx]|_{2,}');
  static final RegExp _inventedLanguage = RegExp(
    r'\b(guess(?:ed)?|invent(?:ed)?|assum(?:e|ed)|fill(?:ed)? in|missing digit)\b',
    caseSensitive: false,
  );

  static AiMediaReviewResult parse(Object? raw) {
    final map = _asObject(raw);
    final suggestionsRaw = map['suggestions'];
    if (suggestionsRaw is! List) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    if (suggestionsRaw.length > maxSuggestions) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }

    final suggestions = <AiSuggestion>[];
    for (var i = 0; i < suggestionsRaw.length; i++) {
      final item = suggestionsRaw[i];
      if (item is! Map) {
        throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
      }
      suggestions.add(
        _parseSuggestion(Map<String, dynamic>.from(item), fallbackId: 'ai-$i'),
      );
    }

    final disclaimer = _optionalString(map['disclaimer']);
    final reviewKind = _optionalString(map['review_kind'] ?? map['reviewKind']);

    return AiMediaReviewResult(
      suggestions: List<AiSuggestion>.unmodifiable(suggestions),
      disclaimer: (disclaimer == null || disclaimer.isEmpty)
          ? AiMediaReviewResult.defaultDisclaimer
          : disclaimer,
      reviewKind: (reviewKind == null || reviewKind.isEmpty)
          ? AiMediaReviewResult.frameBasedReviewKind
          : reviewKind,
    );
  }

  static AiSuggestion _parseSuggestion(
    Map<String, dynamic> map, {
    required String fallbackId,
  }) {
    final kind = _parseKind(map['kind'] ?? map['type']);
    final confidence = _parseConfidence(map['confidence']);
    final sourceRaw = map['source'];
    if (sourceRaw is! Map) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    AiMediaSource source;
    try {
      source = AiMediaSource.fromMap(Map<String, dynamic>.from(sourceRaw));
    } on FormatException {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    final uncertainty = _clip(
      _optionalString(map['uncertainty'] ?? map['uncertainty_explanation']),
      maxUncertaintyLength,
    );
    final rawValue = _clip(_optionalString(map['value']), maxValueLength);
    final id = _optionalString(map['id']) ?? fallbackId;

    var value = rawValue;
    var hours = (map['hours'] as num?)?.toDouble();
    var ambiguous = false;

    if (kind == AiSuggestionKind.serialNumber) {
      final sanitized = _sanitizeSerial(rawValue, uncertainty);
      value = sanitized.value;
      ambiguous = sanitized.ambiguous;
    } else if (kind == AiSuggestionKind.hourMeter) {
      final sanitized = _sanitizeHours(rawValue, hours, uncertainty);
      value = sanitized.display;
      hours = sanitized.hours;
    } else if (kind == AiSuggestionKind.unreadableOrUncertain) {
      // Keep the observation text; never promote it to identity fields.
      hours = null;
    } else {
      hours = null;
    }

    return AiSuggestion(
      id: id,
      kind: kind,
      confidence: confidence,
      source: source,
      value: value,
      uncertainty: uncertainty,
      hasAmbiguousSerialCharacters: ambiguous,
      hourMeterHours: hours,
    );
  }

  static AiSuggestionKind _parseKind(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    try {
      return AiSuggestionKind.fromStorage(raw.trim());
    } on FormatException {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
  }

  static AiSuggestionConfidence _parseConfidence(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    try {
      return AiSuggestionConfidence.fromStorage(raw.trim());
    } on FormatException {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
  }

  static ({String? value, bool ambiguous}) _sanitizeSerial(
    String? raw,
    String? uncertainty,
  ) {
    if (raw == null || raw.trim().isEmpty) {
      return (value: null, ambiguous: false);
    }
    if (_missingDigitPlaceholder.hasMatch(raw) || _looksInvented(uncertainty)) {
      // Preserve whatever was actually readable; never fill placeholders.
      final preserved = _serials.normalizeForStorage(
        raw.replaceAll(RegExp(r'[?*]'), ''),
      );
      if (preserved.isEmpty || _missingDigitPlaceholder.hasMatch(preserved)) {
        return (value: null, ambiguous: false);
      }
      return (
        value: AmbiguousSerialCharacters.preserveAsRead(preserved),
        ambiguous: AmbiguousSerialCharacters.hasAmbiguousCharacters(preserved),
      );
    }
    final normalized = _serials.normalizeForStorage(raw);
    if (normalized.isEmpty) return (value: null, ambiguous: false);
    final preserved = AmbiguousSerialCharacters.preserveAsRead(normalized);
    return (
      value: preserved,
      ambiguous: AmbiguousSerialCharacters.hasAmbiguousCharacters(preserved),
    );
  }

  static ({String? display, double? hours}) _sanitizeHours(
    String? raw,
    double? providedHours,
    String? uncertainty,
  ) {
    if (_looksInvented(uncertainty) ||
        (raw != null && _missingDigitPlaceholder.hasMatch(raw))) {
      return (display: null, hours: null);
    }
    final parsedFromText = raw == null ? null : _hours.parse(raw);
    if (parsedFromText != null) {
      return (
        display: _hours.formatHours(parsedFromText),
        hours: parsedFromText,
      );
    }
    if (providedHours != null && providedHours >= 0 && raw == null) {
      // Numeric-only payload with no text is acceptable when digits are complete.
      return (display: _hours.formatHours(providedHours), hours: providedHours);
    }
    // Incomplete or letter-mixed hour text is never coerced into a reading.
    return (display: null, hours: null);
  }

  static bool _looksInvented(String? uncertainty) {
    if (uncertainty == null || uncertainty.trim().isEmpty) return false;
    return _inventedLanguage.hasMatch(uncertainty);
  }

  static Map<String, dynamic> _asObject(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
  }

  static String? _optionalString(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) {
      throw AiMediaReviewException(AiMediaReviewFailure.malformedResponse());
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _clip(String? value, int max) {
    if (value == null) return null;
    if (value.length <= max) return value;
    return value.substring(0, max);
  }
}
