import 'package:drift/drift.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';
import '../local/drift/app_database.dart';

/// Drift-backed [LocalEquipmentCatalogRepository].
class DriftLocalEquipmentCatalogRepository
    implements LocalEquipmentCatalogRepository {
  DriftLocalEquipmentCatalogRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<List<Equipment>> listForCompany(String companyId) async {
    _requireNonEmpty(companyId, 'companyId');
    final rows =
        await (_db.select(_db.localEquipmentCache)
              ..where((table) => table.companyId.equals(companyId))
              ..orderBy([
                (table) => OrderingTerm(
                  expression: table.assetName,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    return rows.map(_toEquipment).toList(growable: false);
  }

  @override
  Future<Equipment?> getById({
    required String companyId,
    required String equipmentId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(equipmentId, 'equipmentId');
    final row =
        await (_db.select(_db.localEquipmentCache)..where(
              (table) =>
                  table.id.equals(equipmentId) &
                  table.companyId.equals(companyId),
            ))
            .getSingleOrNull();
    return row == null ? null : _toEquipment(row);
  }

  @override
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    final now = _clock();
    await _db.transaction(() async {
      await (_db.delete(
        _db.localEquipmentCache,
      )..where((table) => table.companyId.equals(companyId))).go();
      for (final item in equipment) {
        if (item.companyId != companyId) {
          throw StateError(
            'Refusing to cache equipment ${item.id} for company '
            '${item.companyId} into company $companyId catalog.',
          );
        }
        await _db
            .into(_db.localEquipmentCache)
            .insert(
              LocalEquipmentCacheCompanion.insert(
                id: item.id,
                companyId: item.companyId,
                assetName: item.assetName,
                manufacturer: item.manufacturer,
                model: item.model,
                serialNumber: Value(item.serialNumber),
                year: Value(item.year),
                hours: Value(item.hours),
                location: Value(item.location),
                notes: Value(item.notes),
                createdBy: Value(item.createdBy),
                createdByName: Value(item.createdByName),
                updatedBy: Value(item.updatedBy),
                updatedByName: Value(item.updatedByName),
                createdAt: item.createdAt.toUtc(),
                updatedAt: item.updatedAt.toUtc(),
                cachedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> clearCompany(String companyId) async {
    _requireNonEmpty(companyId, 'companyId');
    await (_db.delete(
      _db.localEquipmentCache,
    )..where((table) => table.companyId.equals(companyId))).go();
  }

  @override
  Future<void> clearAllExceptCompany(String companyId) async {
    _requireNonEmpty(companyId, 'companyId');
    await (_db.delete(
      _db.localEquipmentCache,
    )..where((table) => table.companyId.equals(companyId).not())).go();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.localEquipmentCache).go();
  }

  Equipment _toEquipment(LocalEquipmentCacheRow row) {
    return Equipment(
      id: row.id,
      companyId: row.companyId,
      assetName: row.assetName,
      manufacturer: row.manufacturer,
      model: row.model,
      serialNumber: row.serialNumber,
      year: row.year,
      hours: row.hours,
      location: row.location,
      notes: row.notes,
      createdBy: row.createdBy,
      createdByName: row.createdByName,
      updatedBy: row.updatedBy,
      updatedByName: row.updatedByName,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  void _requireNonEmpty(String value, String label) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, label, 'must not be empty');
    }
  }
}
