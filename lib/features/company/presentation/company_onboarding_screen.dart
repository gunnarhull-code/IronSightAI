import 'package:flutter/material.dart';

import '../../../domain/use_cases/create_company_for_current_user.dart';

/// First-time company setup for an authenticated user with no membership.
///
/// On success, [onCompleted] is invoked so [CompanyGate] can advance to the
/// dashboard. Persistence is owned by [CreateCompanyForCurrentUser].
class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({
    super.key,
    required this.createCompany,
    required this.onCompleted,
  });

  final CreateCompanyForCurrentUser createCompany;
  final VoidCallback onCompleted;

  @override
  State<CompanyOnboardingScreen> createState() =>
      _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.createCompany(name: _nameController.text);
      if (!mounted) return;
      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ArgumentError
            ? e.message?.toString() ?? 'Company name is required'
            : 'Could not create company. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set up your company',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your dealership workspace to start inspections.',
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
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.organizationName],
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _continue,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
