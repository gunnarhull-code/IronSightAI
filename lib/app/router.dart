import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

/// Named route identifiers for the app.
///
/// Uses Flutter's built-in named-routes API (no third-party routing
/// package), per the approved V1 tech stack. Add a new constant here and a
/// matching entry in [appRoutes] as each new screen is implemented.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
}

/// Route table consumed by [MaterialApp.routes].
///
/// [AppRoutes.login] is also used as [MaterialApp.initialRoute] for now.
/// This is deliberately simple: it does not yet check for an existing
/// session and route straight to the dashboard — that is session-aware
/// startup routing, to be added alongside company/role context loading
/// (docs/13-roadmap.md, Weeks 1-2; management/sprints/SPRINT-1.md, Task 15).
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.signup: (context) => const SignupScreen(),
  AppRoutes.dashboard: (context) => const DashboardScreen(),
};
