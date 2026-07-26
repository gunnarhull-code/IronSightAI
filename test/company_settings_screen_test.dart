import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/entities/company_role.dart';
import 'package:ironsight_ai/features/company/presentation/company_settings_screen.dart';

import 'support/fake_company_repository.dart';

void main() {
  Company sampleCompany({
    String name = 'Hull Equipment',
    String? region = 'Midwest',
  }) {
    return Company(
      id: 'company-1',
      name: name,
      region: region,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    FakeCompanyRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CompanySettingsScreen(repository: repository)),
    );
  }

  Future<void> openSettingsRoute(
    WidgetTester tester,
    FakeCompanyRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CompanySettingsScreen(repository: repository),
                  ),
                );
              },
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('loads the current company settings', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Basic company information'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('company-1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Company name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Region'), findsOneWidget);
  });

  testWidgets('owner can edit company name and region', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.enterText(find.byType(TextFormField).at(1), 'Great Lakes');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCallCount, 1);
    expect(repository.lastUpdatedName, 'Iron Rentals');
    expect(repository.lastUpdatedRegion, 'Great Lakes');
    expect(find.text('Company settings saved.'), findsWidgets);
  });

  testWidgets('validation failure prevents company update', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Company name is required'), findsOneWidget);
    expect(repository.updateCallCount, 0);
  });

  testWidgets('save stays disabled until settings are modified', (
    tester,
  ) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    final pristineSave = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );
    expect(pristineSave.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.pump();

    final dirtySave = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );
    expect(dirtySave.onPressed, isNotNull);
  });

  testWidgets('disables save and prevents duplicates while saving', (
    tester,
  ) async {
    final repository = FakeCompanyRepository(
      company: sampleCompany(),
      updateDelay: const Duration(seconds: 1),
    );

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    final savingButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(savingButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.updateCallCount, 1);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(repository.updateCallCount, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('warns before leaving a modified company form', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await openSettingsRoute(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text('You have unsaved company settings changes.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.text('Basic company information'), findsOneWidget);
    expect(find.text('Iron Rentals'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
  });

  testWidgets('discarding unsaved company changes leaves the form', (
    tester,
  ) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await openSettingsRoute(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Basic company information'), findsNothing);
  });

  testWidgets('repository update failure shows visible error', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany())
      ..updateError = Exception('network unavailable');

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Iron Rentals');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCallCount, 1);
    expect(
      find.text('Could not save company settings. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('inspector role is read-only', (tester) async {
    final repository = FakeCompanyRepository(
      company: sampleCompany(),
      role: CompanyRole.inspector,
    );

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    final regionField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );

    expect(find.text('Inspector'), findsOneWidget);
    expect(nameField.enabled, isFalse);
    expect(regionField.enabled, isFalse);
    expect(saveButton.onPressed, isNull);
    expect(
      find.text('Your role is read-only for company settings.'),
      findsOneWidget,
    );
  });
}
