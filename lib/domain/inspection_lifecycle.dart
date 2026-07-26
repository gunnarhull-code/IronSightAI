import 'entities/inspection.dart';
import 'entities/inspection_status.dart';
import 'exceptions/invalid_inspection_lifecycle_exception.dart';

/// Validates local inspection lifecycle transitions.
///
/// Kept framework-agnostic so domain tests can cover rules without persistence.
class InspectionLifecycle {
  const InspectionLifecycle._();

  /// Completing an inspection is only valid from an active in-progress draft.
  static void ensureCanComplete(Inspection inspection) {
    if (inspection.isDiscarded) {
      throw const InvalidInspectionLifecycleException(
        'Cannot complete a discarded inspection.',
      );
    }
    if (inspection.completionStatus == InspectionCompletionStatus.completed) {
      throw const InvalidInspectionLifecycleException(
        'Inspection is already completed.',
      );
    }
  }

  /// Discard is only valid for incomplete, active inspections.
  static void ensureCanDiscard(Inspection inspection) {
    if (inspection.isDiscarded) {
      throw const InvalidInspectionLifecycleException(
        'Inspection is already discarded.',
      );
    }
    if (inspection.completionStatus == InspectionCompletionStatus.completed) {
      throw const InvalidInspectionLifecycleException(
        'Cannot discard a completed inspection.',
      );
    }
  }

  /// Metadata / rating / detailed-response edits require an active inspection.
  static void ensureCanMutate(Inspection inspection) {
    if (inspection.isDiscarded) {
      throw const InvalidInspectionLifecycleException(
        'Cannot modify a discarded inspection.',
      );
    }
    if (inspection.completionStatus == InspectionCompletionStatus.completed) {
      throw const InvalidInspectionLifecycleException(
        'Cannot modify a completed inspection.',
      );
    }
  }

  /// Reopening a completed or discarded inspection is not supported in this sprint.
  static void ensureCanReopen(Inspection inspection) {
    throw InvalidInspectionLifecycleException(
      'Cannot reopen inspection in lifecycle '
      '${inspection.localLifecycle.storageValue}/'
      '${inspection.completionStatus.storageValue}.',
    );
  }
}
