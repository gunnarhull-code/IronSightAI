import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category_rating.dart';
import '../../domain/entities/condition_rating.dart';
import '../../domain/entities/detailed_category_response.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/inspection_depth.dart';
import '../../domain/entities/inspection_status.dart';
import '../../domain/entities/scorecard_category.dart';
import '../../domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_kind.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_method.dart';
import '../../domain/inspection_lifecycle.dart';
import '../../domain/inspection_value_parsing.dart';
import '../../domain/repositories/local_inspection_repository.dart';
import '../local/drift/app_database.dart';

/// Drift-backed [LocalInspectionRepository].
///
/// All queries filter by [companyId]. Domain/UI layers never import Drift.
class DriftLocalInspectionRepository implements LocalInspectionRepository {
  DriftLocalInspectionRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? const Uuid().v4;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  @override
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(equipmentId, 'equipmentId');
    _requireNonEmpty(createdByUserId, 'createdByUserId');

    final now = _clock();
    final inspectionId = _idGenerator();

    await _db.transaction(() async {
      await _db
          .into(_db.inspections)
          .insert(
            InspectionsCompanion.insert(
              id: inspectionId,
              companyId: companyId,
              equipmentId: equipmentId,
              createdByUserId: createdByUserId,
              updatedByUserId: Value(createdByUserId),
              completionStatus:
                  InspectionCompletionStatus.inProgress.storageValue,
              localLifecycle: InspectionLocalLifecycle.active.storageValue,
              depth: depth.storageValue,
              syncStatus: InspectionSyncStatus.localOnly.storageValue,
              reportStatus: InspectionReportStatus.notGenerated.storageValue,
              createdAt: now,
              updatedAt: now,
              localUpdatedAt: now,
            ),
          );

      for (final category in ScorecardCategory.scorecardOrder) {
        await _db
            .into(_db.inspectionCategoryRatings)
            .insert(
              InspectionCategoryRatingsCompanion.insert(
                id: _idGenerator(),
                inspectionId: inspectionId,
                companyId: companyId,
                category: category.storageValue,
                rating: ConditionRating.notAssessed.storageValue,
                updatedAt: now,
              ),
            );
      }
    });

