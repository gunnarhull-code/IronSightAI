import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/data/repositories/local_catalog_syncing_equipment_repository.dart';
import 'package:ironsight_ai/data/services/equipment_catalog_refresh_service.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/equipment_details.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/repositories/equipment_repository.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_repository.dart';

void main() {
  group('create equipment → Quick Appraisal draft', () {
    test(
      'synced create caches equipment and starts a local draft immediately',
      () async {
        final remote = FakeEquipmentRepository(companyId: 'company-a');
        final workspace = OfflineInspectionWorkspace.fromDatabase(
          database: openMemoryAppDatabase(),
          remoteEquipmentRepository: remote,
          authSession: FakeAuthSessionReader(),
        );
        addTearDown(workspace.dispose);

        await workspace.tenantContext.activate(
          companyId: 'company-a',
          userId: 'user-1',
        );

        final syncing = LocalCatalogSyncingEquipmentRepository(
          remote: remote,
          localCatalog: workspace.equipmentCatalog,
        );

        final created = await syncing.createEquipment(
          EquipmentDetails.validated(
            assetName: 'New S22 Excavator',
            manufacturer: 'Caterpillar',
            model: '320',
            serialNumber: 'S22-NEW-001',
          ),
        );

        final cached = await workspace.equipmentCatalog.getById(
          companyId: 'company-a',
          equipmentId: created.id,
        );
        expect(cached, isNotNull);
        expect(cached!.assetName, 'New S22 Excavator');

        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: created.id,
          createdByUserId: 'user-1',
        );

        expect(draft.equipmentId, created.id);
        expect(draft.companyId, 'company-a');
        expect(draft.completionStatus, InspectionCompletionStatus.inProgress);
        expect(draft.localLifecycle, InspectionLocalLifecycle.active);

        final listed = await workspace.inspections.listForCompany('company-a');
        expect(listed, hasLength(1));
        expect(listed.single.id, draft.id);
      },
    );

    test(
      'create without local sync cannot start a draft and leaves no partial row',
      () async {
        final remote = FakeEquipmentRepository(companyId: 'company-a');
        final workspace = OfflineInspectionWorkspace.fromDatabase(
          database: openMemoryAppDatabase(),
          remoteEquipmentRepository: remote,
          authSession: FakeAuthSessionReader(),
        );
        addTearDown(workspace.dispose);

        final created = await remote.createEquipment(
          EquipmentDetails.validated(
            assetName: 'Unsynced Excavator',
            manufacturer: 'Caterpillar',
            model: '320',
          ),
        );

        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-a',
            equipmentId: created.id,
          ),
          isNull,
        );

        await expectLater(
          workspace.inspections.createDraft(
            companyId: 'company-a',
            equipmentId: created.id,
            createdByUserId: 'user-1',
          ),
          throwsA(isA<StateError>()),
        );
        expect(
          await workspace.inspections.listForCompany('company-a'),
          isEmpty,
        );
      },
    );

    test(
      'create upsert discards in-flight refresh that would wipe the new row',
      () async {
        final remote = _LatchingEquipmentRepository();
        final workspace = OfflineInspectionWorkspace.fromDatabase(
          database: openMemoryAppDatabase(),
          remoteEquipmentRepository: remote,
          authSession: FakeAuthSessionReader(),
        );
        addTearDown(workspace.dispose);

        remote.seed(const []);
        final firstStarted = Completer<void>();
        remote.onGetStarted = firstStarted.complete;
        final staleRefresh = workspace.catalogRefresh.refreshCompanyCatalog(
          'company-a',
        );
        await firstStarted.future;

        final syncing = LocalCatalogSyncingEquipmentRepository(
          remote: FakeEquipmentRepository(companyId: 'company-a'),
          localCatalog: workspace.equipmentCatalog,
          catalogRefresh: workspace.catalogRefresh,
        );
        final created = await syncing.createEquipment(
          EquipmentDetails.validated(
            assetName: 'Protected New',
            manufacturer: 'Caterpillar',
            model: '320',
          ),
        );

        remote.releaseGet();
        expect(await staleRefresh, isFalse);

        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-a',
            equipmentId: created.id,
          ),
          isNotNull,
        );
        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: created.id,
          createdByUserId: 'user-1',
        );
        expect(draft.equipmentId, created.id);
      },
    );

    test('stale catalog refresh does not overwrite a newer refresh', () async {
      final remote = _LatchingEquipmentRepository();
      final database = openMemoryAppDatabase();
      final workspace = OfflineInspectionWorkspace.fromDatabase(
        database: database,
        remoteEquipmentRepository: remote,
        authSession: FakeAuthSessionReader(),
      );
      addTearDown(workspace.dispose);

      final refresh = EquipmentCatalogRefreshService(
        remoteEquipmentRepository: remote,
        localCatalog: workspace.equipmentCatalog,
      );

      remote.seed([
        _equipment(id: 'old-1', companyId: 'company-a', assetName: 'Only Old'),
      ]);

      final firstStarted = Completer<void>();
      remote.onGetStarted = firstStarted.complete;
      final first = refresh.refreshCompanyCatalog('company-a');
      await firstStarted.future;

      remote.seed([
        _equipment(id: 'old-1', companyId: 'company-a', assetName: 'Only Old'),
        _equipment(id: 'new-1', companyId: 'company-a', assetName: 'Brand New'),
      ]);
      expect(await refresh.refreshCompanyCatalog('company-a'), isTrue);

      remote.releaseGet();
      await first;

      final cached = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(cached.map((e) => e.assetName), contains('Brand New'));
      expect(cached, hasLength(2));
    });

    test(
      'tenant isolation: upserted equipment is not visible to other companies',
      () async {
        final remote = FakeEquipmentRepository(companyId: 'company-a');
        final workspace = OfflineInspectionWorkspace.fromDatabase(
          database: openMemoryAppDatabase(),
          remoteEquipmentRepository: remote,
          authSession: FakeAuthSessionReader(),
        );
        addTearDown(workspace.dispose);

        final syncing = LocalCatalogSyncingEquipmentRepository(
          remote: remote,
          localCatalog: workspace.equipmentCatalog,
        );
        final created = await syncing.createEquipment(
          EquipmentDetails.validated(
            assetName: 'Tenant A Machine',
            manufacturer: 'Caterpillar',
            model: '320',
          ),
        );

        expect(
          await workspace.equipmentCatalog.listForCompany('company-b'),
          isEmpty,
        );
        expect(
          await workspace.equipmentCatalog.getById(
            companyId: 'company-b',
            equipmentId: created.id,
          ),
          isNull,
        );
        await expectLater(
          workspace.inspections.createDraft(
            companyId: 'company-b',
            equipmentId: created.id,
            createdByUserId: 'user-b',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Equipment.fromMap numeric coercion', () {
    test('accepts PostgREST numeric hours/year as strings', () {
      final equipment = Equipment.fromMap({
        'id': 'eq-1',
        'company_id': 'company-a',
        'asset_name': 'Loader',
        'manufacturer': 'John Deere',
        'model': '644',
        'serial_number': null,
        'year': '2022',
        'hours': '1234.5',
        'location': null,
        'notes': null,
        'created_by': null,
        'updated_by': null,
        'created_at': '2026-08-01T00:00:00.000Z',
        'updated_at': '2026-08-01T00:00:00.000Z',
      });
      expect(equipment.year, 2022);
      expect(equipment.hours, 1234.5);
    });
  });
}

Equipment _equipment({
  required String id,
  required String companyId,
  required String assetName,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Equipment(
    id: id,
    companyId: companyId,
    assetName: assetName,
    manufacturer: 'Caterpillar',
    model: '320',
    createdAt: now,
    updatedAt: now,
  );
}

/// Holds the first getEquipment call until [releaseGet] so overlapping refreshes
/// can be ordered deterministically in tests.
class _LatchingEquipmentRepository implements EquipmentRepository {
  List<Equipment> _equipment = const [];
  Completer<void>? _firstHold;
  bool _latchNextGet = true;
  void Function()? onGetStarted;

  void seed(List<Equipment> equipment) {
    _equipment = List.unmodifiable(equipment);
  }

  void releaseGet() {
    final hold = _firstHold;
    if (hold != null && !hold.isCompleted) {
      hold.complete();
    }
  }

  @override
  Future<List<Equipment>> getEquipment() async {
    if (_latchNextGet) {
      _latchNextGet = false;
      onGetStarted?.call();
      final hold = Completer<void>();
      _firstHold = hold;
      await hold.future;
      return _equipment;
    }
    return _equipment;
  }

  @override
  Future<Equipment?> getEquipmentById(String id) async {
    for (final item in _equipment) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Equipment> createEquipment(EquipmentDetails details) {
    throw UnimplementedError();
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEquipment(String id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isSerialNumberTaken(
    String serialNumber, {
    String? excludeEquipmentId,
  }) async {
    return false;
  }
}
