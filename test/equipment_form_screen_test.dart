import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/features/equipment/presentation/equipment_form_screen.dart';

import 'support/fake_equipment_repository.dart';

void main() {
  Equipment sampleEquipment({
    String? serialNumber,
    String? createdByName = 'Gunnar Hull',
    String? updatedByName = 'Alex Rep',
  }) {
    return Equipment(
      id: 'equipment-1',
      companyId: 'company-1',
      assetName: 'Excavator 1',
      manufacturer: 'Caterpillar',
      model: '320',
      year: 2019,
      hours: 1200,
      serialNumber: serialNumber,
      createdBy: 'user-1',
      createdByName: createdByName,
      updatedBy: 'user-2',
      updatedByName: updatedByName,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2, 3, 4),
    );
  }

  Future<void> tapButtonWithText(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(FilledButton, text));
    await tester.pumpAndSettle();
  }

  // Opens the manufacturer DropdownMenu and taps the matching entry. `.last`
  // is used because the field itself may already display matching text once
  // opened (the menu entry is added after the field in the widget tree).
  Future<void> selectManufacturer(
    WidgetTester tester,
    String manufacturer,
  ) async {
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(manufacturer).last);
    await tester.pumpAndSettle();
  }

  // The equipment form has enough fields that it scrolls in the default
  // 800x600 test surface; enlarging it (per test, via the test's own
  // tester.binding) keeps these tests focused on form behavior rather than
  // scroll-into-view mechanics.
  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('validation blocks create when required fields are empty', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tapButtonWithText(tester, 'Add Equipment');

    expect(find.text('Enter an asset name'), findsOneWidget);
    expect(find.text('Select a manufacturer'), findsOneWidget);
    expect(find.text('Enter a model'), findsOneWidget);
    expect(repository.createCallCount, 0);
  });

  testWidgets('creates equipment with valid input', (tester) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EquipmentFormScreen(repository: repository),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');

    await tapButtonWithText(tester, 'Add Equipment');

    expect(repository.createCallCount, 1);
    expect(repository.lastCreatedDetails?.assetName, 'Skid Steer');
    expect(repository.lastCreatedDetails?.manufacturer, 'Bobcat');
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'rejects free-typed manufacturer text that is not in the catalog',
    (tester) async {
      await useTallSurface(tester);
      final repository = FakeEquipmentRepository();

      await tester.pumpWidget(
        MaterialApp(home: EquipmentFormScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Asset Name'),
        'Skid Steer',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(DropdownMenu<String>),
          matching: find.byType(TextField),
        ),
        'Acme Machines',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'S650',
      );

      await tapButtonWithText(tester, 'Add Equipment');

      expect(find.text('Select a manufacturer from the list'), findsOneWidget);
      expect(repository.createCallCount, 0);
    },
  );

  testWidgets(
    'blocks save and shows a clear message for a duplicate serial number',
    (tester) async {
      await useTallSurface(tester);
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(serialNumber: 'ABC123')],
      );

      await tester.pumpWidget(
        MaterialApp(home: EquipmentFormScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Asset Name'),
        'Skid Steer',
      );
      await selectManufacturer(tester, 'Bobcat');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'S650',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serial Number'),
        'ABC123',
      );

      await tapButtonWithText(tester, 'Add Equipment');

      expect(
        find.text(
          'This serial number already exists for another piece of equipment.',
        ),
        findsOneWidget,
      );
      expect(repository.createCallCount, 0);
    },
  );

  testWidgets('rejects a year earlier than 1950 with a friendly message', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');
    await tester.enterText(find.widgetWithText(TextFormField, 'Year'), '1900');

    await tapButtonWithText(tester, 'Add Equipment');

    expect(find.text('Year must be 1950 or later'), findsOneWidget);
    expect(repository.createCallCount, 0);
  });

  testWidgets('rejects a year later than next year with a friendly message', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();
    final tooLate = DateTime.now().year + 2;

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Year'),
      '$tooLate',
    );

    await tapButtonWithText(tester, 'Add Equipment');

    final maxYear = DateTime.now().year + 1;
    expect(find.text('Year cannot be later than $maxYear'), findsOneWidget);
    expect(repository.createCallCount, 0);
  });

  testWidgets('rejects negative hours with a friendly message', (tester) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');
    await tester.enterText(find.widgetWithText(TextFormField, 'Hours'), '-5');

    await tapButtonWithText(tester, 'Add Equipment');

    expect(find.text('Hours cannot be negative'), findsOneWidget);
    expect(repository.createCallCount, 0);
  });

  testWidgets('loads and edits an existing equipment record', (tester) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentFormScreen(
          repository: repository,
          equipmentId: 'equipment-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Excavator 1'), findsOneWidget);
    // findsWidgets (not findsOneWidget): DropdownMenu keeps its menu entries
    // in the tree even while closed, so the field's own text and the
    // matching (offstage) menu entry both match here.
    expect(find.text('Caterpillar'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Excavator 1'),
      'Excavator 1 Updated',
    );

    await tapButtonWithText(tester, 'Save Changes');

    expect(repository.updateCallCount, 1);
    expect(repository.lastUpdatedId, 'equipment-1');
    expect(repository.lastUpdatedDetails?.assetName, 'Excavator 1 Updated');
    expect(repository.lastUpdatedDetails?.manufacturer, 'Caterpillar');
  });

  testWidgets('shows audit information when editing existing equipment', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentFormScreen(
          repository: repository,
          equipmentId: 'equipment-1',
          companyCountry: 'United States',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audit'), findsOneWidget);
    expect(find.text('Created By'), findsOneWidget);
    expect(find.text('Gunnar Hull'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('2025-12-31 19:00 UTC-5'), findsOneWidget);
    expect(find.text('Last Updated By'), findsOneWidget);
    expect(find.text('Alex Rep'), findsOneWidget);
    expect(find.text('Last Updated'), findsOneWidget);
    expect(find.text('2026-01-01 22:04 UTC-5'), findsOneWidget);
    expect(find.text('2026-01-02 03:04 UTC'), findsNothing);
  });

  testWidgets('audit timestamps follow the company country time zone', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository(equipment: [sampleEquipment()]);

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentFormScreen(
          repository: repository,
          equipmentId: 'equipment-1',
          companyCountry: 'Japan',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-01-01 09:00 UTC+9'), findsOneWidget);
    expect(find.text('2026-01-02 12:04 UTC+9'), findsOneWidget);
  });

  testWidgets('dirty form warning can keep editing with values preserved', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => EquipmentFormScreen(repository: repository),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Skid Steer'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('dirty form warning can discard without saving', (tester) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => EquipmentFormScreen(repository: repository),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(repository.createCallCount, 0);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Skid Steer'), findsNothing);
  });

  testWidgets(
    'editing keeps its own serial number without flagging a duplicate',
    (tester) async {
      await useTallSurface(tester);
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(serialNumber: 'ABC123')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EquipmentFormScreen(
            repository: repository,
            equipmentId: 'equipment-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapButtonWithText(tester, 'Save Changes');

      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdatedDetails?.serialNumber, 'ABC123');
    },
  );

  testWidgets('disables save and prevents duplicates while creating', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository(
      createDelay: const Duration(seconds: 1),
    );

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');

    await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
    await tester.pump();

    final savingButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(savingButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.createCallCount, 1);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(repository.createCallCount, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('shows visible error when repository create fails', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repository = FakeEquipmentRepository()
      ..createError = Exception('network unavailable');

    await tester.pumpWidget(
      MaterialApp(home: EquipmentFormScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await selectManufacturer(tester, 'Bobcat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');

    await tapButtonWithText(tester, 'Add Equipment');

    expect(
      find.text('Could not save equipment. Please try again.'),
      findsOneWidget,
    );
  });
}
