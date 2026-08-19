/// Whether a database file already carries the guided (v5) inspections shape.
enum LocalGuidedSchemaState {
  /// Every guided column and the nullable `equipment_id` are already present.
  applied,

  /// A clean pre-guided (v4 or older) shape that the v5 migration can apply.
  notApplied,

  /// Neither shape. Migrating could destroy rows, so callers must fail closed.
  indeterminate,
}

/// Result of inspecting the physical schema before migrating it.
class LocalGuidedSchemaProbe {
  const LocalGuidedSchemaProbe({required this.state, required this.details});

  final LocalGuidedSchemaState state;

  /// Schema metadata only (table / column names and null-ability) so this is
  /// safe to log and attach to errors. Never contains row values.
  final String details;

  @override
  String toString() => 'LocalGuidedSchemaProbe(${state.name}: $details)';
}

/// Columns the guided (v5) intake adds to `inspections`.
const Set<String> kGuidedInspectionColumns = {
  'machine_source',
  'pending_asset_name',
  'pending_manufacturer',
  'pending_model',
  'guided_step',
  'pending_equipment_id',
};

/// Classifies the physical schema from `PRAGMA table_info` metadata.
///
/// [inspectionColumnsNotNull] maps each `inspections` column to its NOT NULL
/// flag, and is empty when the table does not exist. Only the fully applied and
/// the clean pre-guided shapes are actionable; anything else is
/// [LocalGuidedSchemaState.indeterminate] so no data is rebuilt on a guess.
LocalGuidedSchemaProbe classifyGuidedSchema({
  required Map<String, bool> inspectionColumnsNotNull,
  required bool hasEquipmentCacheTable,
  required Set<String> equipmentCacheColumns,
}) {
  final guidedPresent = kGuidedInspectionColumns
      .where(inspectionColumnsNotNull.containsKey)
      .toList(growable: false);
  final hasCatalogOrigin = equipmentCacheColumns.contains('catalog_origin');
  final equipmentIdNotNull = inspectionColumnsNotNull['equipment_id'];

  final details =
      'inspections: ${inspectionColumnsNotNull.isEmpty ? 'missing' : 'present'}, '
      'guided columns ${guidedPresent.length}/${kGuidedInspectionColumns.length}, '
      'equipment_id nullable: ${equipmentIdNotNull == null ? 'absent' : !equipmentIdNotNull}, '
      'local_equipment_cache: ${hasEquipmentCacheTable ? 'present' : 'missing'}, '
      'catalog_origin: ${hasCatalogOrigin ? 'present' : 'missing'}';

  if (equipmentIdNotNull == null) {
    return LocalGuidedSchemaProbe(
      state: LocalGuidedSchemaState.indeterminate,
      details: details,
    );
  }

  final fullyApplied =
      guidedPresent.length == kGuidedInspectionColumns.length &&
      !equipmentIdNotNull &&
      hasEquipmentCacheTable &&
      hasCatalogOrigin;
  if (fullyApplied) {
    return LocalGuidedSchemaProbe(
      state: LocalGuidedSchemaState.applied,
      details: details,
    );
  }

  // An equipment cache table from v2+ is expected here; only its guided
  // `catalog_origin` column is new in v5.
  final cleanPreGuided =
      guidedPresent.isEmpty && equipmentIdNotNull && !hasCatalogOrigin;
  if (cleanPreGuided) {
    return LocalGuidedSchemaProbe(
      state: LocalGuidedSchemaState.notApplied,
      details: details,
    );
  }

  return LocalGuidedSchemaProbe(
    state: LocalGuidedSchemaState.indeterminate,
    details: details,
  );
}
