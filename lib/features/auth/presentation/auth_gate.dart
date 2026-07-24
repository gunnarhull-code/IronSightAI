import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Session-aware root gate for IronSight AI.
///
/// On startup, checks `Supabase.instance.client.auth.currentSession` and shows
/// either [signedInHome] (session present) or the login flow (no session).
/// Listens to auth state changes so sign-in and sign-out navigation stay
/// centralized here instead of on individual screens.
///
/// [signedInHome] is typically a [CompanyGate] wired from `app/` so tenancy
/// routing stays out of this widget while auth stays centralized.
///
/// [isSignedIn] and [onSignedInChanged] are override hooks for widget tests
/// that do not initialize Supabase via bootstrap.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.signedInHome,
    this.isSignedIn,
    this.onSignedInChanged,
  });

  /// Shown when the user has an active session (e.g. [CompanyGate]).
  final Widget signedInHome;

  /// Optional signed-in check used instead of reading the Supabase session.
  final bool Function()? isSignedIn;

  /// Optional signed-in stream used instead of Supabase auth state changes.
  final Stream<bool> Function()? onSignedInChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _isSignedIn;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _isSignedIn = _readIsSignedIn();
    _authSubscription = _signedInStream().listen((signedIn) {
      if (!mounted) return;
      setState(() => _isSignedIn = signedIn);
    });
  }

  bool _readIsSignedIn() {
    if (widget.isSignedIn != null) {
      return widget.isSignedIn!();
    }
    return Supabase.instance.client.auth.currentSession != null;
  }

  Stream<bool> _signedInStream() {
    if (widget.onSignedInChanged != null) {
      return widget.onSignedInChanged!();
    }
    return Supabase.instance.client.auth.onAuthStateChange.map(
      (data) => data.session != null,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn) {
      return widget.signedInHome;
    }

    // Nested navigator keeps login ↔ signup transitions local to the
    // unauthenticated flow. When a session appears, this subtree is replaced
    // by [signedInHome] and the auth stack is discarded.
    return Navigator(
      key: const ValueKey<String>('unauthenticated-navigator'),
      initialRoute: AppRoutes.login,
      onGenerateRoute: _onGenerateAuthRoute,
    );
  }

  Route<dynamic> _onGenerateAuthRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.signup:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const SignupScreen(),
        );
      case AppRoutes.login:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const LoginScreen(),
        );
    }
  }
}
