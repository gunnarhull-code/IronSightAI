import '../entities/inspection.dart';
import '../equipment_id_capture/confirmed_equipment_id_value.dart';
import '../equipment_id_capture/equipment_id_capture_kind.dart';
import '../equipment_id_capture/equipment_id_capture_method.dart';
import '../equipment_id_capture/hour_meter_parser.dart';
import '../repositories/local_inspection_repository.dart';
import 'ai_suggestion.dart';
import 'ai_suggestion_kind.dart';

// Public constructor names (`inspections`) are kept for call sites.
// ignore_for_file: prefer_initializing_formals

enum AiApplyStatus { applied, dismissed, needsReplaceConfirmation, rejected }

class AiApplyOutcome {
  const AiApplyOutcome({
    required this.status,
    required this.suggestion,
    this.inspection,
    this.message,
  });

  final AiApplyStatus status;
  final AiSuggestion suggestion;
  final Inspection? inspection;
  final String? message;
}

/// Applies, edits, or dismisses individual AI suggestions.
///
/// Never writes inspection data unless the caller requested an explicit apply.
/// Existing confirmed serial/hour values are preserved unless [replaceExisting]
/// is true.
class AiSuggestionApplier {
  AiSuggestionApplier({
    required LocalInspectionRepository inspections,
    HourMeterParser hoursParser = const HourMeterParser(),
  }) : _inspections = inspections,
       _hours = hoursParser;

  final LocalInspectionRepository _inspections;
  final HourMeterParser _hours;

  static const String identityNotePrefix = 'AI suggestion (reviewed)';
  static const String conditionNotePrefix = 'AI visible-condition note';

  Future<AiApplyOutcome> dismiss(AiSuggestion suggestion) async {
    return AiApplyOutcome(
      status: AiApplyStatus.dismissed,
      suggestion: suggestion.copyWith(decision: AiSuggestionDecision.dismissed),
    );
  }

  Future<AiApplyOutcome> apply({
    required String companyId,
    required String inspectionId,
    required String userId,
    required Inspection inspection,
    required AiSuggestion suggestion,
    bool replaceExisting = false,
    String? editedValue,
  }) async {
    if (inspection.companyId != companyId || inspection.id != inspectionId) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion: suggestion,
        message: 'This suggestion does not belong to the open inspection.',
      );
    }

    final working = suggestion.copyWith(
      editedValue: editedValue,
      decision: AiSuggestionDecision.pending,
    );
    final text = working.displayValue;

    if (working.kind == AiSuggestionKind.serialNumber) {
      return _applySerial(
        companyId: companyId,
        inspectionId: inspectionId,
        userId: userId,
        inspection: inspection,
        suggestion: working,
        text: text,
        replaceExisting: replaceExisting,
      );
    }
    if (working.kind == AiSuggestionKind.hourMeter) {
      return _applyHours(
        companyId: companyId,
        inspectionId: inspectionId,
        userId: userId,
        inspection: inspection,
        suggestion: working,
        text: text,
        replaceExisting: replaceExisting,
      );
    }

    if (text.isEmpty) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion: working,
        message: 'This suggestion has no value to apply.',
      );
    }

    final noteLine = _noteLine(working, text);
    final nextNotes = appendNote(inspection.overallNotes, noteLine);
    final updated = await _inspections.updateMetadata(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: userId,
      overallNotes: nextNotes,
    );
    return AiApplyOutcome(
      status: AiApplyStatus.applied,
      suggestion: working.copyWith(decision: AiSuggestionDecision.applied),
      inspection: updated,
    );
  }

  Future<AiApplyOutcome> _applySerial({
    required String companyId,
    required String inspectionId,
    required String userId,
    required Inspection inspection,
    required AiSuggestion suggestion,
    required String text,
    required bool replaceExisting,
  }) async {
    if (text.isEmpty) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion: suggestion,
        message:
            'Serial is unreadable. Missing characters were not invented. '
            'Enter the value manually if you can read it.',
      );
    }
    final existing = inspection.serialNumber;
    if (existing != null &&
        existing.isNotEmpty &&
        existing != text &&
        !replaceExisting) {
      return AiApplyOutcome(
        status: AiApplyStatus.needsReplaceConfirmation,
        suggestion: suggestion,
        inspection: inspection,
        message:
            'A confirmed serial is already saved. Apply only if you want to '
            'replace it.',
      );
    }
    final updated = await _inspections.saveConfirmedEquipmentId(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: userId,
      confirmedValue: ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: text,
        method: EquipmentIdCaptureMethod.manual,
      ),
    );
    return AiApplyOutcome(
      status: AiApplyStatus.applied,
      suggestion: suggestion.copyWith(decision: AiSuggestionDecision.applied),
      inspection: updated,
    );
  }

  Future<AiApplyOutcome> _applyHours({
    required String companyId,
    required String inspectionId,
    required String userId,
    required Inspection inspection,
    required AiSuggestion suggestion,
    required String text,
    required bool replaceExisting,
  }) async {
    final hours = suggestion.hourMeterHours ?? _hours.parse(text);
    if (hours == null) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion: suggestion,
        message:
            'Hour-meter digits are incomplete or uncertain. Missing digits '
            'were not invented. Enter the reading manually if you can see it.',
      );
    }
    final existing = inspection.hourMeterReading;
    if (existing != null && existing != hours && !replaceExisting) {
      return AiApplyOutcome(
        status: AiApplyStatus.needsReplaceConfirmation,
        suggestion: suggestion,
        inspection: inspection,
        message:
            'A confirmed hour-meter reading is already saved. Apply only if '
            'you want to replace it.',
      );
    }
    final updated = await _inspections.saveConfirmedEquipmentId(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: userId,
      confirmedValue: ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.hourMeter,
        value: _hours.formatHours(hours),
        method: EquipmentIdCaptureMethod.manual,
        hours: hours,
      ),
    );
    return AiApplyOutcome(
      status: AiApplyStatus.applied,
      suggestion: suggestion.copyWith(decision: AiSuggestionDecision.applied),
      inspection: updated,
    );
  }

  static String _noteLine(AiSuggestion suggestion, String text) {
    final prefix = suggestion.kind.isIdentity
        ? identityNotePrefix
        : conditionNotePrefix;
    return '$prefix — ${suggestion.kind.displayLabel}: $text';
  }

  static String appendNote(String? existing, String addition) {
    final current = existing?.trim() ?? '';
    if (current.isEmpty) return addition;
    return '$current\n$addition';
  }
}
