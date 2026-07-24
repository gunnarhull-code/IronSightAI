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
/// Session-aware startup and sign-in/sign-out transitions are owned by
/// [AuthGate] (`lib/features/auth/presentation/auth_gate.dart`). Named routes
/// remain available for login ↔ signup navigation and for any direct
/// navigation that still needs a stable path.
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.signup: (context) => const SignupScreen(),
  AppRoutes.dashboard: (context) => const DashboardScreen(),
};
