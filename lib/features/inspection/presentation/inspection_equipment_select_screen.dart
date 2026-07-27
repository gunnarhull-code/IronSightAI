import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import '../../../../domain/use_cases/find_active_drafts_for_equipment.dart';
import 'widgets/local_only_status_banner.dart';

/// Selects locally cached equipment and starts or resumes a draft.
class InspectionEquipmentSelectScreen extends StatefulWidget {
  const InspectionEquipmentSelectScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.inspections,
    required this.equipmentCatalog,
  });

  final String companyId;
  final String userId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;

  @override
  State<InspectionEquipmentSelectScreen> createState() =>
      _InspectionEquipmentSelectScreenState();
}

class _InspectionEquipmentSelectScreenState
    extends State<InspectionEquipmentSelectScreen> {
  late final FindActiveDraftsForEquipment _findDrafts;
  late Future<List<Equipment>> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _findDrafts = FindActiveDraftsForEquipment(widget.inspections);
    _future = widget.equipmentCatalog.listForCompany(widget.companyId);
  }

  void _reload() {
    setState(() {
      _future = widget.equipmentCatalog.listForCompany(widget.companyId);
    });
  }

  Future<void> _onSelect(Equipment equipment) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final drafts = await _findDrafts(
        companyId: widget.companyId,
        equipmentId: equipment.id,
      );
      if (!mounted) return;

      if (drafts.isNotEmpty) {
        final decision = await showDialog<_DuplicateDraftDecision>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Active draft found'),
            content: Text(
              'There ${drafts.length == 1 ? 'is' : 'are'} '
              '${drafts.length} active draft'
              '${drafts.length == 1 ? '' : 's'} for '
              '${equipment.assetName}. Resume the latest draft or create '
              'another?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  _DuplicateDraftDecision.createAnother,
                ),
                child: const Text('Create Another'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, _DuplicateDraftDecision.resume),
                child: const Text('Resume'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (decision == null) return;
        if (decision == _DuplicateDraftDecision.resume) {
          await _openWorkspace(drafts.first.id);
          return;
        }
      }

      final draft = await widget.inspections.createDraft(
        companyId: widget.companyId,
        equipmentId: equipment.id,
        createdByUserId: widget.userId,
      );
      if (!mounted) return;
      await _openWorkspace(draft.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not start a local draft. Check equipment cache and retry.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openWorkspace(String inspectionId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed<bool>(AppRoutes.inspectionWorkspace(inspectionId));
    if (!mounted) return;
    Navigator.of(context).pop(changed == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Equipment')),
      body: Column(
        children: [
          const LocalOnlyStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Showing equipment saved on this device. Network is never '
              'required to start an inspection.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Equipment>>(
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
                            'Could not read the local equipment catalog.',
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
                final equipment = snapshot.data ?? const <Equipment>[];
                if (equipment.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'No equipment is cached on this device yet.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connect once to refresh the catalog from your '
                            'company equipment list, then continue offline.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Reload local catalog'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: equipment.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = equipment[index];
                    return Card(
                      child: ListTile(
                        enabled: !_starting,
                        onTap: () => _onSelect(item),
                        title: Text(item.assetName),
                        subtitle: Text(
                          [
                            item.manufacturer,
                            item.model,
                            if (item.serialNumber != null)
                              'S/N ${item.serialNumber}',
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _DuplicateDraftDecision { resume, createAnother }
