import '../entities/condition_rating.dart';
import '../entities/detailed_category_response.dart';
import '../entities/guided_quick_appraisal_step.dart';
import '../entities/inspection.dart';
import '../entities/inspection_depth.dart';
import '../entities/inspection_machine_source.dart';
import '../entities/inspection_status.dart';
import '../entities/scorecard_category.dart';
import '../equipment_id_capture/confirmed_equipment_id_value.dart';
import '../equipment_id_capture/equipment_id_capture_kind.dart';

/// Local persistence boundary for offline inspections.
///
/// Implementations use on-device encrypted SQLite as the source of truth during
/// capture. Every read/write is company-scoped. This contract must not depend
/// on Supabase connectivity.
abstract class LocalInspectionRepository {
  /// Creates a draft inspection with all scorecard categories set to
  /// [ConditionRating.notAssessed].
  ///
  /// Prefer [createGuidedDraft] for Quick Appraisal intake. This method remains
  /// for legacy callers and creates an existing-equipment-style draft.
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  });

  /// Creates a guided Quick Appraisal draft.
  ///
  /// New-machine drafts leave [Inspection.equipmentId] null until completion.
  /// Existing-equipment drafts require a non-empty [equipmentId].
  Future<Inspection> createGuidedDraft({
    required String companyId,
    required String createdByUserId,
    required InspectionMachineSource machineSource,
    String? equipmentId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  });

  /// Returns one inspection for [companyId], or `null` when missing / wrong tenant.
  Future<Inspection?> getById({
    required String companyId,
    required String inspectionId,
  });

  /// Lists non-discarded inspections for [companyId], newest first.
  ///
  /// When [includeDiscarded] is true, discarded drafts are included.
  Future<List<Inspection>> listForCompany(
    String companyId, {
    bool includeDiscarded = false,
  });

  /// Updates mutable metadata on an active in-progress inspection.
  Future<Inspection> updateMetadata({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionDepth? depth,
    String? overallNotes,
    bool clearOverallNotes = false,
    String? remoteId,
    bool clearRemoteId = false,
    InspectionSyncStatus? syncStatus,
    InspectionReportStatus? reportStatus,
  });

  /// Persists guided machine-source / pending identity / linked equipment.
  Future<Inspection> updateGuidedIntake({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionMachineSource? machineSource,
    String? equipmentId,
    bool clearEquipmentId = false,
    String? pendingAssetName,
    String? pendingManufacturer,
    String? pendingModel,
    bool clearPendingIdentity = false,
    GuidedQuickAppraisalStep? guidedStep,
    String? pendingEquipmentId,
  });

  /// Sets or changes one Quick Condition Scorecard category rating.
  Future<Inspection> saveCategoryRating({
    required String companyId,
    required String inspectionId,
    required ScorecardCategory category,
    required ConditionRating rating,
    String? updatedByUserId,
  });

  /// Replaces the detailed-inspection item responses for one category.
  Future<Inspection> saveDetailedCategoryResponse({
    required String companyId,
    required String inspectionId,
    required DetailedCategoryResponse response,
    String? updatedByUserId,
  });

  /// Soft-discards an incomplete inspection. Completed inspections cannot be discarded.
  Future<Inspection> discardIncomplete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Marks an active in-progress inspection completed locally (offline-safe).
  ///
  /// For New-machine guided drafts use
  /// [completeGuidedNewMachine] so Equipment is created atomically.
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Atomically creates local Equipment and completes a New-machine draft.
  ///
  /// Idempotent: retrying after success returns the already-completed
  /// inspection without creating a duplicate Equipment row.
  Future<Inspection> completeGuidedNewMachine({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Completes an Existing-equipment guided draft without modifying Equipment.
  Future<Inspection> completeGuidedExistingEquipment({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Persists an explicitly confirmed serial or hour-meter value on a draft.
  ///
  /// OCR output must never reach this method without prior human confirmation.
  Future<Inspection> saveConfirmedEquipmentId({
    required String companyId,
    required String inspectionId,
    required ConfirmedEquipmentIdValue confirmedValue,
    String? updatedByUserId,
  });

  /// Marks serial as explicitly unable to verify (clears any prior value).
  Future<Inspection> markSerialUnableToVerify({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Marks hours as explicitly unavailable / not displayed.
  Future<Inspection> markHoursUnavailable({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });

  /// Switches a New-machine draft onto an Existing equipment record.
  Future<Inspection> switchGuidedDraftToExistingEquipment({
    required String companyId,
    required String inspectionId,
    required String equipmentId,
    String? updatedByUserId,
  });
}

/// Thrown when New-machine completion finds a same-company serial collision.
class DuplicateLocalEquipmentSerialException implements Exception {
  DuplicateLocalEquipmentSerialException({
    required this.existingEquipmentId,
    required this.serialNumber,
  });

  final String existingEquipmentId;
  final String serialNumber;

  @override
  String toString() =>
      'DuplicateLocalEquipmentSerialException($serialNumber → $existingEquipmentId)';
}

/// Thrown when guided completion requirements are not met.
class GuidedQuickAppraisalIncompleteException implements Exception {
  GuidedQuickAppraisalIncompleteException(this.message);

  final String message;

  @override
  String toString() => 'GuidedQuickAppraisalIncompleteException: $message';
}

/// Convenience re-export for callers matching on capture kind during saves.
typedef GuidedEquipmentIdKind = EquipmentIdCaptureKind;
