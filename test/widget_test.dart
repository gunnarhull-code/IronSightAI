// Smoke tests for session-aware and company-aware routing.
//
// These tests do not initialize Supabase / dotenv. Gates are given explicit
// overrides / fake repositories so the UI can be exercised in isolation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/app/app.dart';
import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/features/auth/presentation/auth_gate.dart';
import 'package:ironsight_ai/features/company/presentation/company_gate.dart';
import 'package:ironsight_ai/features/dashboard/presentation/dashboard_screen.dart';

import 'support/fake_company_repository.dart';

void main() {
  final sampleCompany = Company(
    id: 'company-1',
    name: 'Hull Equipment',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  testWidgets('AuthGate shows login when there is no session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(
            repository: FakeCompanyRepository(company: sampleCompany),
          ),
          isSignedIn: () => false,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('CompanyGate shows dashboard when user belongs to a company', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(
            repository: FakeCompanyRepository(company: sampleCompany),
          ),
          isSignedIn: () => true,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    expect(find.text('Start Quick Appraisal'), findsOneWidget);
    expect(find.text('Local inspection workspace unavailable'), findsOneWidget);
  });

  testWidgets('CompanyGate shows onboarding when user has no company', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(repository: FakeCompanyRepository()),
          isSignedIn: () => true,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up your company'), findsOneWidget);
    expect(find.text('Company Name'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('CompanyGate shows Retry when repository throws', (
    WidgetTester tester,
  ) async {
    final repository = FakeCompanyRepository(
      getError: Exception('network unavailable'),
    );

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(repository: repository),
          isSignedIn: () => true,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load your company. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Set up your company'), findsNothing);
    expect(find.text('Heavy Equipment Inspections'), findsNothing);

    repository
      ..getError = null
      ..company = sampleCompany;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('Onboarding Continue creates company and opens dashboard', (
    WidgetTester tester,
  ) async {
    final repository = FakeCompanyRepository();

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(repository: repository),
          isSignedIn: () => true,
          onSignedInChanged: () => const Stream<bool>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Hull Equipment');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.createCallCount, 1);
    expect(repository.lastCreatedName, 'Hull Equipment');
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
  });

  testWidgets(
    'AuthGate switches to signed-in home when signed-in becomes true',
    (WidgetTester tester) async {
      final signedIn = StreamController<bool>.broadcast();
      addTearDown(signedIn.close);

      await tester.pumpWidget(
        IronSightApp(
          authGate: AuthGate(
            signedInHome: CompanyGate(
              repository: FakeCompanyRepository(company: sampleCompany),
            ),
            isSignedIn: () => false,
            onSignedInChanged: () => signedIn.stream,
          ),
        ),
      );

      expect(find.text('Sign in to continue'), findsOneWidget);

      signedIn.add(true);
      await tester.pumpAndSettle();

      expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsNothing);
    },
  );

  testWidgets('AuthGate switches to login when signed-in becomes false', (
    WidgetTester tester,
  ) async {
    final signedIn = StreamController<bool>.broadcast();
    addTearDown(signedIn.close);

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(
            repository: FakeCompanyRepository(company: sampleCompany),
          ),
          isSignedIn: () => true,
          onSignedInChanged: () => signedIn.stream,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);

    signedIn.add(false);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsNothing);
  });

  testWidgets('Dashboard Sign Out calls auth action without navigation', (
    WidgetTester tester,
  ) async {
    var signOutCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          signOut: () async {
            signOutCallCount += 1;
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    expect(signOutCallCount, 1);
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsNothing);
  });

  testWidgets('Dashboard Sign Out shows loading while pending', (
    WidgetTester tester,
  ) async {
    final signOut = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(home: DashboardScreen(signOut: () => signOut.future)),
    );

    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    signOut.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Dashboard Sign Out shows an error when sign out fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          signOut: () async {
            throw Exception('network unavailable');
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Could not sign out. Please try again.'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
  });
}
