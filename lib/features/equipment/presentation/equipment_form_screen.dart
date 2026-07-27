import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/country_catalog.dart';
import '../../../domain/entities/country_time_zone.dart';
import '../../../domain/entities/equipment.dart';
import '../../../domain/entities/equipment_details.dart'
    show maxEquipmentYear, minEquipmentYear;
import '../../../domain/entities/manufacturer_catalog.dart';
import '../../../domain/exceptions/duplicate_serial_number_exception.dart';
import '../../../domain/repositories/company_repository.dart';
import '../../../domain/repositories/equipment_repository.dart';
import '../../../domain/use_cases/create_equipment.dart';
import '../../../domain/use_cases/get_current_user_company.dart';
import '../../../domain/use_cases/get_equipment_by_id.dart';
import '../../../domain/use_cases/update_equipment.dart';

/// Create/edit form for a single equipment record.
///
/// When [equipmentId] is `null` the form creates a new record; otherwise it
/// loads and edits the existing one. Pops with `true` on successful save so
/// [EquipmentListScreen] knows to refresh.
class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({
    super.key,
    required this.repository,
    this.companyRepository,
    this.equipmentId,
    this.companyCountry,
  });

  final EquipmentRepository repository;

  /// Used to resolve the company country for local audit timestamps.
  final CompanyRepository? companyRepository;

  final String? equipmentId;

  /// Optional override for tests; otherwise loaded from [companyRepository].
  final String? companyCountry;

  bool get isEditing => equipmentId != null;

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _assetNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _yearController = TextEditingController();
  final _hoursController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final _assetNameFocus = FocusNode();
  final _manufacturerFocus = FocusNode();
  final _modelFocus = FocusNode();
  final _serialNumberFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _hoursFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _notesFocus = FocusNode();

  late final GetEquipmentById _getEquipmentById;
  late final CreateEquipment _createEquipment;
  late final UpdateEquipment _updateEquipment;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isApplyingValues = false;
  bool _notFound = false;
  bool _didRequestInitialFocus = false;
  String? _errorMessage;
  Equipment? _loadedEquipment;
  String? _companyCountry;

  Map<String, String> _originalValues = const {};

  List<TextEditingController> get _allControllers => [
    _assetNameController,
    _manufacturerController,
    _modelController,
    _serialNumberController,
    _yearController,
    _hoursController,
    _locationController,
    _notesController,
  ];

  List<FocusNode> get _allFocusNodes => [
    _assetNameFocus,
    _manufacturerFocus,
    _modelFocus,
    _serialNumberFocus,
    _yearFocus,
    _hoursFocus,
    _locationFocus,
    _notesFocus,
  ];

  @override
  void initState() {
    super.initState();
    _getEquipmentById = GetEquipmentById(widget.repository);
    _createEquipment = CreateEquipment(widget.repository);
    _updateEquipment = UpdateEquipment(widget.repository);
    _companyCountry = widget.companyCountry ?? defaultCompanyCountry;

    for (final controller in _allControllers) {
      controller.addListener(_syncUnsavedChanges);
    }

    _loadCompanyCountry();
    if (widget.isEditing) {
      _loadEquipment();
    } else {
      _originalValues = _currentValues();
      _isLoading = false;
    }
  }

  Future<void> _loadCompanyCountry() async {
    if (widget.companyCountry != null) {
      setState(() => _companyCountry = widget.companyCountry);
      return;
    }

    final companyRepository = widget.companyRepository;
    if (companyRepository == null) return;

    try {
      final company = await GetCurrentUserCompany(companyRepository)();
      if (!mounted) return;
      setState(() {
        _companyCountry = company?.region ?? defaultCompanyCountry;
      });
    } catch (_) {
      // Keep the default country so audit timestamps still render.
    }
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller.dispose();
    }
    for (final focusNode in _allFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _requestInitialFocusIfNeeded() {
    if (_didRequestInitialFocus || _isLoading || _notFound) return;
    _didRequestInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isSaving) {
        _assetNameFocus.requestFocus();
      }
    });
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notFound = false;
    });

    try {
      final equipment = await _getEquipmentById(widget.equipmentId!);
      if (!mounted) return;

      if (equipment == null) {
        setState(() {
          _notFound = true;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _applyEquipment(equipment);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load equipment. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _applyEquipment(Equipment equipment) {
    _isApplyingValues = true;
    _loadedEquipment = equipment;
    _assetNameController.text = equipment.assetName;
    _manufacturerController.text = equipment.manufacturer;
    _modelController.text = equipment.model;
    _serialNumberController.text = equipment.serialNumber ?? '';
    _yearController.text = equipment.year?.toString() ?? '';
    _hoursController.text = _formatHours(equipment.hours);
    _locationController.text = equipment.location ?? '';
    _notesController.text = equipment.notes ?? '';
    _originalValues = _currentValues();
    _hasUnsavedChanges = false;
    _isApplyingValues = false;
  }

  String _formatHours(double? hours) {
    if (hours == null) return '';
    if (hours == hours.roundToDouble()) return hours.toInt().toString();
    return hours.toString();
  }

  Map<String, String> _currentValues() {
    return {
      'assetName': _assetNameController.text.trim(),
      'manufacturer': _manufacturerController.text.trim(),
      'model': _modelController.text.trim(),
      'serialNumber': _serialNumberController.text.trim(),
      'year': _yearController.text.trim(),
      'hours': _hoursController.text.trim(),
      'location': _locationController.text.trim(),
      'notes': _notesController.text.trim(),
    };
  }

  void _syncUnsavedChanges() {
    if (_isApplyingValues) return;
    final hasChanges = !mapEquals(_currentValues(), _originalValues);
    if (hasChanges != _hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = hasChanges);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final year = _yearController.text.trim().isEmpty
          ? null
          : int.parse(_yearController.text.trim());
      final hours = _hoursController.text.trim().isEmpty
          ? null
          : double.parse(_hoursController.text.trim());

      if (widget.isEditing) {
        await _updateEquipment(
          id: widget.equipmentId!,
          assetName: _assetNameController.text,
          manufacturer: _manufacturerController.text,
          model: _modelController.text,
          serialNumber: _serialNumberController.text,
          year: year,
          hours: hours,
          location: _locationController.text,
          notes: _notesController.text,
        );
      } else {
        await _createEquipment(
          assetName: _assetNameController.text,
          manufacturer: _manufacturerController.text,
          model: _modelController.text,
          serialNumber: _serialNumberController.text,
          year: year,
          hours: hours,
          location: _locationController.text,
          notes: _notesController.text,
        );
      }

      if (!mounted) return;
      _hasUnsavedChanges = false;
      // Non-auth form: do not prompt the browser to save credentials.
      TextInput.finishAutofillContext(shouldSave: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Equipment updated.' : 'Equipment added.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      // Always log the original exception for debugging; the user only ever
      // sees the friendly message from [_friendlyErrorMessage].
      debugPrint('EquipmentFormScreen save failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DuplicateSerialNumberException) {
      return error.toString();
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Enter valid equipment details.';
    }
    return 'Could not save equipment. Please try again.';
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved equipment changes.'),
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
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardChanges() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Equipment' : 'Add Equipment'),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notFound
              ? _RetryState(
                  message: 'Equipment not found.',
                  onRetry: _loadEquipment,
                )
              : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    _requestInitialFocusIfNeeded();

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
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (_loadedEquipment != null) ...[
                    _AuditInfoCard(
                      equipment: _loadedEquipment!,
                      companyCountry: _companyCountry,
                    ),
                    const SizedBox(height: 16),
                  ],
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: TextFormField(
                      controller: _assetNameController,
                      focusNode: _assetNameFocus,
                      autofocus: !widget.isEditing,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: null,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Enter an asset name'
                          : null,
                      onFieldSubmitted: (_) {
                        _manufacturerFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FormField<String>(
                          // Validates the controller's current text directly
                          // (rather than a separately tracked selection) so the
                          // inline error always matches exactly what would be
                          // submitted on Save, whether it came from typing a
                          // search term or tapping a menu entry.
                          validator: (_) {
                            final value = _manufacturerController.text.trim();
                            if (value.isEmpty) {
                              return 'Select a manufacturer';
                            }
                            if (!manufacturerCatalog.contains(value)) {
                              return 'Select a manufacturer from the list';
                            }
                            return null;
                          },
                          builder: (field) {
                            return DropdownMenu<String>(
                              controller: _manufacturerController,
                              // DropdownMenu does not expose autofillHints; the
                              // surrounding fields disable autofill explicitly.
                              focusNode: _manufacturerFocus,
                              enabled: !_isSaving,
                              enableFilter: true,
                              requestFocusOnTap: true,
                              width: constraints.maxWidth,
                              label: const Text('Manufacturer'),
                              errorText: field.errorText,
                              dropdownMenuEntries: manufacturerCatalog
                                  .map(
                                    (manufacturer) => DropdownMenuEntry<String>(
                                      value: manufacturer,
                                      label: manufacturer,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (_) {
                                field.validate();
                                _modelFocus.requestFocus();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: TextFormField(
                      controller: _modelController,
                      focusNode: _modelFocus,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: null,
                      decoration: const InputDecoration(labelText: 'Model'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Enter a model'
                          : null,
                      onFieldSubmitted: (_) {
                        _serialNumberFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: TextFormField(
                      controller: _serialNumberController,
                      focusNode: _serialNumberFocus,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      autofillHints: null,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                      ),
                      onFieldSubmitted: (_) {
                        _yearFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(5),
                          child: TextFormField(
                            controller: _yearController,
                            focusNode: _yearFocus,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            autofillHints: null,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null) return 'Enter a valid year';
                              if (parsed < minEquipmentYear) {
                                return 'Year must be $minEquipmentYear or later';
                              }
                              final latestYear = maxEquipmentYear();
                              if (parsed > latestYear) {
                                return 'Year cannot be later than $latestYear';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              _hoursFocus.requestFocus();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(6),
                          child: TextFormField(
                            controller: _hoursController,
                            focusNode: _hoursFocus,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            autofillHints: null,
                            decoration: const InputDecoration(
                              labelText: 'Hours',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null) {
                                return 'Enter a valid number';
                              }
                              if (parsed < 0) {
                                return 'Hours cannot be negative';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              _locationFocus.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(7),
                    child: TextFormField(
                      controller: _locationController,
                      focusNode: _locationFocus,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: null,
                      decoration: const InputDecoration(labelText: 'Location'),
                      onFieldSubmitted: (_) {
                        _notesFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(8),
                    child: TextFormField(
                      controller: _notesController,
                      focusNode: _notesFocus,
                      enabled: !_isSaving,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      autofillHints: null,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(9),
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Save Changes'
                                  : 'Add Equipment',
                            ),
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

class _AuditInfoCard extends StatelessWidget {
  const _AuditInfoCard({required this.equipment, required this.companyCountry});

  final Equipment equipment;
  final String? companyCountry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audit', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _AuditRow(
              label: 'Created By',
              value: _displayUser(equipment.createdByName, equipment.createdBy),
            ),
            const SizedBox(height: 8),
            _AuditRow(
              label: 'Created',
              value: formatCompanyLocalTimestamp(
                equipment.createdAt,
                companyCountry: companyCountry,
              ),
            ),
            const SizedBox(height: 8),
            _AuditRow(
              label: 'Last Updated By',
              value: _displayUser(equipment.updatedByName, equipment.updatedBy),
            ),
            const SizedBox(height: 8),
            _AuditRow(
              label: 'Last Updated',
              value: formatCompanyLocalTimestamp(
                equipment.updatedAt,
                companyCountry: companyCountry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayUser(String? name, String? id) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    return id == null ? 'Not recorded' : 'Unknown user';
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value)),
      ],
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

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
