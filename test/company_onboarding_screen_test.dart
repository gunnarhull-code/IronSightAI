import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/use_cases/create_company_for_current_user.dart';
import 'package:ironsight_ai/features/company/presentation/company_onboarding_screen.dart';

import 'support/fake_company_repository.dart';

void main() {
  CreateCompanyForCurrentUser createUseCase(FakeCompanyRepository repository) {
    return CreateCompanyForCurrentUser(repository);
  }

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required FakeCompanyRepository repository,
    VoidCallback? onCompleted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyOnboardingScreen(
          createCompany: createUseCase(repository),
          onCompleted: onCompleted ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('autofocuses company name when onboarding opens', (tester) async {
    final repository = FakeCompanyRepository();

    await pumpOnboarding(tester, repository: repository);

    final editable = find.descendant(
      of: find.widgetWithText(TextFormField, 'Company Name'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  });

  testWidgets('company name field disables browser autofill hints', (
    tester,
  ) async {
    final repository = FakeCompanyRepository();

    await pumpOnboarding(tester, repository: repository);

    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Company Name'),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.autofillHints, isNull);
  });

  testWidgets('Enter submits onboarding when company name is valid', (
    tester,
  ) async {
    final repository = FakeCompanyRepository();
    var completed = false;

    await pumpOnboarding(
      tester,
      repository: repository,
      onCompleted: () => completed = true,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company Name'),
      'Hull Equipment',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(repository.createCallCount, 1);
  });

  testWidgets('Enter does not submit invalid onboarding form', (tester) async {
    final repository = FakeCompanyRepository();
    var completed = false;

    await pumpOnboarding(
      tester,
      repository: repository,
      onCompleted: () => completed = true,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Enter your company name'), findsOneWidget);
    expect(completed, isFalse);
    expect(repository.createCallCount, 0);
  });
}
