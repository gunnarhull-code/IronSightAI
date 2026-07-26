import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/use_cases/create_company_for_current_user.dart';
import 'package:ironsight_ai/features/company/presentation/company_onboarding_screen.dart';

import 'support/fake_company_repository.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required FakeCompanyRepository repository,
    VoidCallback? onCompleted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyOnboardingScreen(
          createCompany: CreateCompanyForCurrentUser(repository),
          onCompleted: onCompleted ?? () {},
        ),
      ),
    );
  }

  Future<void> openOnboardingRoute(
    WidgetTester tester, {
    required FakeCompanyRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyOnboardingScreen(
                      createCompany: CreateCompanyForCurrentUser(repository),
                      onCompleted: () {},
                    ),
                  ),
                );
              },
              child: const Text('Open Onboarding'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Onboarding'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates a company with a valid name', (tester) async {
    final repository = FakeCompanyRepository();
    var completed = false;

    await pumpOnboarding(
      tester,
      repository: repository,
      onCompleted: () => completed = true,
    );

    await tester.enterText(find.byType(TextFormField), 'Hull Equipment');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.createCallCount, 1);
    expect(repository.lastCreatedName, 'Hull Equipment');
    expect(completed, isTrue);
  });

  testWidgets('validation failure prevents company create', (tester) async {
    final repository = FakeCompanyRepository();

    await pumpOnboarding(tester, repository: repository);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Company name is required'), findsOneWidget);
    expect(repository.createCallCount, 0);
  });

  testWidgets('disables continue and prevents duplicates while creating', (
    tester,
  ) async {
    final repository = FakeCompanyRepository(
      createDelay: const Duration(seconds: 1),
    );

    await pumpOnboarding(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Hull Equipment');
    await tester.pump();

    await tester.tap(find.text('Continue'));
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

  testWidgets('warns before leaving a modified company create form', (
    tester,
  ) async {
    final repository = FakeCompanyRepository();

    await openOnboardingRoute(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Hull Equipment');
    await tester.pump();

    // Onboarding has no AppBar back control; simulate the system back gesture.
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('You have unsaved company changes.'), findsOneWidget);

    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your company'), findsOneWidget);
    expect(find.text('Hull Equipment'), findsOneWidget);
    expect(find.text('Open Onboarding'), findsNothing);
  });

  testWidgets('repository create failure shows visible error', (tester) async {
    final repository = FakeCompanyRepository()
      ..createError = Exception('network unavailable');

    await pumpOnboarding(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Hull Equipment');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.createCallCount, 1);
    expect(
      find.text('Could not create company. Please try again.'),
      findsOneWidget,
    );
  });
}
