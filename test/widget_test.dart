// Basic smoke test for the IronSight AI application shell.
//
// Note: this test launches [IronSightApp] directly, which does not invoke
// [bootstrap]. That means Supabase / dotenv are not initialized — which is
// intentional for a pure UI smoke test, and is why this test only asserts
// that the login screen's static chrome renders (not that auth works).

import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/app/app.dart';

void main() {
  testWidgets('IronSightApp renders the login screen as initial route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IronSightApp());

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
