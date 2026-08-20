import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/repositories/local_catalog_syncing_equipment_repository.dart';
import 'package:ironsight_ai/data/services/equipment_catalog_refresh_service.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/exceptions/equipment_local_catalog_mirror_exception.dart';
import 'package:ironsight_ai/features/equipment/presentation/equipment_form_screen.dart';

import 'support/fake_equipment_repository.dart';
import 'support/fake_local_equipment_catalog_repository.dart';

void main() {
  Equipment sampleEquipment({String id = 'equipment-1'}) {
    return Equipment(
      id: id,
      companyId: 'company-1',
      assetName: 'Excavator 1',
      manufacturer: 'Caterpillar',
      model: '320',
      serialNumber: 'SN-1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  LocalCatalogSyncingEquipmentRepository buildSyncing({
    required FakeEquipmentRepository remote,
    required FakeLocalEquipmentCatalogRepository local,
  }) {
    final refresh = EquipmentCatalogRefreshService(
      remoteEquipmentRepository: remote,
      localCatalog: local,
    );
    return LocalCatalogSyncingEquipmentRepository(
      remoteEquipmentRepository: remote,
      catalogRefreshService: refresh,
    );
  }

  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> fillCreateForm(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bobcat').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');
  }

  group('EquipmentFormScreen partial local mirror recovery', () {
    testWidgets(
      'create partial success shows message and avoids duplicate remote create',
      (tester) async {
        await useTallSurface(tester);
        final remote = FakeEquipmentRepository();
        final local = FakeLocalEquipmentCatalogRepository()
          ..upsertError = StateError('local write failed');
        final syncing = buildSyncing(remote: remote, local: local);

        await tester.pumpWidget(
          MaterialApp(home: EquipmentFormScreen(repository: syncing)),
        );
        await tester.pumpAndSettle();
        await fillCreateForm(tester);

        await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
        await tester.pumpAndSettle();

        expect(remote.createCallCount, 1);
        expect(
          find.text(
            EquipmentLocalCatalogMirrorException.messageFor(
              EquipmentRemoteSaveOperation.create,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Could not save equipment. Please try again.'),
          findsNothing,
        );
        expect(
          find.widgetWithText(FilledButton, 'Save on this device'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'Save on this device'),
        );
        await tester.pumpAndSettle();

        expect(remote.createCallCount, 1);
        expect(local.upsertCallCount, 2);
      },
    );

    testWidgets('recovery completes the form after local mirror succeeds', (
      tester,
    ) async {
      await useTallSurface(tester);
      final remote = FakeEquipmentRepository();
      final local = FakeLocalEquipmentCatalogRepository()
        ..upsertError = StateError('local write failed');
      final syncing = buildSyncing(remote: remote, local: local);
      var poppedResult = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              EquipmentFormScreen(repository: syncing),
                        ),
                      );
                      poppedResult = result == true;
                    },
                    child: const Text('Open form'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await fillCreateForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
      await tester.pumpAndSettle();

      local.upsertError = null;
      await tester.tap(
        find.widgetWithText(FilledButton, 'Save on this device'),
      );
      await tester.pumpAndSettle();

      expect(remote.createCallCount, 1);
      expect(poppedResult, isTrue);
      expect(find.text('Equipment saved on this device.'), findsOneWidget);
      expect(local.storedFor('company-1'), hasLength(1));
    });

    testWidgets('repeated failed recovery never repeats the remote create', (
      tester,
    ) async {
      await useTallSurface(tester);
      final remote = FakeEquipmentRepository();
      final local = FakeLocalEquipmentCatalogRepository()
        ..upsertError = StateError('local write failed');
      final syncing = buildSyncing(remote: remote, local: local);

      await tester.pumpWidget(
        MaterialApp(home: EquipmentFormScreen(repository: syncing)),
      );
      await tester.pumpAndSettle();
      await fillCreateForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
      await tester.pumpAndSettle();

      for (var attempt = 0; attempt < 3; attempt++) {
        await tester.tap(
          find.widgetWithText(FilledButton, 'Save on this device'),
        );
        await tester.pumpAndSettle();
      }

      expect(remote.createCallCount, 1);
      expect(local.upsertCallCount, 4);
      expect(
        find.text(
          EquipmentLocalCatalogMirrorException.messageFor(
            EquipmentRemoteSaveOperation.create,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('edit partial success uses local-only recovery', (
      tester,
    ) async {
      await useTallSurface(tester);
      final remote = FakeEquipmentRepository(equipment: [sampleEquipment()]);
      final local = FakeLocalEquipmentCatalogRepository()
        ..upsertError = StateError('local write failed');
      await local.replaceCompanyCatalog(
        companyId: 'company-1',
        equipment: [sampleEquipment()],
      );
      final syncing = buildSyncing(remote: remote, local: local);

      await tester.pumpWidget(
        MaterialApp(
          home: EquipmentFormScreen(
            repository: syncing,
            equipmentId: 'equipment-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Excavator 1'),
        'Excavator Updated',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(remote.updateCallCount, 1);
      expect(
        find.text(
          EquipmentLocalCatalogMirrorException.messageFor(
            EquipmentRemoteSaveOperation.update,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Save on this device'),
        findsOneWidget,
      );

      local.upsertError = null;
      await tester.tap(
        find.widgetWithText(FilledButton, 'Save on this device'),
      );
      await tester.pumpAndSettle();

      expect(remote.updateCallCount, 1);
      expect(
        local.storedFor('company-1').single.assetName,
        'Excavator Updated',
      );
    });

    testWidgets('genuine remote failure still allows normal save retry', (
      tester,
    ) async {
      await useTallSurface(tester);
      final remote = FakeEquipmentRepository()
        ..createError = Exception('offline');
      final local = FakeLocalEquipmentCatalogRepository();
      final syncing = buildSyncing(remote: remote, local: local);

      await tester.pumpWidget(
        MaterialApp(home: EquipmentFormScreen(repository: syncing)),
      );
      await tester.pumpAndSettle();
      await fillCreateForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
      await tester.pumpAndSettle();

      expect(remote.createCallCount, 1);
      expect(local.upsertCallCount, 0);
      expect(
        find.text('Could not save equipment. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Add Equipment'),
        findsOneWidget,
      );

      remote.createError = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
      await tester.pumpAndSettle();

      expect(remote.createCallCount, 2);
      expect(local.storedFor('company-1'), hasLength(1));
    });
  });
}
