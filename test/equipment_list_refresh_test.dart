// Regression test for a bug where EquipmentListScreen did not refresh after
// a successful create/edit without leaving and re-entering the screen.
//
// Root cause: `setState(() => _equipmentFuture = _getEquipmentList())` used
// an arrow-function body, whose implicit return value is the assignment's
// value (a Future). setState() asserts its callback returns void and throws
// before calling markNeedsBuild() when it doesn't, so the field was
// reassigned but the widget was never told to rebuild.
//
// Exercises the real production route builder (buildAppRoute) rather than a
// simplified stub, so this test would have caught the wiring-specific bug.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/app/router.dart';
import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/features/equipment/presentation/equipment_list_screen.dart';

import 'support/fake_company_repository.dart';
import 'support/fake_equipment_repository.dart';

void main() {
  Future<void> pumpEquipmentList(
    WidgetTester tester, {
    required FakeEquipmentRepository equipmentRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final companyRepository = FakeCompanyRepository(
      company: Company(
        id: 'company-1',
        name: 'Hull Equipment',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentListScreen(repository: equipmentRepository),
        onGenerateRoute: (settings) => buildAppRoute(
          settings,
          companyRepository: companyRepository,
          equipmentRepository: equipmentRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list refreshes after create without leaving the screen', (
    tester,
  ) async {
    final equipmentRepository = FakeEquipmentRepository();
    await pumpEquipmentList(tester, equipmentRepository: equipmentRepository);

    expect(find.text('No equipment yet'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asset Name'),
      'Skid Steer',
    );
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bobcat').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'S650');

    await tester.tap(find.widgetWithText(FilledButton, 'Add Equipment'));
    await tester.pumpAndSettle();

    expect(find.text('Skid Steer'), findsOneWidget);
    expect(find.text('No equipment yet'), findsNothing);
    expect(equipmentRepository.createCallCount, 1);
  });

  testWidgets('list refreshes after edit without leaving the screen', (
    tester,
  ) async {
    final equipmentRepository = FakeEquipmentRepository(
      equipment: [
        Equipment(
          id: 'equipment-1',
          companyId: 'company-1',
          assetName: 'Excavator 1',
          manufacturer: 'Caterpillar',
          model: '320',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
    await pumpEquipmentList(tester, equipmentRepository: equipmentRepository);

    expect(find.text('Excavator 1'), findsOneWidget);

    await tester.tap(find.text('Excavator 1'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Excavator 1'),
      'Excavator 1 Updated',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Excavator 1 Updated'), findsOneWidget);
    expect(find.text('Excavator 1'), findsNothing);
    expect(equipmentRepository.updateCallCount, 1);
  });
}
