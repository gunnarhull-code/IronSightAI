import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';

/// Named route identifiers for the app.
///
/// Uses Flutter's built-in named-routes API (no third-party routing
/// package), per the approved V1 tech stack. Add a new constant here and a
/// matching entry in [appRoutes] as each new screen is implemented.
abstract final class AppRoutes {
  static const String dashboard = '/';
}

/// Route table consumed by [MaterialApp.routes].
///
/// [AppRoutes.dashboard] is also used as [MaterialApp.initialRoute], making
/// the dashboard the app's initial screen.
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.dashboard: (context) => const DashboardScreen(),
};
