import 'package:drift/drift.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/entities/local_equipment_catalog_origin.dart';
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
  Future<Equipment?> findBySerial({
    required String companyId,
    required String serialNumber,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    final normalized = serialNumber.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final rows = await (_db.select(
      _db.localEquipmentCache,
    )..where((table) => table.companyId.equals(companyId))).get();
    for (final row in rows) {
      final serial = row.serialNumber?.trim().toUpperCase();
      if (serial != null && serial.isNotEmpty && serial == normalized) {
        return _toEquipment(row);
      }
    }
    return null;
  }

  @override
  Future<Equipment> upsertLocalCreated(Equipment equipment) {
    return _upsert(equipment, origin: LocalEquipmentCatalogOrigin.localCreated);
  }

  @override
  Future<Equipment> upsertEquipment(Equipment equipment) {
    return _upsert(equipment, origin: LocalEquipmentCatalogOrigin.remoteCache);
  }

  Future<Equipment> _upsert(
    Equipment equipment, {
    required LocalEquipmentCatalogOrigin origin,
  }) async {
    _requireNonEmpty(equipment.companyId, 'companyId');
    _requireNonEmpty(equipment.id, 'id');

    final existingById = await (_db.select(
      _db.localEquipmentCache,
    )..where((table) => table.id.equals(equipment.id))).getSingleOrNull();
    if (existingById != null && existingById.companyId != equipment.companyId) {
      throw StateError(
        'Refusing to cache equipment ${equipment.id} for company '
        '${equipment.companyId}; already cached for ${existingById.companyId}.',
      );
    }

    final now = _clock();
    await _db
        .into(_db.localEquipmentCache)
        .insertOnConflictUpdate(
          _companion(equipment, cachedAt: now, origin: origin),
        );
    return (await getById(
      companyId: equipment.companyId,
      equipmentId: equipment.id,
    ))!;
  }

  @override
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    final now = _clock();
    await _db.transaction(() async {
      final existingLocal =
          await (_db.select(_db.localEquipmentCache)..where(
                (table) =>
                    table.companyId.equals(companyId) &
                    table.catalogOrigin.equals(
                      LocalEquipmentCatalogOrigin.localCreated.storageValue,
                    ),
              ))
              .get();

      await (_db.delete(
        _db.localEquipmentCache,
      )..where((table) => table.companyId.equals(companyId))).go();

      final remoteIds = <String>{};
      for (final item in equipment) {
        if (item.companyId != companyId) {
          throw StateError(
            'Refusing to cache equipment ${item.id} for company '
            '${item.companyId} into company $companyId catalog.',
          );
        }
        remoteIds.add(item.id);
        await _db
            .into(_db.localEquipmentCache)
            .insert(
              _companion(
                item,
                cachedAt: now,
                origin: LocalEquipmentCatalogOrigin.remoteCache,
              ),
            );
      }

      // Preserve offline-created machines that are not yet on the remote list.
      for (final local in existingLocal) {
        if (remoteIds.contains(local.id)) continue;
        await _db
            .into(_db.localEquipmentCache)
            .insert(
              _companion(
                _toEquipment(local),
                cachedAt: now,
                origin: LocalEquipmentCatalogOrigin.localCreated,
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

  LocalEquipmentCacheCompanion _companion(
    Equipment item, {
    required DateTime cachedAt,
    required LocalEquipmentCatalogOrigin origin,
  }) {
    return LocalEquipmentCacheCompanion.insert(
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
      cachedAt: cachedAt,
      catalogOrigin: Value(origin.storageValue),
    );
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
      catalogOrigin: LocalEquipmentCatalogOrigin.fromStorage(row.catalogOrigin),
    );
  }

  void _requireNonEmpty(String value, String label) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, label, 'must not be empty');
    }
  }
}
