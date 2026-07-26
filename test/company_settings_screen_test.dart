import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/entities/company_role.dart';
import 'package:ironsight_ai/features/company/presentation/company_settings_screen.dart';

import 'support/fake_company_repository.dart';

void main() {
  Company sampleCompany({
    String name = 'Hull Equipment',
    String? region = 'United States',
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

  Finder countryTextField() {
    return find.descendant(
      of: find.byKey(const Key('company_country_dropdown')),
      matching: find.byType(TextField),
    );
  }

  Future<void> selectCountry(WidgetTester tester, String country) async {
    // Filter first so the target entry is on-screen in the long catalog.
    await tester.tap(find.byKey(const Key('company_country_dropdown')));
    await tester.pumpAndSettle();
    await tester.enterText(countryTextField(), country);
    await tester.pumpAndSettle();
    await tester.tap(find.text(country).last);
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
    expect(find.byKey(const Key('company_country_dropdown')), findsOneWidget);
    expect(find.text('Region'), findsNothing);

    final countryField = tester.widget<TextField>(countryTextField());
    expect(countryField.controller?.text, 'United States');
  });

  testWidgets('owner can edit company name and country', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Iron Rentals');
    await selectCountry(tester, 'Canada');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCallCount, 1);
    expect(repository.lastUpdatedName, 'Iron Rentals');
    expect(repository.lastUpdatedRegion, 'Canada');
    expect(find.text('Company settings saved.'), findsWidgets);
  });

  testWidgets('legacy free-text region still loads and can be saved', (
    tester,
  ) async {
    final repository = FakeCompanyRepository(
      company: sampleCompany(region: 'Midwest'),
    );

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    final countryField = tester.widget<TextField>(countryTextField());
    expect(countryField.controller?.text, 'Midwest');

    await tester.enterText(
      find.byType(TextFormField).first,
      'Hull Equipment Co',
    );
    await tester.pump();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCallCount, 1);
    expect(repository.lastUpdatedName, 'Hull Equipment Co');
    expect(repository.lastUpdatedRegion, 'Midwest');
  });

  testWidgets('validation failure prevents company update', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Enter company name'), findsOneWidget);
    expect(repository.updateCallCount, 0);
  });

  testWidgets('invalid country search text prevents save', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany());

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(countryTextField(), 'Not A Real Country');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Select a country from the list'), findsOneWidget);
    expect(repository.updateCallCount, 0);
  });

  testWidgets('repository update failure shows visible error', (tester) async {
    final repository = FakeCompanyRepository(company: sampleCompany())
      ..updateError = Exception('network unavailable');

    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Iron Rentals');
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
      find.byType(TextFormField).first,
    );
    final countryMenu = tester.widget<DropdownMenu<String>>(
      find.byKey(const Key('company_country_dropdown')),
    );
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );

    expect(find.text('Inspector'), findsOneWidget);
    expect(nameField.enabled, isFalse);
    expect(countryMenu.enabled, isFalse);
    expect(saveButton.onPressed, isNull);
    expect(
      find.text('Your role is read-only for company settings.'),
      findsOneWidget,
    );
  });
}
