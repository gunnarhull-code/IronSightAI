import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'router.dart';

/// Root widget of the IronSight AI application.
class IronSightApp extends StatelessWidget {
  const IronSightApp({super.key, this.authGate});

  /// Optional override for [AuthGate], primarily used by widget tests that
  /// do not initialize Supabase.
  final Widget? authGate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronSight AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authGate ?? const AuthGate(),
      routes: appRoutes,
    );
  }
}
