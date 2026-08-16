import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/inspection_machine_source.dart';
import '../../../../domain/entities/inspection_status.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import 'inspection_draft_routing.dart';
import 'inspection_equipment_select_screen.dart';
import 'widgets/local_only_status_banner.dart';

/// Entry point for guided Quick Appraisal: new machine, existing, or resume.
class GuidedQuickAppraisalEntryScreen extends StatefulWidget {
  const GuidedQuickAppraisalEntryScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.inspections,
    required this.equipmentCatalog,
    this.refreshCatalog,
  });

  final String companyId;
  final String userId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;

  /// Optional best-effort remote refresh for the existing-equipment picker.
  final Future<bool> Function(String companyId)? refreshCatalog;

  @override
  State<GuidedQuickAppraisalEntryScreen> createState() =>
      _GuidedQuickAppraisalEntryScreenState();
}

class _GuidedQuickAppraisalEntryScreenState
    extends State<GuidedQuickAppraisalEntryScreen> {
  late Future<_EntryData> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EntryData> _load() async {
    final inspections = await widget.inspections.listForCompany(
      widget.companyId,
    );
    final drafts = inspections
        .where(
          (item) =>
              item.completionStatus == InspectionCompletionStatus.inProgress &&
              !item.isDiscarded,
        )
        .toList(growable: false);
    final equipment = await widget.equipmentCatalog.listForCompany(
      widget.companyId,
    );
    final byId = {for (final item in equipment) item.id: item};
    return _EntryData(drafts: drafts, equipmentById: byId);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openDraft(Inspection inspection) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed<bool?>(incompleteInspectionRoute(inspection));
    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
      return;
    }
    _reload();
  }

  Future<void> _openGuided(String inspectionId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed<bool?>(AppRoutes.guidedQuickAppraisal(inspectionId));
    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
      return;
    }
    _reload();
  }

  Future<void> _startNewMachine() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final draft = await widget.inspections.createGuidedDraft(
        companyId: widget.companyId,
        createdByUserId: widget.userId,
        machineSource: InspectionMachineSource.newMachine,
      );
      if (!mounted) return;
      await _openGuided(draft.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start a New machine draft. Retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _startExistingEquipment() async {
    if (_starting) return;
    final changed = await Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (context) => InspectionEquipmentSelectScreen(
          companyId: widget.companyId,
          userId: widget.userId,
          inspections: widget.inspections,
          equipmentCatalog: widget.equipmentCatalog,
          refreshCatalog: widget.refreshCatalog,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
      return;
    }
    _reload();
  }

  String _draftTitle(Inspection inspection, Equipment? equipment) {
    if (equipment != null) return equipment.assetName;
    final pending = inspection.pendingAssetName?.trim();
    if (pending != null && pending.isNotEmpty) return pending;
    if (inspection.isNewMachineDraft) return 'New machine draft';
    final id = inspection.equipmentId;
    if (id != null && id.isNotEmpty) return 'Equipment $id';
    return 'Quick Appraisal draft';
  }

  String _draftSubtitle(Inspection inspection) {
    final source = inspection.machineSource?.displayLabel ?? 'Legacy draft';
    final when = inspection.updatedAt.toLocal().toString().split('.').first;
    return '$source · Updated $when';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Start Quick Appraisal')),
      body: Column(
        children: [
          const LocalOnlyStatusBanner(),
          Expanded(
            child: FutureBuilder<_EntryData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Could not load local drafts.',
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

                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      'How do you want to start?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      button: true,
                      label: 'New machine',
                      child: Card(
                        child: ListTile(
                          enabled: !_starting,
                          leading: const Icon(Icons.add_box_outlined),
                          title: const Text('New machine'),
                          subtitle: const Text(
                            'Capture identity during this appraisal',
                          ),
                          trailing: _starting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _startNewMachine,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Existing equipment',
                      child: Card(
                        child: ListTile(
                          enabled: !_starting,
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: const Text('Existing equipment'),
                          subtitle: const Text(
                            'Select from equipment cached on this device',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _startExistingEquipment,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Resume in-progress drafts',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (data.drafts.isEmpty)
                      Text(
                        'No in-progress drafts on this device.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      for (final draft in data.drafts) ...[
                        Card(
                          child: ListTile(
                            enabled: !_starting,
                            onTap: () => _openDraft(draft),
                            title: Text(
                              _draftTitle(
                                draft,
                                draft.equipmentId == null
                                    ? null
                                    : data.equipmentById[draft.equipmentId],
                              ),
                            ),
                            subtitle: Text(_draftSubtitle(draft)),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryData {
  const _EntryData({required this.drafts, required this.equipmentById});

  final List<Inspection> drafts;
  final Map<String, Equipment> equipmentById;
}
