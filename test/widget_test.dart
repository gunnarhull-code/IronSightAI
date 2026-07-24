// Basic smoke test for the IronSight AI application shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/app/app.dart';

void main() {
  testWidgets('IronSightApp renders the dashboard shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IronSightApp());

    expect(find.text('IronSight AI'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
  });
}
