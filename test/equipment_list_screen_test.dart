import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/features/equipment/presentation/equipment_list_screen.dart';

import 'support/fake_equipment_repository.dart';

void main() {
  Equipment sampleEquipment() {
    return Equipment(
      id: 'equipment-1',
      companyId: 'company-1',
      assetName: 'Excavator 1',
      manufacturer: 'Caterpillar',
      model: '320',
      year: 2019,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  testWidgets('shows empty state when there is no equipment', (tester) async {
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(home: EquipmentListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No equipment yet'), findsOneWidget);
    expect(find.text('Add Equipment'), findsWidgets);
  });

  testWidgets('lists equipment returned by the repository', (tester) async {
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await tester.pumpWidget(
      MaterialApp(home: EquipmentListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Excavator 1'), findsOneWidget);
    expect(find.textContaining('Caterpillar'), findsOneWidget);
    expect(find.text('No equipment yet'), findsNothing);
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
