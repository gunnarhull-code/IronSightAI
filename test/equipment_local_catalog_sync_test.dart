import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/data/repositories/local_catalog_syncing_equipment_repository.dart';
import 'package:ironsight_ai/data/services/equipment_catalog_refresh_service.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/equipment_details.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/local_equipment_catalog_origin.dart';
import 'package:ironsight_ai/domain/exceptions/equipment_local_catalog_mirror_exception.dart';
import 'package:ironsight_ai/domain/use_cases/create_equipment.dart';
import 'package:ironsight_ai/domain/use_cases/update_equipment.dart';
import 'package:ironsight_ai/features/inspection/presentation/guided_quick_appraisal_entry_screen.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_repository.dart';
import 'support/fake_local_equipment_catalog_repository.dart';
import 'support/in_memory_inspection_media_file_store.dart';

void main() {
  late FakeEquipmentRepository remote;
  late OfflineInspectionWorkspace workspace;

  EquipmentDetails validDetails({
    String assetName = 'Skid Steer',
    String manufacturer = 'Bobcat',
    String model = 'S650',
    String? serialNumber = 'SN-NEW',
  }) {
    return EquipmentDetails.validated(
      assetName: assetName,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
    );
  }

  Equipment seedEquipment({
    required String id,
    required String companyId,
    String assetName = 'Cached Loader',
    String manufacturer = 'Caterpillar',
    String model = '950',
  }) {
    final now = DateTime.utc(2026, 8, 1);
    return Equipment(
      id: id,
      companyId: companyId,
      assetName: assetName,
      manufacturer: manufacturer,
      model: model,
      serialNumber: 'SN-$id',
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    remote = FakeEquipmentRepository(companyId: 'company-a');
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: remote,
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  group('successful remote mutations mirror into the local catalog', () {
    test(
      'create upserts into the matching company catalog immediately',
      () async {
        final created =
            await CreateEquipment(workspace.catalogSyncingEquipment)(
              assetName: 'Skid Steer',
              manufacturer: 'Bobcat',
              model: 'S650',
              serialNumber: 'SN-NEW',
            );

        expect(remote.createCallCount, 1);
        final local = await workspace.equipmentCatalog.listForCompany(
          'company-a',
        );
        expect(local, hasLength(1));
        expect(local.single.id, created.id);
        expect(local.single.assetName, 'Skid Steer');
        expect(local.single.companyId, 'company-a');
        expect(
          local.single.catalogOrigin,
          LocalEquipmentCatalogOrigin.remoteCache,
        );
        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-a',
            equipmentId: created.id,
          ),
          isNotNull,
        );
      },
    );

    test(
      'edit updates the corresponding local catalog entry immediately',
      () async {
        final created =
            await CreateEquipment(workspace.catalogSyncingEquipment)(
              assetName: 'Skid Steer',
              manufacturer: 'Bobcat',
              model: 'S650',
              serialNumber: 'SN-NEW',
            );

        final updated =
            await UpdateEquipment(workspace.catalogSyncingEquipment)(
              id: created.id,
              assetName: 'Skid Steer Updated',
              manufacturer: 'Bobcat',
              model: 'S770',
              serialNumber: 'SN-NEW',
            );

        expect(remote.updateCallCount, 1);
        final local = await workspace.equipmentCatalog.listForCompany(
          'company-a',
        );
        expect(local, hasLength(1));
        expect(local.single.id, updated.id);
        expect(local.single.assetName, 'Skid Steer Updated');
        expect(local.single.model, 'S770');
      },
    );
  });

  group('remote failures do not mutate the local catalog', () {
    test('create failure leaves the local catalog unchanged', () async {
      remote.createError = Exception('remote create failed');

      await expectLater(
        CreateEquipment(workspace.catalogSyncingEquipment)(
          assetName: 'Skid Steer',
          manufacturer: 'Bobcat',
          model: 'S650',
          serialNumber: 'SN-NEW',
        ),
        throwsA(isA<Exception>()),
      );

      expect(remote.createCallCount, 1);
      expect(
        await workspace.equipmentCatalog.listForCompany('company-a'),
        isEmpty,
      );
    });

    test('edit failure leaves the local catalog unchanged', () async {
      final existing = seedEquipment(id: 'eq-1', companyId: 'company-a');
      remote.equipment = [existing];
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [existing],
      );
      remote.updateError = Exception('remote update failed');

      await expectLater(
        UpdateEquipment(workspace.catalogSyncingEquipment)(
          id: 'eq-1',
          assetName: 'Should Not Persist',
          manufacturer: 'Bobcat',
          model: 'S650',
          serialNumber: 'SN-eq-1',
        ),
        throwsA(isA<Exception>()),
      );

      expect(remote.updateCallCount, 1);
      final local = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(local.single.assetName, 'Cached Loader');
    });
  });

  group('local catalog failures are not swallowed and do not retry remote', () {
    test(
      'create throws partial-success exception when local upsert fails',
      () async {
        final local = FakeLocalEquipmentCatalogRepository()
          ..upsertError = StateError('local catalog write failed');
        final refresh = EquipmentCatalogRefreshService(
          remoteEquipmentRepository: remote,
          localCatalog: local,
        );
        final syncing = LocalCatalogSyncingEquipmentRepository(
          remoteEquipmentRepository: remote,
          catalogRefreshService: refresh,
        );

        await expectLater(
          syncing.createEquipment(validDetails()),
          throwsA(
            isA<EquipmentLocalCatalogMirrorException>()
                .having(
                  (error) => error.operation,
                  'operation',
                  EquipmentRemoteSaveOperation.create,
                )
                .having(
                  (error) => error.equipment.assetName,
                  'assetName',
                  'Skid Steer',
                ),
          ),
        );

        expect(remote.createCallCount, 1);
        expect(local.upsertCallCount, 1);
        expect(local.storedFor('company-a'), isEmpty);
      },
    );

    test('retryLocalMirror succeeds without another remote create', () async {
      final local = FakeLocalEquipmentCatalogRepository()
        ..upsertError = StateError('local catalog write failed');
      final refresh = EquipmentCatalogRefreshService(
        remoteEquipmentRepository: remote,
        localCatalog: local,
      );
      final syncing = LocalCatalogSyncingEquipmentRepository(
        remoteEquipmentRepository: remote,
        catalogRefreshService: refresh,
      );

      EquipmentLocalCatalogMirrorException? partial;
      try {
        await syncing.createEquipment(validDetails());
      } on EquipmentLocalCatalogMirrorException catch (error) {
        partial = error;
      }
      expect(partial, isNotNull);

      local.upsertError = null;
      await syncing.retryLocalMirror(partial!.equipment);

      expect(remote.createCallCount, 1);
      expect(local.storedFor('company-a'), hasLength(1));
      expect(local.storedFor('company-a').single.id, partial.equipment.id);
    });
  });

  group('stale refresh cannot erase newer local mutations', () {
    test('stale refresh after create cannot erase the new Equipment', () async {
      remote.blockGetUntil = Completer<void>();
      remote.onGetStarted = Completer<void>();

      final refreshFuture = workspace.catalogRefresh.refreshCompanyCatalog(
        'company-a',
      );
      await remote.onGetStarted!.future;

      final created = await CreateEquipment(workspace.catalogSyncingEquipment)(
        assetName: 'Skid Steer',
        manufacturer: 'Bobcat',
        model: 'S650',
        serialNumber: 'SN-NEW',
      );

      remote.blockGetUntil!.complete();
      final applied = await refreshFuture;
      expect(applied, isFalse);

      final local = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(local.map((item) => item.id), [created.id]);
      expect(local.single.assetName, 'Skid Steer');
    });

    test('stale refresh after edit cannot restore old values', () async {
      final existing = seedEquipment(
        id: 'eq-1',
        companyId: 'company-a',
        assetName: 'Old Name',
      );
      remote.equipment = [existing];
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [existing],
      );

      remote.blockGetUntil = Completer<void>();
      remote.onGetStarted = Completer<void>();
      final refreshFuture = workspace.catalogRefresh.refreshCompanyCatalog(
        'company-a',
      );
      await remote.onGetStarted!.future;

      await UpdateEquipment(workspace.catalogSyncingEquipment)(
        id: 'eq-1',
        assetName: 'New Name',
        manufacturer: 'Caterpillar',
        model: '950',
        serialNumber: 'SN-eq-1',
      );

      remote.blockGetUntil!.complete();
      final applied = await refreshFuture;
      expect(applied, isFalse);

      final local = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(local.single.assetName, 'New Name');
    });
  });

  group('company isolation', () {
    test('mirrored create never lands in another company catalog', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-b',
        equipment: [
          seedEquipment(
            id: 'eq-b',
            companyId: 'company-b',
            assetName: 'Other Company',
          ),
        ],
      );

      final created = await CreateEquipment(workspace.catalogSyncingEquipment)(
        assetName: 'Skid Steer',
        manufacturer: 'Bobcat',
        model: 'S650',
        serialNumber: 'SN-NEW',
      );

      expect(
        await workspace.equipmentCatalog.listForCompany('company-a'),
        hasLength(1),
      );
      expect(
        await workspace.equipmentCatalog.getById(
          companyId: 'company-b',
          equipmentId: created.id,
        ),
        isNull,
      );
      final companyB = await workspace.equipmentCatalog.listForCompany(
        'company-b',
      );
      expect(companyB.single.id, 'eq-b');
      expect(companyB.single.assetName, 'Other Company');
    });

    test(
      'refresh drops cross-company remote rows instead of using them',
      () async {
        remote.equipment = [
          seedEquipment(id: 'eq-a', companyId: 'company-a'),
          seedEquipment(
            id: 'eq-b',
            companyId: 'company-b',
            assetName: 'Other Company',
          ),
        ];

        final applied = await workspace.catalogRefresh.refreshCompanyCatalog(
          'company-a',
        );
        expect(applied, isTrue);

        final companyA = await workspace.equipmentCatalog.listForCompany(
          'company-a',
        );
        expect(companyA.map((item) => item.id), ['eq-a']);
        expect(
          await workspace.equipmentCatalog.listForCompany('company-b'),
          isEmpty,
        );
        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-a',
            equipmentId: 'eq-b',
          ),
          isNull,
        );
      },
    );

    test(
      'upsert refuses to overwrite another company row with the same id',
      () async {
        await workspace.equipmentCatalog.upsertEquipment(
          seedEquipment(id: 'eq-shared', companyId: 'company-a'),
        );

        await expectLater(
          workspace.equipmentCatalog.upsertEquipment(
            seedEquipment(id: 'eq-shared', companyId: 'company-b'),
          ),
          throwsA(isA<StateError>()),
        );

        expect(
          (await workspace.equipmentCatalog.getById(
            companyId: 'company-a',
            equipmentId: 'eq-shared',
          ))?.companyId,
          'company-a',
        );
        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-b',
            equipmentId: 'eq-shared',
          ),
          isNull,
        );
      },
    );
  });

  group('existing-equipment guided flow', () {
    test(
      'newly mirrored equipment can start a guided draft without a refresh',
      () async {
        final created =
            await CreateEquipment(workspace.catalogSyncingEquipment)(
              assetName: 'Skid Steer',
              manufacturer: 'Bobcat',
              model: 'S650',
              serialNumber: 'SN-NEW',
            );

        expect(remote.getCallCount, 0);

        final cached = await workspace.equipmentCatalog.getById(
          companyId: 'company-a',
          equipmentId: created.id,
        );
        expect(cached, isNotNull);

        final draft = await workspace.inspections.createGuidedDraft(
          companyId: 'company-a',
          createdByUserId: 'user-1',
          machineSource: InspectionMachineSource.existingEquipment,
          equipmentId: created.id,
        );
        expect(draft.equipmentId, created.id);
        expect(draft.machineSource, InspectionMachineSource.existingEquipment);
        expect(remote.getCallCount, 0);
      },
    );

    testWidgets(
      'Existing-equipment picker shows mirrored equipment when refresh fails',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final created =
            await CreateEquipment(workspace.catalogSyncingEquipment)(
              assetName: 'Skid Steer',
              manufacturer: 'Bobcat',
              model: 'S650',
              serialNumber: 'SN-NEW',
            );

        var refreshCalls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: GuidedQuickAppraisalEntryScreen(
              companyId: 'company-a',
              userId: 'user-1',
              inspections: workspace.inspections,
              equipmentCatalog: workspace.equipmentCatalog,
              refreshCatalog: (companyId) async {
                refreshCalls += 1;
                expect(companyId, 'company-a');
                return false;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Existing equipment'));
        await tester.pumpAndSettle();

        expect(find.text('Skid Steer'), findsOneWidget);
        expect(find.text('Bobcat · S650 · S/N SN-NEW'), findsOneWidget);
        expect(refreshCalls, 1);
        expect(remote.getCallCount, 0);
        expect(created.assetName, 'Skid Steer');
      },
    );
  });

  group('existing drafts stay readable', () {
    test(
      'guided and legacy-style drafts are unchanged after catalog sync',
      () async {
        final existing = seedEquipment(id: 'eq-legacy', companyId: 'company-a');
        remote.equipment = [existing];
        await workspace.equipmentCatalog.replaceCompanyCatalog(
          companyId: 'company-a',
          equipment: [existing],
        );

        final legacyDraft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-legacy',
          createdByUserId: 'user-1',
        );
        final guidedDraft = await workspace.inspections.createGuidedDraft(
          companyId: 'company-a',
          createdByUserId: 'user-1',
          machineSource: InspectionMachineSource.newMachine,
        );
        await workspace.inspections.updateGuidedIntake(
          companyId: 'company-a',
          inspectionId: guidedDraft.id,
          pendingAssetName: 'Pending Loader',
          pendingManufacturer: 'Komatsu',
          pendingModel: 'WA380',
        );

        final legacyBefore = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: legacyDraft.id,
        );
        final guidedBefore = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: guidedDraft.id,
        );

        await CreateEquipment(workspace.catalogSyncingEquipment)(
          assetName: 'Skid Steer',
          manufacturer: 'Bobcat',
          model: 'S650',
          serialNumber: 'SN-NEW',
        );
        await UpdateEquipment(workspace.catalogSyncingEquipment)(
          id: 'eq-legacy',
          assetName: 'Cached Loader Edited',
          manufacturer: 'Caterpillar',
          model: '950',
          serialNumber: 'SN-eq-legacy',
        );

        final legacyAfter = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: legacyDraft.id,
        );
        final guidedAfter = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: guidedDraft.id,
        );

        expect(legacyAfter!.id, legacyBefore!.id);
        expect(legacyAfter.equipmentId, 'eq-legacy');
        expect(legacyAfter.createdByUserId, legacyBefore.createdByUserId);
        expect(legacyAfter.completionStatus, legacyBefore.completionStatus);
        expect(legacyAfter.overallNotes, legacyBefore.overallNotes);
        expect(legacyAfter.serialNumber, legacyBefore.serialNumber);
        expect(legacyAfter.createdAt, legacyBefore.createdAt);

        expect(guidedAfter!.id, guidedBefore!.id);
        expect(guidedAfter.equipmentId, isNull);
        expect(guidedAfter.pendingAssetName, 'Pending Loader');
        expect(guidedAfter.pendingManufacturer, 'Komatsu');
        expect(guidedAfter.pendingModel, 'WA380');
        expect(guidedAfter.machineSource, InspectionMachineSource.newMachine);
        expect(guidedAfter.createdAt, guidedBefore.createdAt);
      },
    );
  });
}
