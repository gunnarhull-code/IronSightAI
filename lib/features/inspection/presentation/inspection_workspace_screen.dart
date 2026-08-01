import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../data/equipment_id_capture/create_platform_bindings.dart';
import '../../../../domain/detailed_checklist_templates.dart';
import '../../../../domain/entities/condition_rating.dart';
import '../../../../domain/entities/detailed_category_response.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/scorecard_category.dart';
import '../../../../domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import '../../../../domain/equipment_id_capture/equipment_id_capture_controller.dart';
import '../../../../domain/equipment_id_capture/equipment_id_capture_kind.dart';
import '../../../../domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import '../../equipment_id_capture/presentation/equipment_id_capture_panel.dart';
import 'widgets/condition_rating_controls.dart';
import 'widgets/local_only_status_banner.dart';

/// Builds capture controllers for serial / hour panels in Quick Appraisal.
typedef EquipmentIdCaptureControllerFactory =
    EquipmentIdCaptureController Function({
      required EquipmentIdCaptureKind kind,
      ConfirmedEquipmentIdValue? initialConfirmed,
    });

/// Quick Appraisal workspace with optional per-category Detailed Inspection.
class InspectionWorkspaceScreen extends StatefulWidget {
  const InspectionWorkspaceScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.inspectionId,
    required this.inspections,
    required this.equipmentCatalog,
    this.navigatorKey,
    this.captureControllerFactory,
  });

  final String companyId;
  final String userId;
  final String inspectionId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;

  /// Root navigator used by camera capture routes on supported platforms.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional override for tests (manual-only fakes, etc.).
  final EquipmentIdCaptureControllerFactory? captureControllerFactory;

  @override
  State<InspectionWorkspaceScreen> createState() =>
      _InspectionWorkspaceScreenState();
}

class _InspectionWorkspaceScreenState extends State<InspectionWorkspaceScreen> {
  late Future<_WorkspaceData> _future;
  final ScrollController _scrollController = ScrollController();
  final Set<ScorecardCategory> _expanded = {};
  final TextEditingController _notesController = TextEditingController();
  bool _savingNotes = false;
  bool _mutating = false;
  bool _savingEquipmentId = false;

