import 'category_rating.dart';
import 'condition_rating.dart';
import 'detailed_category_response.dart';
import 'inspection_depth.dart';
import 'inspection_status.dart';
import 'scorecard_category.dart';

/// Local-first inspection aggregate — source of truth on device during capture.
///
/// Flutter business logic depends on this model and [LocalInspectionRepository],
/// never on Supabase directly. Sync identity/state is optional and never
/// required for offline capture.
class Inspection {
  const Inspection({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    required this.createdByUserId,
    required this.completionStatus,
    required this.localLifecycle,
    required this.depth,
    required this.syncStatus,
    required this.reportStatus,
    required this.categoryRatings,
    required this.createdAt,
    required this.updatedAt,
    required this.localUpdatedAt,
    this.updatedByUserId,
    this.remoteId,
    this.overallNotes,
    this.detailedResponses = const {},
    this.completedAt,
    this.discardedAt,
  });

  final String id;
  final String companyId;
  final String equipmentId;
  final String createdByUserId;
  final String? updatedByUserId;
  final InspectionCompletionStatus completionStatus;
  final InspectionLocalLifecycle localLifecycle;
  final InspectionDepth depth;
  final InspectionSyncStatus syncStatus;
  final InspectionReportStatus reportStatus;

  /// Optional server-side identity once synchronization exists.
  final String? remoteId;
  final String? overallNotes;
  final List<CategoryRating> categoryRatings;
  final Map<ScorecardCategory, DetailedCategoryResponse> detailedResponses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime localUpdatedAt;
  final DateTime? completedAt;
  final DateTime? discardedAt;

  bool get isDiscarded => localLifecycle == InspectionLocalLifecycle.discarded;

  bool get isIncomplete =>
      completionStatus == InspectionCompletionStatus.inProgress;

  bool get canDiscard =>
      localLifecycle == InspectionLocalLifecycle.active && isIncomplete;

  ConditionRating ratingFor(ScorecardCategory category) {
    for (final rating in categoryRatings) {
      if (rating.category == category) return rating.rating;
    }
    return ConditionRating.notAssessed;
  }

  DetailedCategoryResponse detailedFor(ScorecardCategory category) {
    return detailedResponses[category] ??
        DetailedCategoryResponse(category: category);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'equipment_id': equipmentId,
      'created_by': createdByUserId,
      'updated_by': updatedByUserId,
      'completion_status': completionStatus.storageValue,
      'local_lifecycle': localLifecycle.storageValue,
      'depth': depth.storageValue,
      'sync_status': syncStatus.storageValue,
      'report_status': reportStatus.storageValue,
      'remote_id': remoteId,
      'overall_notes': overallNotes,
      'category_ratings': categoryRatings
          .map((rating) => rating.toMap())
          .toList(growable: false),
      'detailed_responses': detailedResponses.values
          .map((response) => response.toMap())
          .toList(growable: false),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'local_updated_at': localUpdatedAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'discarded_at': discardedAt?.toUtc().toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    final rawRatings = map['category_ratings'] as List<dynamic>? ?? const [];
    final rawDetailed = map['detailed_responses'] as List<dynamic>? ?? const [];
    final detailed = <ScorecardCategory, DetailedCategoryResponse>{};
    for (final entry in rawDetailed) {
      final response = DetailedCategoryResponse.fromMap(
        Map<String, dynamic>.from(entry as Map),
      );
      detailed[response.category] = response;
    }

    return Inspection(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      equipmentId: map['equipment_id'] as String,
      createdByUserId: map['created_by'] as String,
      updatedByUserId: map['updated_by'] as String?,
      completionStatus: InspectionCompletionStatus.fromStorage(
        map['completion_status'] as String,
      ),
      localLifecycle: InspectionLocalLifecycle.fromStorage(
        map['local_lifecycle'] as String,
      ),
      depth: InspectionDepth.fromStorage(map['depth'] as String),
      syncStatus: InspectionSyncStatus.fromStorage(map['sync_status'] as String),
      reportStatus:
          InspectionReportStatus.fromStorage(map['report_status'] as String),
      remoteId: map['remote_id'] as String?,
      overallNotes: map['overall_notes'] as String?,
      categoryRatings: rawRatings
          .map(
            (rating) => CategoryRating.fromMap(
              Map<String, dynamic>.from(rating as Map),
            ),
          )
          .toList(growable: false),
      detailedResponses: detailed,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
      localUpdatedAt: DateTime.parse(map['local_updated_at'] as String).toUtc(),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String).toUtc(),
      discardedAt: map['discarded_at'] == null
          ? null
          : DateTime.parse(map['discarded_at'] as String).toUtc(),
    );
  }

  Inspection copyWith({
    String? updatedByUserId,
    InspectionCompletionStatus? completionStatus,
    InspectionLocalLifecycle? localLifecycle,
    InspectionDepth? depth,
    InspectionSyncStatus? syncStatus,
    InspectionReportStatus? reportStatus,
    String? remoteId,
    String? overallNotes,
    List<CategoryRating>? categoryRatings,
    Map<ScorecardCategory, DetailedCategoryResponse>? detailedResponses,
    DateTime? updatedAt,
    DateTime? localUpdatedAt,
    DateTime? completedAt,
    DateTime? discardedAt,
    bool clearRemoteId = false,
    bool clearOverallNotes = false,
    bool clearCompletedAt = false,
    bool clearDiscardedAt = false,
    bool clearUpdatedByUserId = false,
  }) {
    return Inspection(
      id: id,
      companyId: companyId,
      equipmentId: equipmentId,
      createdByUserId: createdByUserId,
      updatedByUserId: clearUpdatedByUserId
          ? null
          : (updatedByUserId ?? this.updatedByUserId),
      completionStatus: completionStatus ?? this.completionStatus,
      localLifecycle: localLifecycle ?? this.localLifecycle,
      depth: depth ?? this.depth,
      syncStatus: syncStatus ?? this.syncStatus,
      reportStatus: reportStatus ?? this.reportStatus,
      remoteId: clearRemoteId ? null : (remoteId ?? this.remoteId),
      overallNotes:
          clearOverallNotes ? null : (overallNotes ?? this.overallNotes),
      categoryRatings: categoryRatings ?? this.categoryRatings,
      detailedResponses: detailedResponses ?? this.detailedResponses,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      discardedAt:
          clearDiscardedAt ? null : (discardedAt ?? this.discardedAt),
    );
  }
}
