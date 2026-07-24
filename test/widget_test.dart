// Smoke tests for session-aware routing via AuthGate.
//
// These tests do not initialize Supabase / dotenv. AuthGate is given explicit
// signed-in overrides so the UI can be exercised in isolation.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/app/app.dart';
import 'package:ironsight_ai/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets('AuthGate shows login when there is no session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          isSignedIn: () => false,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('AuthGate shows dashboard when a session exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          isSignedIn: () => true,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    expect(find.text('Start Quick Appraisal'), findsOneWidget);
  });

  testWidgets('AuthGate switches to dashboard when signed-in becomes true', (
    WidgetTester tester,
  ) async {
    final signedIn = StreamController<bool>.broadcast();
    addTearDown(signedIn.close);

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          isSignedIn: () => false,
          onSignedInChanged: () => signedIn.stream,
        ),
      ),
    );

    expect(find.text('Sign in to continue'), findsOneWidget);

    signedIn.add(true);
    await tester.pump();

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsNothing);
  });

  testWidgets('AuthGate switches to login when signed-in becomes false', (
    WidgetTester tester,
  ) async {
    final signedIn = StreamController<bool>.broadcast();
    addTearDown(signedIn.close);

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          isSignedIn: () => true,
          onSignedInChanged: () => signedIn.stream,
        ),
      ),
    );

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);

    signedIn.add(false);
    await tester.pump();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsNothing);
  });
}
