import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';

/// Email/password sign-in screen.
///
/// Successful sign-in does not navigate here — [AuthGate] listens to
/// Supabase auth state and swaps to the dashboard centrally.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isSubmitting = false;
  bool _didRequestInitialFocus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Flutter web does not reliably honor [autofocus] alone; request focus
    // after the first frame so Email is ready for keyboard entry immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRequestInitialFocus) return;
      _didRequestInitialFocus = true;
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Encourage the browser/OS password manager to offer saving credentials
      // for this authentication form only.
      TextInput.finishAutofillContext(shouldSave: true);
      // Navigation is handled by AuthGate via onAuthStateChange.
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToSignUp() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'IronSight AI',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_errorMessage != null) ...[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(1),
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            autofocus: true,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: _validateEmail,
                            onFieldSubmitted: (_) {
                              _passwordFocus.requestFocus();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(2),
                          child: TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            enabled: !_isSubmitting,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              if (!_isSubmitting) {
                                _signIn();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(3),
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _signIn,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(4),
                          child: TextButton(
                            onPressed: _isSubmitting ? null : _goToSignUp,
                            child: const Text(
                              "Don't have an account? Sign Up",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter your email';
  }
  if (!value.contains('@') || !value.contains('.')) {
    return 'Enter a valid email address';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter your password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

/// A small, self-contained error banner shown above the form fields.
///
/// Duplicated (not shared) between the login and sign-up screens for now,
/// deliberately, since there are only two call sites — worth promoting to
/// `lib/shared/widgets/` if a third auth-style screen needs it.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