  EquipmentIdCaptureController? _serialController;
  EquipmentIdCaptureController? _hoursController;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _serialController?.dispose();
    _hoursController?.dispose();
    super.dispose();
  }

  EquipmentIdCaptureController _createController({
    required EquipmentIdCaptureKind kind,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    final factory = widget.captureControllerFactory;
    if (factory != null) {
      return factory(kind: kind, initialConfirmed: initialConfirmed);
    }
    // Fresh bindings per controller — dispose closes TextRecognitionPort.
    final bindings = createPlatformEquipmentIdCaptureBindings(
      navigatorKey: widget.navigatorKey,
    );
    return EquipmentIdCaptureController(
      kind: kind,
      imageCapture: bindings.imageCapture,
      textRecognition: bindings.textRecognition,
      cameraPermission: bindings.cameraPermission,
      initialConfirmed: initialConfirmed,
    );
  }

  void _ensureCaptureControllers(Inspection inspection) {
    _serialController ??= _createController(
      kind: EquipmentIdCaptureKind.serialNumber,
      initialConfirmed: inspection.confirmedSerialNumber,
    );
    _hoursController ??= _createController(
      kind: EquipmentIdCaptureKind.hourMeter,
      initialConfirmed: inspection.confirmedHourMeter,
    );
  }

  Future<_WorkspaceData> _load() async {
    final inspection = await widget.inspections.getById(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }
    final equipment = await widget.equipmentCatalog.getById(
      companyId: widget.companyId,
      equipmentId: inspection.equipmentId,
    );
    if (_notesController.text != (inspection.overallNotes ?? '')) {
      _notesController.text = inspection.overallNotes ?? '';
    }
    _ensureCaptureControllers(inspection);
    return _WorkspaceData(inspection: inspection, equipment: equipment);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _onEquipmentIdConfirmed(
    Inspection inspection,
    EquipmentIdCaptureState state,
  ) async {
    final confirmed = state.confirmed;
    if (confirmed == null || _savingEquipmentId) return;

    final alreadyPersisted = switch (confirmed.kind) {
      EquipmentIdCaptureKind.serialNumber =>
        inspection.serialNumber == confirmed.value &&
            inspection.serialCaptureMethod == confirmed.method,
      EquipmentIdCaptureKind.hourMeter =>
        inspection.hourMeterReading == confirmed.hours &&
            inspection.hourMeterCaptureMethod == confirmed.method,
    };
    if (alreadyPersisted) return;

    setState(() => _savingEquipmentId = true);
    try {
      await widget.inspections.saveConfirmedEquipmentId(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        confirmedValue: confirmed,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save equipment ID locally.')),
      );
    } finally {
      if (mounted) setState(() => _savingEquipmentId = false);
    }
  }

  Future<void> _saveRating(
    Inspection inspection,
    ScorecardCategory category,
    ConditionRating rating,
  ) async {
    if (_mutating || !inspection.isIncomplete || inspection.isDiscarded) return;
    setState(() => _mutating = true);
    try {
      await widget.inspections.saveCategoryRating(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        category: category,
        rating: rating,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save rating locally.')),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _toggleDetailed(
    Inspection inspection,
    ScorecardCategory category,
  ) async {
    final expanding = !_expanded.contains(category);
    setState(() {
      if (expanding) {
        _expanded.add(category);
      } else {
        _expanded.remove(category);
      }
    });
    if (!expanding) return;

    final existing = inspection.detailedFor(category);
    if (existing.items.isNotEmpty) return;
    if (!inspection.isIncomplete || inspection.isDiscarded) return;

    final seeded = DetailedCategoryResponse(
      category: category,
      items: detailedChecklistTemplateFor(category),
    );
    setState(() => _mutating = true);
    try {
      await widget.inspections.saveDetailedCategoryResponse(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        response: seeded,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open detailed checklist locally.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _saveDetailedItem(
    Inspection inspection,
    ScorecardCategory category,
    DetailedChecklistItemResponse item,
    ConditionRating rating,
  ) async {
    if (_mutating) return;
    final current = inspection.detailedFor(category);
    final items = current.items
        .map(
          (existing) => existing.itemKey == item.itemKey
              ? DetailedChecklistItemResponse(
                  itemKey: existing.itemKey,
                  labelSnapshot: existing.labelSnapshot,
                  sortOrder: existing.sortOrder,
                  rating: rating,
                  notes: existing.notes,
                )
              : existing,
        )
        .toList(growable: false);
    setState(() => _mutating = true);
    try {
      await widget.inspections.saveDetailedCategoryResponse(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        response: DetailedCategoryResponse(category: category, items: items),
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save detailed response locally.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _saveNotes(Inspection inspection) async {
    if (_savingNotes) return;
    setState(() => _savingNotes = true);
    try {
      final text = _notesController.text.trim();
      await widget.inspections.updateMetadata(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
        overallNotes: text.isEmpty ? null : text,
        clearOverallNotes: text.isEmpty,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save notes locally.')),
      );
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  Future<void> _discard(Inspection inspection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard draft?'),
        content: const Text(
          'This incomplete draft will be discarded on this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.inspections.discardIncomplete(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not discard draft locally.')),
      );
    }
  }

  Future<void> _openReview() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed<bool?>(AppRoutes.inspectionReview(widget.inspectionId));
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
      return;
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Appraisal'),
        actions: [
          IconButton(
            tooltip: 'Discard draft',
            onPressed: _mutating
                ? null
                : () async {
                    final data = await _future;
                    if (!mounted) return;
                    await _discard(data.inspection);
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<_WorkspaceData>(
        future: _future,
        builder: (context, snapshot) {
          // Keep the last successful workspace mounted while a local save
          // reloads. Replacing the ListView with a spinner was resetting
          // scroll offset after every in-place rating/notes interaction.
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not open this local inspection.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final inspection = data.inspection;
          final editable = inspection.isIncomplete && !inspection.isDiscarded;
          final serialController = _serialController;
          final hoursController = _hoursController;

          return Column(
            children: [
              LocalOnlyStatusBanner(syncStatus: inspection.syncStatus),
              Expanded(
                child: ListView(
                  key: PageStorageKey<String>(
                    'quick-appraisal-scroll-${widget.inspectionId}',
                  ),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      data.equipment?.assetName ??
                          'Equipment ${inspection.equipmentId}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (data.equipment != null)
                          '${data.equipment!.manufacturer} '
                              '${data.equipment!.model}',
                        'Local draft',
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (serialController != null &&
                        hoursController != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Equipment identification',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan or type serial number and hours. OCR never saves '
                        'until you confirm. Works offline.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: !editable || _savingEquipmentId,
                        child: Opacity(
                          opacity: editable && !_savingEquipmentId ? 1 : 0.6,
                          child: EquipmentIdCapturePanel(
                            key: const ValueKey('qa-serial-capture'),
                            controller: serialController,
                            onConfirmed: (state) =>
                                _onEquipmentIdConfirmed(inspection, state),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: !editable || _savingEquipmentId,
                        child: Opacity(
                          opacity: editable && !_savingEquipmentId ? 1 : 0.6,
                          child: EquipmentIdCapturePanel(
                            key: const ValueKey('qa-hours-capture'),
                            controller: hoursController,
                            onConfirmed: (state) =>
                                _onEquipmentIdConfirmed(inspection, state),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    for (final category
                        in ScorecardCategory.scorecardOrder) ...[
                      _CategoryCard(
                        category: category,
                        rating: inspection.ratingFor(category),
                        expanded: _expanded.contains(category),
                        detailed: inspection.detailedFor(category),
                        enabled: editable && !_mutating,
                        onRatingChanged: (rating) =>
                            _saveRating(inspection, category, rating),
                        onToggleDetailed: () =>
                            _toggleDetailed(inspection, category),
                        onDetailedRatingChanged: (item, rating) =>
                            _saveDetailedItem(
                              inspection,
                              category,
                              item,
                              rating,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('Overall notes', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      enabled: editable && !_savingNotes,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Optional notes (saved on this device)',
                      ),
                      onEditingComplete: () => _saveNotes(inspection),
                      onTapOutside: (_) => _saveNotes(inspection),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: editable && !_savingNotes
                            ? () => _saveNotes(inspection)
                            : null,
                        icon: _savingNotes
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save notes'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: editable ? _openReview : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Review & Complete'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceData {
  const _WorkspaceData({required this.inspection, required this.equipment});

  final Inspection inspection;
  final Equipment? equipment;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.rating,
    required this.expanded,
    required this.detailed,
    required this.enabled,
    required this.onRatingChanged,
    required this.onToggleDetailed,
    required this.onDetailedRatingChanged,
  });

  final ScorecardCategory category;
  final ConditionRating rating;
  final bool expanded;
  final DetailedCategoryResponse detailed;
  final bool enabled;
  final ValueChanged<ConditionRating> onRatingChanged;
  final VoidCallback onToggleDetailed;
  final void Function(
    DetailedChecklistItemResponse item,
    ConditionRating rating,
  )
  onDetailedRatingChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.displayLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onToggleDetailed,
                  child: Text(expanded ? 'Hide details' : 'Detailed'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConditionRatingControls(
              value: rating,
              enabled: enabled,
              onChanged: onRatingChanged,
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              Text(
                'Detailed Inspection (optional)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final item in detailed.items) ...[
                Text(item.labelSnapshot, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                ConditionRatingControls(
                  value: item.rating,
                  enabled: enabled,
                  includeNotAssessed: true,
                  onChanged: (value) => onDetailedRatingChanged(item, value),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
