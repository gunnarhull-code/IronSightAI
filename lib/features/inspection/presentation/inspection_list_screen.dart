import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/inspection_status.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import 'widgets/local_only_status_banner.dart';

/// Company-scoped local inspection list with loading/empty/error states.
class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({
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
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  late Future<_InspectionListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InspectionListData> _load() async {
    final inspections = await widget.inspections.listForCompany(
      widget.companyId,
    );
    final equipment = await widget.equipmentCatalog.listForCompany(
      widget.companyId,
    );
    final byId = {for (final item in equipment) item.id: item};
    return _InspectionListData(inspections: inspections, equipmentById: byId);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openNew() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed<bool?>(AppRoutes.inspectionNew);
    if (changed == true && mounted) _reload();
  }

  Future<void> _openInspection(Inspection inspection) async {
    final route =
        inspection.completionStatus == InspectionCompletionStatus.completed
        ? AppRoutes.inspectionReview(inspection.id)
        : AppRoutes.inspectionWorkspace(inspection.id);
    final changed = await Navigator.of(context).pushNamed<bool?>(route);
    if (changed == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspections'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: const Text('Start Quick Appraisal'),
      ),
      body: Column(
        children: [
          const LocalOnlyStatusBanner(),
          Expanded(
            child: FutureBuilder<_InspectionListData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        'Could not load local inspections. Your device data '
                        'was not modified.',
                    onRetry: _reload,
                  );
                }
                final data = snapshot.data!;
                if (data.inspections.isEmpty) {
                  return _EmptyState(onStart: _openNew);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: data.inspections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inspection = data.inspections[index];
                    final equipment =
                        data.equipmentById[inspection.equipmentId];
                    final title =
                        equipment?.assetName ??
                        'Equipment ${inspection.equipmentId}';
                    final subtitle = _subtitle(inspection, equipment);
                    final statusLabel = _statusLabel(inspection);
                    return Card(
                      child: ListTile(
                        onTap: () => _openInspection(inspection),
                        title: Text(title, style: theme.textTheme.titleMedium),
                        subtitle: Text(subtitle),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              statusLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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

  String _statusLabel(Inspection inspection) {
    if (inspection.completionStatus == InspectionCompletionStatus.completed) {
      return 'Completed';
    }
    return 'Draft';
  }

  String _subtitle(Inspection inspection, Equipment? equipment) {
    final manufacturer = equipment?.manufacturer;
    final model = equipment?.model;
    final identity = [
      if (manufacturer != null && manufacturer.isNotEmpty) manufacturer,
      if (model != null && model.isNotEmpty) model,
    ].join(' ');
    final when = inspection.updatedAt.toLocal().toString().split('.').first;
    if (identity.isEmpty) return 'Updated $when · local only';
    return '$identity · Updated $when · local only';
  }
}

class _InspectionListData {
  const _InspectionListData({
    required this.inspections,
    required this.equipmentById,
  });

  final List<Inspection> inspections;
  final Map<String, Equipment> equipmentById;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No local inspections yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a Quick Appraisal from equipment saved on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              child: const Text('Start Quick Appraisal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
