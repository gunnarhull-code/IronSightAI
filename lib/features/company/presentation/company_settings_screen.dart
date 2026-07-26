import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/company_membership.dart';
import '../../../domain/entities/country_catalog.dart';
import '../../../domain/entities/country_time_zone.dart';
import '../../../domain/repositories/company_repository.dart';
import '../../../domain/use_cases/get_current_user_company_membership.dart';
import '../../../domain/use_cases/update_company_details.dart';

/// Minimal company settings screen for Sprint 1.
///
/// This intentionally does not include invitations, team management, branding,
/// billing, chat, share links, or custom permissions.
class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key, required this.repository});

  final CompanyRepository repository;

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _nameFocus = FocusNode();
  final _countryFocus = FocusNode();

  late final GetCurrentUserCompanyMembership _getMembership;
  late final UpdateCompanyDetails _updateCompany;

  CompanyMembership? _membership;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isApplyingMembership = false;
  bool _didRequestInitialFocus = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _getMembership = GetCurrentUserCompanyMembership(widget.repository);
    _updateCompany = UpdateCompanyDetails(widget.repository);
    _nameController.addListener(_syncUnsavedChanges);
    _countryController.addListener(_syncUnsavedChanges);
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _nameFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  void _requestInitialFocusIfNeeded({required bool canEdit}) {
    if (_didRequestInitialFocus || !canEdit) return;
    _didRequestInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && canEdit) {
        _nameFocus.requestFocus();
      }
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final membership = await _getMembership();
      if (!mounted) return;
      if (membership == null) {
        setState(() {
          _errorMessage = 'Company profile not found.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _applyMembership(membership);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load company settings. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _applyMembership(CompanyMembership membership) {
    _isApplyingMembership = true;
    _membership = membership;
    _nameController.text = membership.company.name;
    _countryController.text = membership.company.region ?? '';
    _hasUnsavedChanges = false;
    _isApplyingMembership = false;
  }

  void _syncUnsavedChanges() {
    if (_isApplyingMembership || _membership == null) return;

    final company = _membership!.company;
    final hasChanges =
        _nameController.text.trim() != company.name ||
        _countryController.text.trim() != (company.region ?? '');

    // Always rebuild so the company-created timestamp reformats immediately
    // when the Country dropdown selection changes.
    setState(() => _hasUnsavedChanges = hasChanges);
  }

  String get _selectedCountryForDisplay {
    final selected = _countryController.text.trim();
    if (selected.isNotEmpty) return selected;
    return _membership?.company.region ?? defaultCompanyCountry;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final updatedCompany = await _updateCompany(
        name: _nameController.text,
        region: _countryController.text,
      );
      if (!mounted) return;

      final updatedMembership = CompanyMembership(
        company: updatedCompany,
        role: _membership!.role,
      );
      setState(() {
        _applyMembership(updatedMembership);
        _successMessage = 'Company settings saved.';
      });
      // Non-auth form: do not prompt the browser to save credentials.
      TextInput.finishAutofillContext(shouldSave: false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Company settings saved.')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not save company settings. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved company settings changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _membership?.canEditCompanySettings ?? false;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardChanges() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Company Settings')),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, canEdit),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final membership = _membership;

    if (membership == null) {
      return _RetryState(message: _errorMessage, onRetry: _loadSettings);
    }

    _requestInitialFocusIfNeeded(canEdit: canEdit);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Basic company information',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep the dealership workspace details current.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    _StatusBanner(message: _errorMessage!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    _StatusBanner(message: _successMessage!, isError: false),
                    const SizedBox(height: 16),
                  ],
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      enabled: canEdit && !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: null,
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                        helperText: 'Required',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Company name is required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (canEdit && !_isSaving) {
                          _countryFocus.requestFocus();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final countryEntries = countryDropdownEntries(
                          currentValue: membership.company.region,
                        );
                        return FormField<String>(
                          // Validates the controller text so typed search terms
                          // that were never selected from the list are rejected,
                          // matching the equipment manufacturer dropdown pattern.
                          validator: (_) {
                            final value = _countryController.text.trim();
                            if (!isAllowedCompanyCountry(
                              value,
                              existingRegion: membership.company.region,
                            )) {
                              return 'Select a country from the list';
                            }
                            return null;
                          },
                          builder: (field) {
                            return DropdownMenu<String>(
                              key: const Key('company_country_dropdown'),
                              controller: _countryController,
                              // DropdownMenu does not expose autofillHints; the
                              // surrounding name field disables autofill explicitly.
                              focusNode: _countryFocus,
                              enabled: canEdit && !_isSaving,
                              enableFilter: true,
                              requestFocusOnTap: true,
                              width: constraints.maxWidth,
                              label: const Text('Country'),
                              errorText: field.errorText,
                              dropdownMenuEntries: countryEntries
                                  .map(
                                    (country) => DropdownMenuEntry<String>(
                                      value: country,
                                      label: country,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (_) {
                                field.validate();
                                _syncUnsavedChanges();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ReadOnlyInfo(
                    label: 'Company created',
                    value: formatCompanyLocalTimestamp(
                      membership.company.createdAt,
                      companyCountry: _selectedCountryForDisplay,
                    ),
                  ),
                  _ReadOnlyInfo(
                    label: 'Current user role',
                    value: membership.role.label,
                  ),
                  _ReadOnlyInfo(
                    label: 'Company ID',
                    value: membership.company.id,
                  ),
                  if (!canEdit) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Your role is read-only for company settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: FilledButton(
                      onPressed: canEdit && !_isSaving && _hasUnsavedChanges
                          ? _save
                          : null,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: foreground)),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message ?? 'Could not load company settings.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
