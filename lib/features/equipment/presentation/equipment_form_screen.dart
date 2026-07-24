import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/equipment.dart';
import '../../../domain/entities/equipment_details.dart'
    show maxEquipmentYear, minEquipmentYear;
import '../../../domain/entities/manufacturer_catalog.dart';
import '../../../domain/exceptions/duplicate_serial_number_exception.dart';
import '../../../domain/repositories/equipment_repository.dart';
import '../../../domain/use_cases/create_equipment.dart';
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
    this.equipmentId,
  });

  final EquipmentRepository repository;
  final String? equipmentId;

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

  late final GetEquipmentById _getEquipmentById;
  late final CreateEquipment _createEquipment;
  late final UpdateEquipment _updateEquipment;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isApplyingValues = false;
  bool _notFound = false;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _getEquipmentById = GetEquipmentById(widget.repository);
    _createEquipment = CreateEquipment(widget.repository);
    _updateEquipment = UpdateEquipment(widget.repository);

    for (final controller in _allControllers) {
      controller.addListener(_syncUnsavedChanges);
    }

    if (widget.isEditing) {
      _loadEquipment();
    } else {
      _originalValues = _currentValues();
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _assetNameController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Asset Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter an asset name'
                      : null,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
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
                          onSelected: (_) => field.validate(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a model'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serialNumberController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year'),
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        enabled: !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Hours'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) return 'Enter a valid number';
                          if (parsed < 0) return 'Hours cannot be negative';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  enabled: !_isSaving,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          widget.isEditing ? 'Save Changes' : 'Add Equipment',
                        ),
                ),
              ],
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
