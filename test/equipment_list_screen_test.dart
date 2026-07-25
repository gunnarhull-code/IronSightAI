import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/features/equipment/presentation/equipment_list_screen.dart';

import 'support/fake_equipment_repository.dart';

void main() {
  Equipment sampleEquipment({
    String id = 'equipment-1',
    String assetName = 'Excavator 1',
    String manufacturer = 'Caterpillar',
    String model = '320',
    String? serialNumber,
    String? location,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.utc(2026, 1, 1);
    return Equipment(
      id: id,
      companyId: 'company-1',
      assetName: assetName,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      location: location,
      year: 2019,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Future<void> pumpList(
    WidgetTester tester,
    FakeEquipmentRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: EquipmentListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectManufacturerFilter(
    WidgetTester tester,
    String manufacturer,
  ) async {
    await tester.tap(
      find.byKey(const ValueKey('equipment-manufacturer-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(manufacturer).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectSort(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('equipment-sort-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  void expectEquipmentOrder(WidgetTester tester, List<String> assetNames) {
    var previousTop = double.negativeInfinity;
    for (final assetName in assetNames) {
      final top = tester.getTopLeft(find.text(assetName)).dy;
      expect(top, greaterThan(previousTop));
      previousTop = top;
    }
  }

  testWidgets('shows empty state when there is no equipment', (tester) async {
    final repository = FakeEquipmentRepository();

    await pumpList(tester, repository);

    expect(find.text('No equipment yet'), findsOneWidget);
    expect(find.text('Add Equipment'), findsWidgets);
  });

  testWidgets('lists equipment returned by the repository', (tester) async {
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await pumpList(tester, repository);

    expect(find.text('Excavator 1'), findsOneWidget);
    expect(find.textContaining('Caterpillar'), findsOneWidget);
    expect(find.text('No equipment yet'), findsNothing);
  });

  testWidgets('searches equipment fields as the user types', (tester) async {
    final repository = FakeEquipmentRepository(
      equipment: [
        sampleEquipment(
          id: 'equipment-1',
          assetName: 'Excavator 1',
          manufacturer: 'Caterpillar',
          model: '320',
          serialNumber: 'CAT-320-001',
          location: 'North Yard',
        ),
        sampleEquipment(
          id: 'equipment-2',
          assetName: 'Skid Steer 2',
          manufacturer: 'Bobcat',
          model: 'S650',
          serialNumber: 'BOB-S650-002',
          location: 'South Yard',
        ),
      ],
    );
    await pumpList(tester, repository);

    final searchField = find.byKey(const ValueKey('equipment-search-field'));

    await tester.enterText(searchField, 'skid');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);

    await tester.enterText(searchField, 'bobcat');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);

    await tester.enterText(searchField, 's650');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);

    await tester.enterText(searchField, 'BOB-S650');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);

    await tester.enterText(searchField, 'south yard');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);

    await tester.enterText(searchField, '');
    await tester.pump();
    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsOneWidget);
  });

  testWidgets('filters equipment by manufacturer and can reset to all', (
    tester,
  ) async {
    final repository = FakeEquipmentRepository(
      equipment: [
        sampleEquipment(assetName: 'Excavator 1', manufacturer: 'Caterpillar'),
        sampleEquipment(
          id: 'equipment-2',
          assetName: 'Skid Steer 2',
          manufacturer: 'Bobcat',
          model: 'S650',
        ),
      ],
    );
    await pumpList(tester, repository);

    await selectManufacturerFilter(tester, 'Caterpillar');

    expect(find.text('Excavator 1'), findsOneWidget);
    expect(find.text('Skid Steer 2'), findsNothing);

    await selectManufacturerFilter(tester, 'All Manufacturers');

    expect(find.text('Skid Steer 2'), findsOneWidget);
    expect(find.text('Excavator 1'), findsOneWidget);
  });

  testWidgets('sorts equipment by each supported option', (tester) async {
    final repository = FakeEquipmentRepository(
      equipment: [
        sampleEquipment(
          id: 'equipment-1',
          assetName: 'Beta Loader',
          manufacturer: 'Bobcat',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        sampleEquipment(
          id: 'equipment-2',
          assetName: 'Alpha Excavator',
          manufacturer: 'Komatsu',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
        sampleEquipment(
          id: 'equipment-3',
          assetName: 'Delta Skid Steer',
          manufacturer: 'Caterpillar',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ],
    );
    await pumpList(tester, repository);

    expectEquipmentOrder(tester, [
      'Alpha Excavator',
      'Delta Skid Steer',
      'Beta Loader',
    ]);

    await selectSort(tester, 'Oldest');
    expectEquipmentOrder(tester, [
      'Beta Loader',
      'Delta Skid Steer',
      'Alpha Excavator',
    ]);

    await selectSort(tester, 'Asset Name (A-Z)');
    expectEquipmentOrder(tester, [
      'Alpha Excavator',
      'Beta Loader',
      'Delta Skid Steer',
    ]);

    await selectSort(tester, 'Manufacturer (A-Z)');
    expectEquipmentOrder(tester, [
      'Beta Loader',
      'Delta Skid Steer',
      'Alpha Excavator',
    ]);
  });

  testWidgets('FAB navigates to the create route', (tester) async {
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentListScreen(repository: repository),
        // Uses onGenerateRoute (not the `routes:` map) so the built route's
        // generic type matches EquipmentListScreen's pushNamed<bool?> call —
        // the `routes:` map always builds MaterialPageRoute<dynamic>, which
        // cannot be cast to Route<bool?> at runtime.
        onGenerateRoute: (settings) {
          if (settings.name == '/equipment/new') {
            return MaterialPageRoute<bool?>(
              builder: (context) => const Scaffold(body: Text('Create Screen')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create Screen'), findsOneWidget);
  });

  testWidgets('tapping an item navigates to its edit route', (tester) async {
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentListScreen(repository: repository),
        onGenerateRoute: (settings) {
          if (settings.name == '/equipment/edit/equipment-1') {
            return MaterialPageRoute<bool?>(
              builder: (context) => const Scaffold(body: Text('Edit Screen')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excavator 1'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Screen'), findsOneWidget);
  });
}
