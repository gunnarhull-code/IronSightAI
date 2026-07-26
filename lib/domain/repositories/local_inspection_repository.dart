import '../entities/condition_rating.dart';
import '../entities/detailed_category_response.dart';
import '../entities/inspection.dart';
import '../entities/inspection_depth.dart';
import '../entities/inspection_status.dart';
import '../entities/scorecard_category.dart';

/// Local persistence boundary for offline inspections.
///
/// Implementations use on-device encrypted SQLite as the source of truth during
/// capture. Every read/write is company-scoped. This contract must not depend
/// on Supabase connectivity.
abstract class LocalInspectionRepository {
  /// Creates a draft inspection with all scorecard categories set to
  /// [ConditionRating.notAssessed].
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
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
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  });
}
