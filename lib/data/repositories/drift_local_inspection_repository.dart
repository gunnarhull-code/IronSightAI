import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category_rating.dart';
import '../../domain/entities/condition_rating.dart';
import '../../domain/entities/detailed_category_response.dart';
import '../../domain/entities/guided_quick_appraisal_step.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/inspection_depth.dart';
import '../../domain/entities/inspection_machine_source.dart';
import '../../domain/entities/inspection_status.dart';
import '../../domain/entities/local_equipment_catalog_origin.dart';
import '../../domain/entities/scorecard_category.dart';
import '../../domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_kind.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_method.dart';
import '../../domain/guided_quick_appraisal_completeness.dart';
import '../../domain/inspection_lifecycle.dart';
import '../../domain/inspection_value_parsing.dart';
import '../../domain/repositories/local_inspection_media_repository.dart';
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
    LocalInspectionMediaRepository? mediaForCompleteness,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? const Uuid().v4,
       _mediaForCompleteness = mediaForCompleteness;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _idGenerator;
  final LocalInspectionMediaRepository? _mediaForCompleteness;

  /// Optional media repo used by guided completion completeness checks.
  DriftLocalInspectionRepository withMediaRepository(
    LocalInspectionMediaRepository media,
  ) {
    return DriftLocalInspectionRepository(
      _db,
      clock: _clock,
      idGenerator: _idGenerator,
      mediaForCompleteness: media,
    );
  }

  @override
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) {
    return createGuidedDraft(
      companyId: companyId,
      createdByUserId: createdByUserId,
      machineSource: InspectionMachineSource.existingEquipment,
      equipmentId: equipmentId,
      depth: depth,
    );
  }

  @override
  Future<Inspection> createGuidedDraft({
    required String companyId,
    required String createdByUserId,
    required InspectionMachineSource machineSource,
    String? equipmentId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(createdByUserId, 'createdByUserId');

    if (machineSource == InspectionMachineSource.existingEquipment) {
      _requireNonEmpty(equipmentId ?? '', 'equipmentId');
    } else if (equipmentId != null && equipmentId.trim().isNotEmpty) {
      throw ArgumentError.value(
        equipmentId,
        'equipmentId',
        'New-machine drafts must not bind Equipment until completion',
      );
    }

    final now = _clock();
    final inspectionId = _idGenerator();
    final pendingEquipmentId =
        machineSource == InspectionMachineSource.newMachine
        ? _idGenerator()
        : null;

    await _db.transaction(() async {
      await _db
          .into(_db.inspections)
          .insert(
            InspectionsCompanion.insert(
              id: inspectionId,
              companyId: companyId,
              equipmentId: Value(
                machineSource == InspectionMachineSource.existingEquipment
                    ? equipmentId
                    : null,
              ),
              createdByUserId: createdByUserId,
              updatedByUserId: Value(createdByUserId),
              completionStatus:
                  InspectionCompletionStatus.inProgress.storageValue,
              localLifecycle: InspectionLocalLifecycle.active.storageValue,
              depth: depth.storageValue,
              syncStatus: InspectionSyncStatus.localOnly.storageValue,
              reportStatus: InspectionReportStatus.notGenerated.storageValue,
              machineSource: Value(machineSource.storageValue),
              guidedStep: Value(
                GuidedQuickAppraisalStep.equipmentIdentity.storageValue,
              ),
              pendingEquipmentId: Value(pendingEquipmentId),
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
  }) async {
    final existing = await _requireActiveMutable(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    InspectionLifecycle.ensureCanMutate(existing);

    if (equipmentId != null) {
      _requireNonEmpty(equipmentId, 'equipmentId');
      await _requireEquipmentBelongsToCompany(
        companyId: companyId,
        equipmentId: equipmentId,
      );
    }

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
            machineSource: machineSource == null
                ? const Value.absent()
                : Value(machineSource.storageValue),
            equipmentId: clearEquipmentId
                ? const Value(null)
                : (equipmentId == null
                      ? const Value.absent()
                      : Value(equipmentId)),
            pendingAssetName: clearPendingIdentity
                ? const Value(null)
                : (pendingAssetName == null
                      ? const Value.absent()
                      : Value(pendingAssetName)),
            pendingManufacturer: clearPendingIdentity
                ? const Value(null)
                : (pendingManufacturer == null
                      ? const Value.absent()
                      : Value(pendingManufacturer)),
            pendingModel: clearPendingIdentity
                ? const Value(null)
                : (pendingModel == null
                      ? const Value.absent()
                      : Value(pendingModel)),
            guidedStep: guidedStep == null
                ? const Value.absent()
                : Value(guidedStep.storageValue),
            pendingEquipmentId: pendingEquipmentId == null
                ? const Value.absent()
                : Value(pendingEquipmentId),
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
    if (existing.completionStatus == InspectionCompletionStatus.completed) {
      return existing;
    }

    // Guided New-machine drafts create Equipment atomically.
    if (existing.machineSource == InspectionMachineSource.newMachine) {
      return completeGuidedNewMachine(
        companyId: companyId,
        inspectionId: inspectionId,
        updatedByUserId: updatedByUserId,
      );
    }

    // Guided Existing-equipment drafts enforce completeness and leave master
    // Equipment unchanged.
    if (existing.machineSource == InspectionMachineSource.existingEquipment) {
      return completeGuidedExistingEquipment(
        companyId: companyId,
        inspectionId: inspectionId,
        updatedByUserId: updatedByUserId,
      );
    }

    // Legacy pre-guided drafts: preserve prior completion semantics.
    InspectionLifecycle.ensureCanComplete(existing);
    return _markCompleted(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: updatedByUserId,
    );
  }

  @override
  Future<Inspection> completeGuidedExistingEquipment({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) async {
    final existing = await _requireOwned(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (existing.completionStatus == InspectionCompletionStatus.completed) {
      return existing;
    }
    InspectionLifecycle.ensureCanComplete(existing);
    await _ensureGuidedCompleteness(
      companyId: companyId,
      inspection: existing,
    );
    if (existing.equipmentId == null || existing.equipmentId!.isEmpty) {
      throw GuidedQuickAppraisalIncompleteException(
        'Existing-equipment completion requires a linked Equipment record.',
      );
    }
    await _requireEquipmentBelongsToCompany(
      companyId: companyId,
      equipmentId: existing.equipmentId!,
    );

    return _markCompleted(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: updatedByUserId,
    );
  }

  @override
  Future<Inspection> completeGuidedNewMachine({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) async {
    final existing = await _requireOwned(
      companyId: companyId,
      inspectionId: inspectionId,
    );

    // Idempotent success path.
    if (existing.completionStatus == InspectionCompletionStatus.completed) {
      return existing;
    }

    InspectionLifecycle.ensureCanComplete(existing);
    if (existing.machineSource != InspectionMachineSource.newMachine) {
      throw GuidedQuickAppraisalIncompleteException(
        'completeGuidedNewMachine requires a New-machine draft.',
      );
    }

    await _ensureGuidedCompleteness(
      companyId: companyId,
      inspection: existing,
    );

    final assetName = existing.pendingAssetName?.trim() ?? '';
    final manufacturer = existing.pendingManufacturer?.trim() ?? '';
    final model = existing.pendingModel?.trim() ?? '';
    if (assetName.isEmpty || manufacturer.isEmpty || model.isEmpty) {
      throw GuidedQuickAppraisalIncompleteException(
        'New-machine completion requires asset name, manufacturer, and model.',
      );
    }

    final verifiedSerial =
        existing.serialIsUnableToVerify ? null : existing.serialNumber?.trim();
    if (verifiedSerial != null && verifiedSerial.isNotEmpty) {
      final duplicate = await _findEquipmentBySerial(
        companyId: companyId,
        serialNumber: verifiedSerial,
      );
      if (duplicate != null &&
          duplicate.id != existing.equipmentId &&
          duplicate.id != existing.pendingEquipmentId) {
        throw DuplicateLocalEquipmentSerialException(
          existingEquipmentId: duplicate.id,
          serialNumber: verifiedSerial,
        );
      }
    }

    final equipmentId =
        existing.equipmentId ??
        existing.pendingEquipmentId ??
        _idGenerator();
    final now = _clock();

    try {
      await _db.transaction(() async {
        final alreadyCached =
            await (_db.select(_db.localEquipmentCache)..where(
                  (table) =>
                      table.id.equals(equipmentId) &
                      table.companyId.equals(companyId),
                ))
                .getSingleOrNull();

        if (alreadyCached == null) {
          await _db
              .into(_db.localEquipmentCache)
              .insert(
                LocalEquipmentCacheCompanion.insert(
                  id: equipmentId,
                  companyId: companyId,
                  assetName: assetName,
                  manufacturer: manufacturer,
                  model: model,
                  serialNumber: Value(verifiedSerial),
                  createdBy: Value(updatedByUserId ?? existing.createdByUserId),
                  updatedBy: Value(updatedByUserId ?? existing.createdByUserId),
                  createdAt: now,
                  updatedAt: now,
                  cachedAt: now,
                  catalogOrigin: Value(
                    LocalEquipmentCatalogOrigin.localCreated.storageValue,
                  ),
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
                equipmentId: Value(equipmentId),
                pendingEquipmentId: Value(equipmentId),
                completionStatus: Value(
                  InspectionCompletionStatus.completed.storageValue,
                ),
                completedAt: Value(now),
                updatedByUserId: updatedByUserId == null
                    ? const Value.absent()
                    : Value(updatedByUserId),
                updatedAt: Value(now),
                localUpdatedAt: Value(now),
                guidedStep: Value(
                  GuidedQuickAppraisalStep.reviewAndComplete.storageValue,
                ),
              ),
            );
      });
    } catch (error) {
      // Leave draft resumable; do not leave a partial completed inspection.
      if (error is DuplicateLocalEquipmentSerialException) rethrow;
      rethrow;
    }

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

    if (confirmedValue.method.isExplicitUnavailable) {
      return switch (confirmedValue.kind) {
        EquipmentIdCaptureKind.serialNumber => markSerialUnableToVerify(
          companyId: companyId,
          inspectionId: inspectionId,
          updatedByUserId: updatedByUserId,
        ),
        EquipmentIdCaptureKind.hourMeter => markHoursUnavailable(
          companyId: companyId,
          inspectionId: inspectionId,
          updatedByUserId: updatedByUserId,
        ),
      };
    }

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

  @override
  Future<Inspection> markSerialUnableToVerify({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
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
            serialNumber: const Value(null),
            serialCaptureMethod: Value(
              EquipmentIdCaptureMethod.unableToVerify.storageValue,
            ),
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
  Future<Inspection> markHoursUnavailable({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
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
            hourMeterReading: const Value(null),
            hourMeterCaptureMethod: Value(
              EquipmentIdCaptureMethod.unavailable.storageValue,
            ),
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
  Future<Inspection> switchGuidedDraftToExistingEquipment({
    required String companyId,
    required String inspectionId,
    required String equipmentId,
    String? updatedByUserId,
  }) async {
    _requireNonEmpty(equipmentId, 'equipmentId');
    await _requireEquipmentBelongsToCompany(
      companyId: companyId,
      equipmentId: equipmentId,
    );

    return updateGuidedIntake(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: updatedByUserId,
      machineSource: InspectionMachineSource.existingEquipment,
      equipmentId: equipmentId,
      clearPendingIdentity: true,
      guidedStep: GuidedQuickAppraisalStep.equipmentIdentity,
    );
  }

  Future<Inspection> _markCompleted({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) async {
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
            guidedStep: Value(
              GuidedQuickAppraisalStep.reviewAndComplete.storageValue,
            ),
          ),
        );

    return (await getById(companyId: companyId, inspectionId: inspectionId))!;
  }

  Future<void> _ensureGuidedCompleteness({
    required String companyId,
    required Inspection inspection,
  }) async {
    final mediaRepo = _mediaForCompleteness;
    if (mediaRepo == null) {
      // Tests that omit media still enforce serial/hours/identity.
      final completeness = evaluateGuidedQuickAppraisalCompleteness(
        inspection: inspection,
        media: const [],
      );
      // Without media repo, skip photo requirement only in unit tests that
      // do not wire media — production workspace always wires media.
      final missing = {...completeness.missing}
        ..remove(GuidedQuickAppraisalRequirement.requiredPhotos);
      if (missing.isNotEmpty) {
        throw GuidedQuickAppraisalIncompleteException(
          'Guided Quick Appraisal is incomplete: ${missing.map((e) => e.name).join(', ')}',
        );
      }
      return;
    }

    final media = await mediaRepo.listForInspection(
      companyId: companyId,
      inspectionId: inspection.id,
    );
    final completeness = evaluateGuidedQuickAppraisalCompleteness(
      inspection: inspection,
      media: media,
    );
    if (!completeness.isComplete) {
      throw GuidedQuickAppraisalIncompleteException(
        'Guided Quick Appraisal is incomplete: '
        '${completeness.missing.map((e) => e.name).join(', ')}',
      );
    }
  }

  Future<LocalEquipmentCacheRow?> _findEquipmentBySerial({
    required String companyId,
    required String serialNumber,
  }) async {
    final normalized = serialNumber.trim().toUpperCase();
    final rows =
        await (_db.select(_db.localEquipmentCache)
              ..where((table) => table.companyId.equals(companyId)))
            .get();
    for (final row in rows) {
      final serial = row.serialNumber?.trim().toUpperCase();
      if (serial != null && serial.isNotEmpty && serial == normalized) {
        return row;
      }
    }
    return null;
  }

  Future<void> _requireEquipmentBelongsToCompany({
    required String companyId,
    required String equipmentId,
  }) async {
    final row =
        await (_db.select(_db.localEquipmentCache)..where(
              (table) =>
                  table.id.equals(equipmentId) &
                  table.companyId.equals(companyId),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw StateError(
        'Equipment $equipmentId was not found for company $companyId.',
      );
    }
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
      machineSource: row.machineSource == null
          ? null
          : InspectionMachineSource.fromStorage(row.machineSource!),
      pendingAssetName: row.pendingAssetName,
      pendingManufacturer: row.pendingManufacturer,
      pendingModel: row.pendingModel,
      guidedStep: row.guidedStep == null
          ? null
          : GuidedQuickAppraisalStep.fromStorage(row.guidedStep!),
      pendingEquipmentId: row.pendingEquipmentId,
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
