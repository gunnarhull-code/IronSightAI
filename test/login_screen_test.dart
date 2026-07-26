import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/features/auth/presentation/login_screen.dart';

void main() {
  Finder emailField() => find.widgetWithText(TextFormField, 'Email');
  Finder passwordField() => find.widgetWithText(TextFormField, 'Password');

  bool fieldHasFocus(WidgetTester tester, Finder fieldFinder) {
    final editable = find.descendant(
      of: fieldFinder,
      matching: find.byType(EditableText),
    );
    return tester.widget<EditableText>(editable).focusNode.hasFocus;
  }

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();
  }

  testWidgets('does not autofocus the email field when login opens', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(fieldHasFocus(tester, emailField()), isFalse);
  });

  testWidgets('Enter in email moves focus to password', (tester) async {
    await pumpLogin(tester);

    await tester.tap(emailField());
    await tester.pump();
    await tester.enterText(emailField(), 'user@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(fieldHasFocus(tester, passwordField()), isTrue);
  });

  testWidgets('Enter in password does not submit an invalid login form', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(passwordField());
    await tester.pump();
    await tester.enterText(passwordField(), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    // Validation blocked submit — no in-progress spinner.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tab order moves email -> password -> sign in', (tester) async {
    await pumpLogin(tester);

    await tester.tap(emailField());
    await tester.pump();
    expect(fieldHasFocus(tester, emailField()), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(fieldHasFocus(tester, passwordField()), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    expect(
      find.ancestor(
        of: find.byWidget(focused!.context!.widget),
        matching: find.widgetWithText(FilledButton, 'Sign In'),
      ),
      findsOneWidget,
    );
  });
}
