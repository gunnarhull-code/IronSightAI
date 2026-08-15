import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/inspection_media_file_store.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/data/repositories/drift_local_inspection_repository.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/guided_quick_appraisal_step.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/local_equipment_catalog_origin.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_repository.dart';
import 'support/in_memory_inspection_media_file_store.dart';
import 'support/test_images.dart';

void main() {
  late AppDatabase database;
  late OfflineInspectionWorkspace workspace;

  Equipment equipment({
    required String id,
    String companyId = 'company-a',
    String? serialNumber,
  }) {
    final now = DateTime.utc(2026, 8, 1);
    return Equipment(
      id: id,
      companyId: companyId,
      assetName: 'Asset $id',
      manufacturer: 'Mfr',
      model: 'MDL',
      serialNumber: serialNumber,
      createdAt: now,
      updatedAt: now,
    );
  }

  const photo = CapturedImage(
    bytes: kTinyPngBytes,
    path: '/tmp/guided.png',
    mimeType: 'image/png',
  );

  Future<void> fillRequiredPhotos(String inspectionId) async {
    for (final slot in InspectionPhotoSlot.requiredSlots) {
      await workspace.inspectionMedia.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: slot,
        image: photo,
        updatedByUserId: 'user-1',
      );
    }
  }

  setUp(() async {
    database = openMemoryAppDatabase();
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: database,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  group('new versus existing draft state', () {
    test('new machine draft has null equipment and pending id', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      expect(draft.equipmentId, isNull);
      expect(draft.pendingEquipmentId, isNotNull);
      expect(draft.machineSource, InspectionMachineSource.newMachine);
      expect(draft.guidedStep, GuidedQuickAppraisalStep.equipmentIdentity);
      final catalog = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(catalog, isEmpty);
    });

    test('existing equipment draft binds selected equipment', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [equipment(id: 'eq-1')],
      );
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.existingEquipment,
        equipmentId: 'eq-1',
      );
      expect(draft.equipmentId, 'eq-1');
      expect(draft.pendingEquipmentId, isNull);
    });
  });

  group('step progression persistence', () {
    test('updateGuidedIntake preserves identity and step across reopen', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Loader',
        pendingManufacturer: 'Komatsu',
        pendingModel: 'wa380',
        guidedStep: GuidedQuickAppraisalStep.requiredPhotos,
      );
      final restored = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(restored!.pendingAssetName, 'Loader');
      expect(restored.pendingManufacturer, 'Komatsu');
      expect(restored.pendingModel, 'wa380');
      expect(restored.guidedStep, GuidedQuickAppraisalStep.requiredPhotos);
    });
  });

  group('unavailable serial and hours', () {
    test('marks and clears prior values', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'TEMP',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );
      final cleared = await workspace.inspections.markSerialUnableToVerify(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(cleared.serialNumber, isNull);
      expect(cleared.serialCaptureMethod, EquipmentIdCaptureMethod.unableToVerify);
      expect(cleared.hasResolvedSerial, isTrue);

      final hours = await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(hours.hourMeterReading, isNull);
      expect(hours.hourMeterCaptureMethod, EquipmentIdCaptureMethod.unavailable);
      expect(hours.hasResolvedHours, isTrue);
    });
  });

  group('new-machine atomic completion', () {
    test('creates exactly one local equipment and completed inspection', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Dozer',
        pendingManufacturer: 'Cat',
        pendingModel: 'D6',
      );
      await fillRequiredPhotos(draft.id);
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'SN-NEW-1',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );
      await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      final completed = await workspace.inspections.completeGuidedNewMachine(
        companyId: 'company-a',
        inspectionId: draft.id,
        updatedByUserId: 'user-1',
      );
      expect(completed.completionStatus, InspectionCompletionStatus.completed);
      expect(completed.equipmentId, isNotNull);

      final catalog = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(catalog, hasLength(1));
      expect(catalog.single.id, completed.equipmentId);
      expect(catalog.single.assetName, 'Dozer');
      expect(catalog.single.manufacturer, 'Cat');
      expect(catalog.single.model, 'D6');
      expect(catalog.single.serialNumber, 'SN-NEW-1');
      expect(catalog.single.catalogOrigin, LocalEquipmentCatalogOrigin.localCreated);
    });

    test('completion is idempotent and does not duplicate equipment', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Dozer',
        pendingManufacturer: 'Cat',
        pendingModel: 'D6',
      );
      await fillRequiredPhotos(draft.id);
      await workspace.inspections.markSerialUnableToVerify(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      final first = await workspace.inspections.completeGuidedNewMachine(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      final second = await workspace.inspections.completeGuidedNewMachine(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(second.equipmentId, first.equipmentId);
      expect(
        await workspace.equipmentCatalog.listForCompany('company-a'),
        hasLength(1),
      );
    });

    test('duplicate same-company serial offers existing equipment path', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [equipment(id: 'eq-existing', serialNumber: 'DUP-1')],
      );
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Other',
        pendingManufacturer: 'Cat',
        pendingModel: '320',
      );
      await fillRequiredPhotos(draft.id);
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'dup-1',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );
      await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      expect(
        () => workspace.inspections.completeGuidedNewMachine(
          companyId: 'company-a',
          inspectionId: draft.id,
        ),
        throwsA(
          isA<DuplicateLocalEquipmentSerialException>().having(
            (e) => e.existingEquipmentId,
            'existingEquipmentId',
            'eq-existing',
          ),
        ),
      );

      final stillDraft = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(stillDraft!.completionStatus, InspectionCompletionStatus.inProgress);
      expect(stillDraft.equipmentId, isNull);

      final switched = await workspace.inspections
          .switchGuidedDraftToExistingEquipment(
            companyId: 'company-a',
            inspectionId: draft.id,
            equipmentId: 'eq-existing',
          );
      expect(
        switched.machineSource,
        InspectionMachineSource.existingEquipment,
      );
      expect(switched.equipmentId, 'eq-existing');
      expect(switched.pendingAssetName, isNull);
    });

    test('failed incomplete completion leaves resumable draft', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      expect(
        () => workspace.inspections.completeGuidedNewMachine(
          companyId: 'company-a',
          inspectionId: draft.id,
        ),
        throwsA(isA<GuidedQuickAppraisalIncompleteException>()),
      );
      final restored = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(restored!.isIncomplete, isTrue);
      expect(restored.equipmentId, isNull);
      expect(await workspace.equipmentCatalog.listForCompany('company-a'), isEmpty);
    });
  });

  group('existing equipment completion', () {
    test('does not modify equipment master fields', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [
          equipment(id: 'eq-1', serialNumber: 'MASTER-SN'),
        ],
      );
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.existingEquipment,
        equipmentId: 'eq-1',
      );
      await fillRequiredPhotos(draft.id);
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'INSPECTION-SN',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );
      await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      await workspace.inspections.completeGuidedExistingEquipment(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      final master = await workspace.equipmentCatalog.getById(
        companyId: 'company-a',
        equipmentId: 'eq-1',
      );
      expect(master!.serialNumber, 'MASTER-SN');
      expect(master.assetName, 'Asset eq-1');
      expect(master.manufacturer, 'Mfr');
      expect(master.model, 'MDL');
    });
  });

  group('tenant isolation and lifecycle', () {
    test('rejects cross-company reads and completion', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      expect(
        await workspace.inspections.getById(
          companyId: 'company-b',
          inspectionId: draft.id,
        ),
        isNull,
      );
      expect(
        () => workspace.inspections.completeGuidedNewMachine(
          companyId: 'company-b',
          inspectionId: draft.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cannot complete discarded draft', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.discardIncomplete(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(
        () => workspace.inspections.completeGuidedNewMachine(
          companyId: 'company-a',
          inspectionId: draft.id,
        ),
        throwsA(anything),
      );
    });
  });

  group('local catalog merge', () {
    test('replaceCompanyCatalog preserves local_created equipment', () async {
      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Local Only',
        pendingManufacturer: 'Cat',
        pendingModel: 'X',
      );
      await fillRequiredPhotos(draft.id);
      await workspace.inspections.markSerialUnableToVerify(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      await workspace.inspections.markHoursUnavailable(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      final completed = await workspace.inspections.completeGuidedNewMachine(
        companyId: 'company-a',
        inspectionId: draft.id,
      );

      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [equipment(id: 'remote-1')],
      );
      final catalog = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(catalog.map((e) => e.id).toSet(), {
        'remote-1',
        completed.equipmentId!,
      });
    });
  });

  group('schema migration with prior drafts', () {
    test('v4 database with draft survives upgrade to v5', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });

      final file = File(
        '${Directory.systemTemp.path}/guided_mig_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final raw = sqlite3.open(file.path);
      raw.execute('''
        CREATE TABLE inspections (
          id TEXT NOT NULL PRIMARY KEY,
          company_id TEXT NOT NULL,
          equipment_id TEXT NOT NULL,
          created_by_user_id TEXT NOT NULL,
          updated_by_user_id TEXT NULL,
          completion_status TEXT NOT NULL,
          local_lifecycle TEXT NOT NULL,
          depth TEXT NOT NULL,
          sync_status TEXT NOT NULL,
          report_status TEXT NOT NULL,
          remote_id TEXT NULL,
          overall_notes TEXT NULL,
          serial_number TEXT NULL,
          serial_capture_method TEXT NULL,
          hour_meter_reading REAL NULL,
          hour_meter_capture_method TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          local_updated_at INTEGER NOT NULL,
          completed_at INTEGER NULL,
          discarded_at INTEGER NULL
        );
        CREATE TABLE inspection_category_ratings (
          id TEXT NOT NULL PRIMARY KEY,
          inspection_id TEXT NOT NULL,
          company_id TEXT NOT NULL,
          category TEXT NOT NULL,
          rating TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
        CREATE TABLE inspection_detailed_responses (
          id TEXT NOT NULL PRIMARY KEY,
          inspection_id TEXT NOT NULL,
          company_id TEXT NOT NULL,
          category TEXT NOT NULL,
          item_key TEXT NOT NULL,
          label_snapshot TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          rating TEXT NOT NULL,
          notes TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
        CREATE TABLE local_equipment_cache (
          id TEXT NOT NULL PRIMARY KEY,
          company_id TEXT NOT NULL,
          asset_name TEXT NOT NULL,
          manufacturer TEXT NOT NULL,
          model TEXT NOT NULL,
          serial_number TEXT NULL,
          year INTEGER NULL,
          hours REAL NULL,
          location TEXT NULL,
          notes TEXT NULL,
          created_by TEXT NULL,
          created_by_name TEXT NULL,
          updated_by TEXT NULL,
          updated_by_name TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          cached_at INTEGER NOT NULL
        );
        CREATE TABLE inspection_media (
          id TEXT NOT NULL PRIMARY KEY,
          company_id TEXT NOT NULL,
          inspection_id TEXT NOT NULL,
          slot TEXT NOT NULL,
          local_relative_path TEXT NOT NULL,
          mime_type TEXT NOT NULL,
          byte_size INTEGER NOT NULL,
          captured_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          local_updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute(
        "INSERT INTO inspections ("
        "id, company_id, equipment_id, created_by_user_id, completion_status, "
        "local_lifecycle, depth, sync_status, report_status, serial_number, "
        "serial_capture_method, overall_notes, created_at, updated_at, "
        "local_updated_at"
        ") VALUES ("
        "'legacy-1', 'company-a', 'eq-1', 'user-1', 'in_progress', 'active', "
        "'quick_appraisal', 'local_only', 'not_generated', 'OLD-SN', 'manual', "
        "'legacy notes', 0, 0, 0"
        ")",
      );
      raw.execute(
        "INSERT INTO inspection_category_ratings ("
        "id, inspection_id, company_id, category, rating, updated_at"
        ") VALUES ('r1', 'legacy-1', 'company-a', 'engine', 'good', 0)",
      );
      raw.execute('PRAGMA user_version = 4;');
      raw.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final repo = DriftLocalInspectionRepository(db);
      final restored = await repo.getById(
        companyId: 'company-a',
        inspectionId: 'legacy-1',
      );
      expect(restored, isNotNull);
      expect(restored!.equipmentId, 'eq-1');
      expect(restored.serialNumber, 'OLD-SN');
      expect(restored.overallNotes, 'legacy notes');
      expect(restored.machineSource, isNull);
      expect(restored.guidedStep, isNull);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], 5);
    });
  });
}
