import 'ai_media_source.dart';
import 'ai_suggestion_kind.dart';

enum AiSuggestionDecision { pending, applied, dismissed }

/// One AI suggestion for human review. Never a verified fact.
class AiSuggestion {
  const AiSuggestion({
    required this.id,
    required this.kind,
    required this.confidence,
    required this.source,
    this.value,
    this.uncertainty,
    this.hasAmbiguousSerialCharacters = false,
    this.hourMeterHours,
    this.decision = AiSuggestionDecision.pending,
    this.editedValue,
  });

  final String id;
  final AiSuggestionKind kind;
  final AiSuggestionConfidence confidence;
  final AiMediaSource source;

  /// Suggested observation or identity value. Null when unreadable.
  final String? value;

  /// Human-readable explanation of uncertainty. Required for low confidence
  /// and unreadable items; optional otherwise.
  final String? uncertainty;

  /// Serial look-alikes (O/0, I/1, …) preserved as read — never rewritten.
  final bool hasAmbiguousSerialCharacters;

  /// Parsed hours when [kind] is hour meter and the value was conservative.
  final double? hourMeterHours;

  final AiSuggestionDecision decision;
  final String? editedValue;

  String get displayValue => (editedValue ?? value)?.trim() ?? '';

  bool get hasDisplayValue => displayValue.isNotEmpty;

  bool get isPending => decision == AiSuggestionDecision.pending;

  String get disclaimer => 'AI suggestion, not a verified fact.';

  AiSuggestion copyWith({
    AiSuggestionDecision? decision,
    String? editedValue,
    bool clearEditedValue = false,
    String? value,
    double? hourMeterHours,
    bool clearHourMeterHours = false,
    bool? hasAmbiguousSerialCharacters,
    String? uncertainty,
  }) {
    return AiSuggestion(
      id: id,
      kind: kind,
      confidence: confidence,
      source: source,
      value: value ?? this.value,
      uncertainty: uncertainty ?? this.uncertainty,
      hasAmbiguousSerialCharacters:
          hasAmbiguousSerialCharacters ?? this.hasAmbiguousSerialCharacters,
      hourMeterHours: clearHourMeterHours
          ? null
          : (hourMeterHours ?? this.hourMeterHours),
      decision: decision ?? this.decision,
      editedValue: clearEditedValue ? null : (editedValue ?? this.editedValue),
    );
  }
}
