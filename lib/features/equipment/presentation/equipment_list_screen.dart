import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../domain/entities/equipment.dart';
import '../../../domain/repositories/equipment_repository.dart';
import '../../../domain/use_cases/get_equipment_list.dart';

/// Lists all equipment belonging to the current user's company.
///
/// This sprint is CRUD only: no photos, inspections, valuation, maintenance,
/// categories, or barcode/QR scanning yet.
class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key, required this.repository});

  final EquipmentRepository repository;

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  late final GetEquipmentList _getEquipmentList;
  late Future<List<Equipment>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _getEquipmentList = GetEquipmentList(widget.repository);
    _equipmentFuture = _getEquipmentList();
  }

  void _reload() {
    // Block body (not `=>`) is required here: an arrow function's body is an
    // expression, so `() => _equipmentFuture = _getEquipmentList()` would
    // make the closure itself return the assigned Future. setState() asserts
    // its callback returns void and throws before calling markNeedsBuild()
    // when it doesn't — so the field was reassigned but the widget was never
    // told to rebuild, leaving the list showing stale data until the screen
    // was torn down and recreated.
    setState(() {
      _equipmentFuture = _getEquipmentList();
    });
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(
      context,
    ).pushNamed<bool?>(AppRoutes.equipmentNew);
    if (created == true) _reload();
  }

  Future<void> _openEditForm(Equipment equipment) async {
    final updated = await Navigator.of(
      context,
    ).pushNamed<bool?>(AppRoutes.equipmentEdit(equipment.id));
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      body: FutureBuilder<List<Equipment>>(
        future: _equipmentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Could not load equipment. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
            return _EmptyState(onAddEquipment: _openCreateForm);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: equipment.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = equipment[index];
              return _EquipmentTile(
                equipment: item,
                onTap: () => _openEditForm(item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({required this.equipment, required this.onTap});

  final Equipment equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      equipment.manufacturer,
      equipment.model,
      if (equipment.year != null) equipment.year.toString(),
    ];

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.precision_manufacturing_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(equipment.assetName, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddEquipment});

  final VoidCallback onAddEquipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.precision_manufacturing_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No equipment yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first piece of equipment to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddEquipment,
              icon: const Icon(Icons.add),
              label: const Text('Add Equipment'),
            ),
          ],
        ),
      ),
    );
  }
}
