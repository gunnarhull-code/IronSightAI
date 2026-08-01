import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/repositories/drift_local_inspection_repository.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/detailed_category_response.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_condition_rating_exception.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_scorecard_category_exception.dart';
import 'package:ironsight_ai/domain/inspection_value_parsing.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';

void main() {
  late AppDatabase database;
  late LocalInspectionRepository repository;
  var clockTick = 0;
  var idTick = 0;

  DateTime nextClock() {
    clockTick += 1;
    return DateTime.utc(2026, 7, 26, 12, 0, clockTick);
  }

  String nextId() {
    idTick += 1;
    return 'id-$idTick';
  }

  setUp(() {
    clockTick = 0;
    idTick = 0;
    database = openMemoryAppDatabase();
    repository = DriftLocalInspectionRepository(
      database,
      clock: nextClock,
      idGenerator: nextId,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<String> createDraft({
    String companyId = 'company-a',
    String equipmentId = 'equip-1',
    String createdByUserId = 'user-1',
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) async {
    final draft = await repository.createDraft(
      companyId: companyId,
      equipmentId: equipmentId,
      createdByUserId: createdByUserId,
      depth: depth,
    );
    return draft.id;
  }

  group('createDraft', () {
    test('creates a draft with all categories not assessed', () async {
      final draft = await repository.createDraft(
        companyId: 'company-a',
        equipmentId: 'equip-1',
        createdByUserId: 'user-1',
      );

      expect(draft.companyId, 'company-a');
      expect(draft.equipmentId, 'equip-1');
      expect(draft.createdByUserId, 'user-1');
      expect(draft.updatedByUserId, 'user-1');
      expect(draft.completionStatus, InspectionCompletionStatus.inProgress);
      expect(draft.localLifecycle, InspectionLocalLifecycle.active);
      expect(draft.depth, InspectionDepth.quickAppraisal);
      expect(draft.syncStatus, InspectionSyncStatus.localOnly);
      expect(draft.reportStatus, InspectionReportStatus.notGenerated);
      expect(draft.remoteId, isNull);
      expect(draft.categoryRatings, hasLength(7));
      expect(
        draft.categoryRatings.every(
          (rating) => rating.rating == ConditionRating.notAssessed,
        ),
        isTrue,
      );
      expect(
        draft.categoryRatings.map((rating) => rating.category).toList(),
        ScorecardCategory.scorecardOrder,
      );
    });
  });

  group('retrieval and listing', () {
    test('retrieves one inspection by id within the company', () async {
      final id = await createDraft();
      final loaded = await repository.getById(
        companyId: 'company-a',
        inspectionId: id,
      );

      expect(loaded, isNotNull);
      expect(loaded!.id, id);
      expect(loaded.equipmentId, 'equip-1');
    });

    test('returns null for a different company (tenant boundary)', () async {
      final id = await createDraft(companyId: 'company-a');
      final loaded = await repository.getById(
        companyId: 'company-b',
        inspectionId: id,
      );
      expect(loaded, isNull);
    });

    test('lists only the current company inspections', () async {
      await createDraft(companyId: 'company-a', equipmentId: 'equip-a1');
      await createDraft(companyId: 'company-a', equipmentId: 'equip-a2');
      await createDraft(companyId: 'company-b', equipmentId: 'equip-b1');

      final companyA = await repository.listForCompany('company-a');
      final companyB = await repository.listForCompany('company-b');

      expect(companyA, hasLength(2));
      expect(companyA.every((item) => item.companyId == 'company-a'), isTrue);
      expect(companyB, hasLength(1));
      expect(companyB.single.equipmentId, 'equip-b1');
    });
  });

  group('metadata updates', () {
    test('updates depth, notes, and optional sync identity', () async {
      final id = await createDraft();

      final updated = await repository.updateMetadata(
        companyId: 'company-a',
        inspectionId: id,
        updatedByUserId: 'user-2',
        depth: InspectionDepth.detailed,
        overallNotes: 'Needs closer look',
        remoteId: 'remote-123',
        syncStatus: InspectionSyncStatus.pending,
      );

      expect(updated.depth, InspectionDepth.detailed);
      expect(updated.overallNotes, 'Needs closer look');
      expect(updated.remoteId, 'remote-123');
      expect(updated.syncStatus, InspectionSyncStatus.pending);
      expect(updated.updatedByUserId, 'user-2');
    });

    test(
      'rejects updateMetadata from a different company (tenant boundary)',
      () async {
        final id = await createDraft(
          companyId: 'company-b',
          equipmentId: 'equip-b1',
        );
        final original = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );

        expect(
          () => repository.updateMetadata(
            companyId: 'company-a',
            inspectionId: id,
            updatedByUserId: 'user-a',
            depth: InspectionDepth.detailed,
            overallNotes: 'cross-tenant write',
            remoteId: 'remote-hijack',
            syncStatus: InspectionSyncStatus.pending,
          ),
          throwsA(isA<StateError>()),
        );

        final after = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );
        expect(after, isNotNull);
        expect(after!.depth, original!.depth);
        expect(after.overallNotes, original.overallNotes);
        expect(after.remoteId, original.remoteId);
        expect(after.syncStatus, original.syncStatus);
        expect(after.updatedByUserId, original.updatedByUserId);
        expect(after.updatedAt, original.updatedAt);

        expect(
          await repository.getById(companyId: 'company-a', inspectionId: id),
          isNull,
        );
        expect(
          () => repository.saveCategoryRating(
            companyId: 'company-a',
            inspectionId: id,
            category: ScorecardCategory.engine,
            rating: ConditionRating.good,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('category ratings', () {
    test('persists category rating changes', () async {
      final id = await createDraft();

      final updated = await repository.saveCategoryRating(
        companyId: 'company-a',
        inspectionId: id,
        category: ScorecardCategory.engine,
        rating: ConditionRating.good,
        updatedByUserId: 'user-1',
      );

      expect(updated.ratingFor(ScorecardCategory.engine), ConditionRating.good);
      expect(
        updated.ratingFor(ScorecardCategory.hydraulics),
        ConditionRating.notAssessed,
      );

      final again = await repository.saveCategoryRating(
        companyId: 'company-a',
        inspectionId: id,
        category: ScorecardCategory.engine,
        rating: ConditionRating.poor,
      );
      expect(again.ratingFor(ScorecardCategory.engine), ConditionRating.poor);
    });

    test(
      'rejects saveCategoryRating from a different company (tenant boundary)',
      () async {
        final id = await createDraft(companyId: 'company-b');
        await repository.saveCategoryRating(
          companyId: 'company-b',
          inspectionId: id,
          category: ScorecardCategory.engine,
          rating: ConditionRating.fair,
          updatedByUserId: 'user-b',
        );
        final original = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );

        expect(
          () => repository.saveCategoryRating(
            companyId: 'company-a',
            inspectionId: id,
            category: ScorecardCategory.engine,
            rating: ConditionRating.poor,
            updatedByUserId: 'user-a',
          ),
          throwsA(isA<StateError>()),
        );

        final after = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );
        expect(after, isNotNull);
        expect(
          after!.ratingFor(ScorecardCategory.engine),
          ConditionRating.fair,
        );
        expect(
          after.ratingFor(ScorecardCategory.engine),
          original!.ratingFor(ScorecardCategory.engine),
        );
        expect(after.updatedByUserId, original.updatedByUserId);
        expect(after.updatedAt, original.updatedAt);
      },
    );

    test('rejects invalid category and rating wire values', () {
      expect(
        () => parseScorecardCategory('not-a-category'),
        throwsA(isA<InvalidScorecardCategoryException>()),
      );
      expect(
        () => parseConditionRating('not-a-rating'),
        throwsA(isA<InvalidConditionRatingException>()),
      );
    });
  });

  group('detailed responses', () {
    test('persists detailed category checklist responses', () async {
      final id = await createDraft();

      final updated = await repository.saveDetailedCategoryResponse(
        companyId: 'company-a',
        inspectionId: id,
        updatedByUserId: 'user-1',
        response: const DetailedCategoryResponse(
          category: ScorecardCategory.undercarriage,
          items: [
            DetailedChecklistItemResponse(
              itemKey: 'track_shoes',
              labelSnapshot: 'Track shoes / pads',
              sortOrder: 0,
              rating: ConditionRating.fair,
              notes: '50% wear',
            ),
            DetailedChecklistItemResponse(
              itemKey: 'sprockets',
              labelSnapshot: 'Sprockets',
              sortOrder: 1,
              rating: ConditionRating.good,
            ),
          ],
        ),
      );

      expect(updated.depth, InspectionDepth.detailed);
      final detailed = updated.detailedFor(ScorecardCategory.undercarriage);
      expect(detailed.items, hasLength(2));
      expect(detailed.items.first.itemKey, 'track_shoes');
      expect(detailed.items.first.notes, '50% wear');
      expect(detailed.items.last.rating, ConditionRating.good);
    });
  });

  group('discard behavior', () {
    test(
      'soft-discards incomplete inspections and hides them from default list',
      () async {
        final id = await createDraft();

        final discarded = await repository.discardIncomplete(
          companyId: 'company-a',
          inspectionId: id,
          updatedByUserId: 'user-1',
        );

        expect(discarded.localLifecycle, InspectionLocalLifecycle.discarded);
        expect(discarded.discardedAt, isNotNull);
        expect(await repository.listForCompany('company-a'), isEmpty);
        expect(
          await repository.listForCompany('company-a', includeDiscarded: true),
          hasLength(1),
        );
      },
    );

    test(
      'rejects discardIncomplete from a different company (tenant boundary)',
      () async {
        final id = await createDraft(
          companyId: 'company-b',
          equipmentId: 'equip-b1',
        );
        final original = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );

        expect(
          () => repository.discardIncomplete(
            companyId: 'company-a',
            inspectionId: id,
            updatedByUserId: 'user-a',
          ),
          throwsA(isA<StateError>()),
        );

        final after = await repository.getById(
          companyId: 'company-b',
          inspectionId: id,
        );
        expect(after, isNotNull);
        expect(after!.localLifecycle, InspectionLocalLifecycle.active);
        expect(after.discardedAt, isNull);
        expect(after.localLifecycle, original!.localLifecycle);
        expect(after.discardedAt, original.discardedAt);
        expect(after.updatedByUserId, original.updatedByUserId);
        expect(after.updatedAt, original.updatedAt);
        expect(await repository.listForCompany('company-b'), hasLength(1));
      },
    );

    test('cannot discard a completed inspection', () async {
      final id = await createDraft();
      await repository.complete(companyId: 'company-a', inspectionId: id);

      expect(
        () => repository.discardIncomplete(
          companyId: 'company-a',
          inspectionId: id,
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });

    test('cannot mutate a discarded inspection', () async {
      final id = await createDraft();
      await repository.discardIncomplete(
        companyId: 'company-a',
        inspectionId: id,
      );

      expect(
        () => repository.saveCategoryRating(
          companyId: 'company-a',
          inspectionId: id,
          category: ScorecardCategory.cab,
          rating: ConditionRating.fair,
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });
  });

  group('saveConfirmedEquipmentId', () {
    test('persists confirmed serial and hours with capture methods', () async {
      final id = await createDraft();
      final withSerial = await repository.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'ABC123',
          method: EquipmentIdCaptureMethod.ocrConfirmed,
        ),
        updatedByUserId: 'user-1',
      );
      expect(withSerial.serialNumber, 'ABC123');
      expect(
        withSerial.serialCaptureMethod,
        EquipmentIdCaptureMethod.ocrConfirmed,
      );

      final withHours = await repository.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.hourMeter,
          value: '9876.5',
          method: EquipmentIdCaptureMethod.manual,
          hours: 9876.5,
        ),
        updatedByUserId: 'user-1',
      );
      expect(withHours.hourMeterReading, 9876.5);
      expect(withHours.hourMeterCaptureMethod, EquipmentIdCaptureMethod.manual);
      expect(withHours.serialNumber, 'ABC123');
    });

    test('rejects wrong-company confirmation writes', () async {
      final id = await createDraft(companyId: 'company-a');
      expect(
        () => repository.saveConfirmedEquipmentId(
          companyId: 'company-b',
          inspectionId: id,
          confirmedValue: const ConfirmedEquipmentIdValue(
            kind: EquipmentIdCaptureKind.serialNumber,
            value: 'X',
            method: EquipmentIdCaptureMethod.manual,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects confirmation on discarded drafts', () async {
      final id = await createDraft();
      await repository.discardIncomplete(
        companyId: 'company-a',
        inspectionId: id,
      );
      expect(
        () => repository.saveConfirmedEquipmentId(
          companyId: 'company-a',
          inspectionId: id,
          confirmedValue: const ConfirmedEquipmentIdValue(
            kind: EquipmentIdCaptureKind.serialNumber,
            value: 'X',
            method: EquipmentIdCaptureMethod.manual,
          ),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });
  });

  group('persistence across reconnect', () {
    test(
      'preserves inspection data after recreating repository/database connection',
      () async {
        // Intentional sequential open/close of the same file path.
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        addTearDown(() {
          driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
        });

        final directory = await Directory.systemTemp.createTemp(
          'ironsight_db_',
        );
        final file = File('${directory.path}/inspections.sqlite');
        addTearDown(() async {
          await directory.delete(recursive: true);
        });

        const encryptionKey = 'test-inspection-key';
        final firstDb = openFileAppDatabase(
          file,
          encryptionKey: encryptionKey,
          requireCipher: false,
        );
        final firstRepo = DriftLocalInspectionRepository(
          firstDb,
          clock: nextClock,
          idGenerator: nextId,
        );

        final created = await firstRepo.createDraft(
          companyId: 'company-a',
          equipmentId: 'equip-1',
          createdByUserId: 'user-1',
        );
        await firstRepo.saveCategoryRating(
          companyId: 'company-a',
          inspectionId: created.id,
          category: ScorecardCategory.structure,
          rating: ConditionRating.fair,
        );
        await firstRepo.saveDetailedCategoryResponse(
          companyId: 'company-a',
          inspectionId: created.id,
          response: const DetailedCategoryResponse(
            category: ScorecardCategory.structure,
            items: [
              DetailedChecklistItemResponse(
                itemKey: 'frame_cracks',
                labelSnapshot: 'Frame cracks',
                sortOrder: 0,
                rating: ConditionRating.good,
              ),
            ],
          ),
        );
        await firstRepo.saveConfirmedEquipmentId(
          companyId: 'company-a',
          inspectionId: created.id,
          confirmedValue: const ConfirmedEquipmentIdValue(
            kind: EquipmentIdCaptureKind.serialNumber,
            value: 'REOPEN1',
            method: EquipmentIdCaptureMethod.manual,
          ),
        );
        await firstRepo.saveConfirmedEquipmentId(
          companyId: 'company-a',
          inspectionId: created.id,
          confirmedValue: const ConfirmedEquipmentIdValue(
            kind: EquipmentIdCaptureKind.hourMeter,
            value: '100',
            method: EquipmentIdCaptureMethod.ocrConfirmed,
            hours: 100,
          ),
        );
        await firstDb.close();

        final secondDb = openFileAppDatabase(
          file,
          encryptionKey: encryptionKey,
          requireCipher: false,
        );
        final secondRepo = DriftLocalInspectionRepository(secondDb);
        addTearDown(secondDb.close);

        final restored = await secondRepo.getById(
          companyId: 'company-a',
          inspectionId: created.id,
        );

        expect(restored, isNotNull);
        expect(
          restored!.ratingFor(ScorecardCategory.structure),
          ConditionRating.fair,
        );
        expect(
          restored
              .detailedFor(ScorecardCategory.structure)
              .items
              .single
              .itemKey,
          'frame_cracks',
        );
        expect(restored.serialNumber, 'REOPEN1');
        expect(restored.hourMeterReading, 100);
        expect(await secondRepo.listForCompany('company-a'), hasLength(1));
      },
    );
  });
}