    final created = await getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    return created!;
  }

  @override
  Future<Inspection?> getById({
    required String companyId,
    required String inspectionId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(inspectionId, 'inspectionId');

    final row =
        await (_db.select(_db.inspections)..where(
              (table) =>
                  table.id.equals(inspectionId) &
                  table.companyId.equals(companyId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return _assemble(row);
  }

  @override
  Future<List<Inspection>> listForCompany(
    String companyId, {
    bool includeDiscarded = false,
  }) async {
    _requireNonEmpty(companyId, 'companyId');

    final query = _db.select(_db.inspections)
      ..where((table) => table.companyId.equals(companyId))
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.updatedAt, mode: OrderingMode.desc),
      ]);

    if (!includeDiscarded) {
      query.where(
        (table) => table.localLifecycle.equals(
          InspectionLocalLifecycle.active.storageValue,
        ),
      );
    }

    final rows = await query.get();
    final inspections = <Inspection>[];
    for (final row in rows) {
      inspections.add(await _assemble(row));
    }
    return inspections;
  }

  @override
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
  }) async {
    final existing = await _requireActiveMutable(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanMutate(existing);

    final now = _clock();
    await (_db.update(_db.inspections)..where(
          (table) =>
              table.id.equals(inspectionId) & table.companyId.equals(companyId),
        ))
        .write(
          InspectionsCompanion(
            updatedByUserId: updatedByUserId == null
                ? const Value.absent()
                : Value(updatedByUserId),
            depth: depth == null
                ? const Value.absent()
                : Value(depth.storageValue),
            overallNotes: clearOverallNotes
                ? const Value(null)
                : (overallNotes == null
                      ? const Value.absent()
                      : Value(overallNotes)),
            remoteId: clearRemoteId
                ? const Value(null)
                : (remoteId == null ? const Value.absent() : Value(remoteId)),
            syncStatus: syncStatus == null
                ? const Value.absent()
                : Value(syncStatus.storageValue),
            reportStatus: reportStatus == null
                ? const Value.absent()
                : Value(reportStatus.storageValue),
            updatedAt: Value(now),
            localUpdatedAt: Value(now),
          ),
        );

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  @override
  Future<Inspection> saveCategoryRating({
    required String companyId,
    required String inspectionId,
    required ScorecardCategory category,
    required ConditionRating rating,
    String? updatedByUserId,
  }) async {
    // Round-trip through storage parsers so invalid wire values are rejected
    // even if a caller constructs an unexpected value at runtime.
    parseScorecardCategory(category.storageValue);
    parseConditionRating(rating.storageValue);

    final existing = await _requireActiveMutable(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanMutate(existing);

    final now = _clock();
    await _db.transaction(() async {
      final current =
          await (_db.select(_db.inspectionCategoryRatings)..where(
                (table) =>
                    table.inspectionId.equals(inspectionId) &
                    table.companyId.equals(companyId) &
                    table.category.equals(category.storageValue),
              ))
              .getSingleOrNull();

      if (current == null) {
        await _db
            .into(_db.inspectionCategoryRatings)
            .insert(
              InspectionCategoryRatingsCompanion.insert(
                id: _idGenerator(),
                inspectionId: inspectionId,
                companyId: companyId,
                category: category.storageValue,
                rating: rating.storageValue,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.inspectionCategoryRatings,
        )..where((table) => table.id.equals(current.id))).write(
          InspectionCategoryRatingsCompanion(
            rating: Value(rating.storageValue),
            updatedAt: Value(now),
          ),
        );
      }

      await (_db.update(_db.inspections)..where(
            (table) =>
                table.id.equals(inspectionId) &
                table.companyId.equals(companyId),
          ))
          .write(
            InspectionsCompanion(
              updatedByUserId: updatedByUserId == null
                  ? const Value.absent()
                  : Value(updatedByUserId),
              updatedAt: Value(now),
              localUpdatedAt: Value(now),
            ),
          );
    });

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  @override
  Future<Inspection> saveDetailedCategoryResponse({
    required String companyId,
    required String inspectionId,
    required DetailedCategoryResponse response,
    String? updatedByUserId,
  }) async {
    parseScorecardCategory(response.category.storageValue);
    for (final item in response.items) {
      parseConditionRating(item.rating.storageValue);
      if (item.itemKey.trim().isEmpty) {
        throw ArgumentError.value(item.itemKey, 'itemKey', 'must not be empty');
      }
    }

    final existing = await _requireActiveMutable(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanMutate(existing);

    final now = _clock();
    await _db.transaction(() async {
      await (_db.delete(_db.inspectionDetailedResponses)..where(
            (table) =>
                table.inspectionId.equals(inspectionId) &
                table.companyId.equals(companyId) &
                table.category.equals(response.category.storageValue),
          ))
          .go();

      for (final item in response.items) {
        await _db
            .into(_db.inspectionDetailedResponses)
            .insert(
              InspectionDetailedResponsesCompanion.insert(
                id: _idGenerator(),
                inspectionId: inspectionId,
                companyId: companyId,
                category: response.category.storageValue,
                itemKey: item.itemKey,
                labelSnapshot: item.labelSnapshot,
                sortOrder: item.sortOrder,
                rating: item.rating.storageValue,
                notes: Value(item.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      await (_db.update(_db.inspections)..where(
            (table) =>
                table.id.equals(inspectionId) &
                table.companyId.equals(companyId),
          ))
          .write(
            InspectionsCompanion(
              updatedByUserId: updatedByUserId == null
                  ? const Value.absent()
                  : Value(updatedByUserId),
              depth: response.items.isEmpty
                  ? const Value.absent()
                  : Value(InspectionDepth.detailed.storageValue),
              updatedAt: Value(now),
              localUpdatedAt: Value(now),
            ),
          );
    });

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  @override
  Future<Inspection> discardIncomplete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) async {
    final existing = await _requireOwned(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanDiscard(existing);

    final now = _clock();
    await (_db.update(_db.inspections)..where(
          (table) =>
              table.id.equals(inspectionId) & table.companyId.equals(companyId),
        ))
        .write(
          InspectionsCompanion(
            localLifecycle: Value(
              InspectionLocalLifecycle.discarded.storageValue,
            ),
            discardedAt: Value(now),
            updatedByUserId: updatedByUserId == null
                ? const Value.absent()
                : Value(updatedByUserId),
            updatedAt: Value(now),
            localUpdatedAt: Value(now),
          ),
        );

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  @override
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) async {
    final existing = await _requireOwned(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanComplete(existing);

    final now = _clock();
    await (_db.update(_db.inspections)..where(
          (table) =>
              table.id.equals(inspectionId) & table.companyId.equals(companyId),
        ))
        .write(
          InspectionsCompanion(
            completionStatus: Value(
              InspectionCompletionStatus.completed.storageValue,
            ),
            completedAt: Value(now),
            updatedByUserId: updatedByUserId == null
                ? const Value.absent()
                : Value(updatedByUserId),
            updatedAt: Value(now),
            localUpdatedAt: Value(now),
          ),
        );

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  @override
  Future<Inspection> saveConfirmedEquipmentId({
    required String companyId,
    required String inspectionId,
    required ConfirmedEquipmentIdValue confirmedValue,
    String? updatedByUserId,
  }) async {
    final existing = await _requireActiveMutable(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanMutate(existing);

    final now = _clock();
    final companion = switch (confirmedValue.kind) {
      EquipmentIdCaptureKind.serialNumber => InspectionsCompanion(
        serialNumber: Value(confirmedValue.value),
        serialCaptureMethod: Value(confirmedValue.method.storageValue),
        updatedByUserId: updatedByUserId == null
            ? const Value.absent()
            : Value(updatedByUserId),
        updatedAt: Value(now),
        localUpdatedAt: Value(now),
      ),
      EquipmentIdCaptureKind.hourMeter => () {
        final hours = confirmedValue.hours;
        if (hours == null || hours < 0) {
          throw ArgumentError.value(
            confirmedValue.hours,
            'confirmedValue.hours',
            'hour meter confirmation requires a non-negative hours value',
          );
        }
        return InspectionsCompanion(
          hourMeterReading: Value(hours),
          hourMeterCaptureMethod: Value(confirmedValue.method.storageValue),
          updatedByUserId: updatedByUserId == null
              ? const Value.absent()
              : Value(updatedByUserId),
          updatedAt: Value(now),
          localUpdatedAt: Value(now),
        );
      }(),
    };

    await (_db.update(_db.inspections)..where(
          (table) =>
              table.id.equals(inspectionId) & table.companyId.equals(companyId),
        ))
        .write(companion);

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  Future<Inspection> _assemble(LocalInspectionRow row) async {
    final ratingRows =
        await (_db.select(_db.inspectionCategoryRatings)..where(
              (table) =>
                  table.inspectionId.equals(row.id) &
                  table.companyId.equals(row.companyId),
            ))
            .get();

    final detailedRows =
        await (_db.select(_db.inspectionDetailedResponses)
              ..where(
                (table) =>
                    table.inspectionId.equals(row.id) &
                    table.companyId.equals(row.companyId),
              )
              ..orderBy([(table) => OrderingTerm(expression: table.sortOrder)]))
            .get();

    final ratingsByCategory = {
      for (final ratingRow in ratingRows)
        ScorecardCategory.fromStorage(ratingRow.category): CategoryRating(
          category: ScorecardCategory.fromStorage(ratingRow.category),
          rating: ConditionRating.fromStorage(ratingRow.rating),
          updatedAt: ratingRow.updatedAt.toUtc(),
        ),
    };

    // Preserve scorecard order even if a row is somehow missing.
    final orderedRatings = ScorecardCategory.scorecardOrder
        .map(
          (category) =>
              ratingsByCategory[category] ??
              CategoryRating(
                category: category,
                rating: ConditionRating.notAssessed,
                updatedAt: row.updatedAt.toUtc(),
              ),
        )
        .toList(growable: false);

    final detailed = <ScorecardCategory, DetailedCategoryResponse>{};
    for (final category in ScorecardCategory.scorecardOrder) {
      final items = detailedRows
          .where((item) => item.category == category.storageValue)
          .map(
            (item) => DetailedChecklistItemResponse(
              itemKey: item.itemKey,
              labelSnapshot: item.labelSnapshot,
              sortOrder: item.sortOrder,
              rating: ConditionRating.fromStorage(item.rating),
              notes: item.notes,
            ),
          )
          .toList(growable: false);
      if (items.isNotEmpty) {
        detailed[category] = DetailedCategoryResponse(
          category: category,
          items: items,
        );
      }
    }

    return Inspection(
      id: row.id,
      companyId: row.companyId,
      equipmentId: row.equipmentId,
      createdByUserId: row.createdByUserId,
      updatedByUserId: row.updatedByUserId,
      completionStatus: InspectionCompletionStatus.fromStorage(
        row.completionStatus,
      ),
      localLifecycle: InspectionLocalLifecycle.fromStorage(row.localLifecycle),
      depth: InspectionDepth.fromStorage(row.depth),
      syncStatus: InspectionSyncStatus.fromStorage(row.syncStatus),
      reportStatus: InspectionReportStatus.fromStorage(row.reportStatus),
      remoteId: row.remoteId,
      overallNotes: row.overallNotes,
      serialNumber: row.serialNumber,
      serialCaptureMethod: row.serialCaptureMethod == null
          ? null
          : EquipmentIdCaptureMethod.fromStorage(row.serialCaptureMethod!),
      hourMeterReading: row.hourMeterReading,
      hourMeterCaptureMethod: row.hourMeterCaptureMethod == null
          ? null
          : EquipmentIdCaptureMethod.fromStorage(row.hourMeterCaptureMethod!),
      categoryRatings: orderedRatings,
      detailedResponses: detailed,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      localUpdatedAt: row.localUpdatedAt.toUtc(),
      completedAt: row.completedAt?.toUtc(),
      discardedAt: row.discardedAt?.toUtc(),
    );
  }

  Future<Inspection> _requireOwned({
    required String companyId,
    required String inspectionId,
  }) async {
    final inspection = await getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (inspection == null) {
      throw StateError(
        'Inspection $inspectionId was not found for company $companyId.',
      );
    }
    return inspection;
  }

  Future<Inspection> _requireActiveMutable({
    required String companyId,
    required String inspectionId,
  }) {
    return _requireOwned(companyId: companyId, inspectionId: inspectionId);
  }

  void _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
  }
}
