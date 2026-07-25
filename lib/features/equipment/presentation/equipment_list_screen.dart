import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../domain/entities/equipment.dart';
import '../../../domain/entities/manufacturer_catalog.dart';
import '../../../domain/repositories/equipment_repository.dart';
import '../../../domain/use_cases/get_equipment_list.dart';

const _allManufacturersFilter = 'All Manufacturers';

enum _EquipmentSortOption {
  assetName('Asset Name (A-Z)'),
  manufacturer('Manufacturer (A-Z)'),
  newest('Newest'),
  oldest('Oldest');

  const _EquipmentSortOption(this.label);

  final String label;
}

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
  String _searchQuery = '';
  String _manufacturerFilter = _allManufacturersFilter;
  _EquipmentSortOption _sortOption = _EquipmentSortOption.newest;

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

  void _updateSearchQuery(String value) {
    setState(() => _searchQuery = value);
  }

  void _updateManufacturerFilter(String? value) {
    if (value == null) return;
    setState(() => _manufacturerFilter = value);
  }

  void _updateSortOption(_EquipmentSortOption? value) {
    if (value == null) return;
    setState(() => _sortOption = value);
  }

  List<Equipment> _visibleEquipment(List<Equipment> equipment) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = equipment.where((item) {
      final matchesManufacturer =
          _manufacturerFilter == _allManufacturersFilter ||
          item.manufacturer == _manufacturerFilter;
      if (!matchesManufacturer) return false;
      if (query.isEmpty) return true;

      return _searchableText(item).contains(query);
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortOption) {
        _EquipmentSortOption.assetName => _compareAssetName(a, b),
        _EquipmentSortOption.manufacturer => _compareManufacturer(a, b),
        _EquipmentSortOption.newest => _compareNewest(a, b),
        _EquipmentSortOption.oldest => _compareOldest(a, b),
      };
    });
    return filtered;
  }

  String _searchableText(Equipment equipment) {
    return [
      equipment.assetName,
      equipment.manufacturer,
      equipment.model,
      equipment.serialNumber,
      equipment.location,
    ].whereType<String>().join(' ').toLowerCase();
  }

  int _compareAssetName(Equipment a, Equipment b) {
    return _compareText(a.assetName, b.assetName);
  }

  int _compareManufacturer(Equipment a, Equipment b) {
    final manufacturerCompare = _compareText(a.manufacturer, b.manufacturer);
    if (manufacturerCompare != 0) return manufacturerCompare;
    return _compareAssetName(a, b);
  }

  int _compareNewest(Equipment a, Equipment b) {
    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;
    return _compareAssetName(a, b);
  }

  int _compareOldest(Equipment a, Equipment b) {
    final createdCompare = a.createdAt.compareTo(b.createdAt);
    if (createdCompare != 0) return createdCompare;
    return _compareAssetName(a, b);
  }

  int _compareText(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
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

          final visibleEquipment = _visibleEquipment(equipment);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EquipmentListControls(
                manufacturerFilter: _manufacturerFilter,
                sortOption: _sortOption,
                onSearchChanged: _updateSearchQuery,
                onManufacturerChanged: _updateManufacturerFilter,
                onSortChanged: _updateSortOption,
              ),
              const SizedBox(height: 16),
              if (visibleEquipment.isEmpty)
                const _NoMatchesState()
              else
                for (final item in visibleEquipment) ...[
                  _EquipmentTile(
                    equipment: item,
                    onTap: () => _openEditForm(item),
                  ),
                  if (item != visibleEquipment.last) const SizedBox(height: 8),
                ],
            ],
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

class _EquipmentListControls extends StatelessWidget {
  const _EquipmentListControls({
    required this.manufacturerFilter,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onManufacturerChanged,
    required this.onSortChanged,
  });

  final String manufacturerFilter;
  final _EquipmentSortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onManufacturerChanged;
  final ValueChanged<_EquipmentSortOption?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final filterItems = [_allManufacturersFilter, ...manufacturerCatalog];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('equipment-search-field'),
          decoration: const InputDecoration(
            labelText: 'Search equipment',
            hintText: 'Name, manufacturer, model, serial, or location',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final controls = [
              DropdownButtonFormField<String>(
                key: const ValueKey('equipment-manufacturer-filter'),
                initialValue: manufacturerFilter,
                decoration: const InputDecoration(labelText: 'Manufacturer'),
                items: filterItems
                    .map(
                      (manufacturer) => DropdownMenuItem<String>(
                        value: manufacturer,
                        child: Text(manufacturer),
                      ),
                    )
                    .toList(),
                onChanged: onManufacturerChanged,
              ),
              DropdownButtonFormField<_EquipmentSortOption>(
                key: const ValueKey('equipment-sort-dropdown'),
                initialValue: sortOption,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: _EquipmentSortOption.values
                    .map(
                      (option) => DropdownMenuItem<_EquipmentSortOption>(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: onSortChanged,
              ),
            ];

            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  controls[0],
                  const SizedBox(height: 12),
                  controls[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: controls[0]),
                const SizedBox(width: 12),
                Expanded(child: controls[1]),
              ],
            );
          },
        ),
      ],
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

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No matching equipment',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the search or manufacturer filter to see more equipment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
