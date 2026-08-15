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
    final rows =
        await (_db.select(_db.localEquipmentCache)
              ..where((table) => table.companyId.equals(companyId)))
            .get();
    for (final row in rows) {
      final serial = row.serialNumber?.trim().toUpperCase();
      if (serial != null && serial.isNotEmpty && serial == normalized) {
        return _toEquipment(row);
      }
    }
    return null;
  }

  @override
  Future<Equipment> upsertLocalCreated(Equipment equipment) async {
    _requireNonEmpty(equipment.companyId, 'companyId');
    _requireNonEmpty(equipment.id, 'id');
    final now = _clock();
    await _db
        .into(_db.localEquipmentCache)
        .insertOnConflictUpdate(
          LocalEquipmentCacheCompanion.insert(
            id: equipment.id,
            companyId: equipment.companyId,
            assetName: equipment.assetName,
            manufacturer: equipment.manufacturer,
            model: equipment.model,
            serialNumber: Value(equipment.serialNumber),
            year: Value(equipment.year),
            hours: Value(equipment.hours),
            location: Value(equipment.location),
            notes: Value(equipment.notes),
            createdBy: Value(equipment.createdBy),
            createdByName: Value(equipment.createdByName),
            updatedBy: Value(equipment.updatedBy),
            updatedByName: Value(equipment.updatedByName),
            createdAt: equipment.createdAt.toUtc(),
            updatedAt: equipment.updatedAt.toUtc(),
            cachedAt: now,
            catalogOrigin: Value(
              LocalEquipmentCatalogOrigin.localCreated.storageValue,
            ),
          ),
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
                catalogOrigin: Value(
                  LocalEquipmentCatalogOrigin.remoteCache.storageValue,
                ),
              ),
            );
      }

      // Preserve offline-created machines that are not yet on the remote list.
      for (final local in existingLocal) {
        if (remoteIds.contains(local.id)) continue;
        await _db
            .into(_db.localEquipmentCache)
            .insert(
              LocalEquipmentCacheCompanion.insert(
                id: local.id,
                companyId: local.companyId,
                assetName: local.assetName,
                manufacturer: local.manufacturer,
                model: local.model,
                serialNumber: Value(local.serialNumber),
                year: Value(local.year),
                hours: Value(local.hours),
                location: Value(local.location),
                notes: Value(local.notes),
                createdBy: Value(local.createdBy),
                createdByName: Value(local.createdByName),
                updatedBy: Value(local.updatedBy),
                updatedByName: Value(local.updatedByName),
                createdAt: local.createdAt,
                updatedAt: local.updatedAt,
                cachedAt: now,
                catalogOrigin: Value(
                  LocalEquipmentCatalogOrigin.localCreated.storageValue,
                ),
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
      catalogOrigin: LocalEquipmentCatalogOrigin.fromStorage(row.catalogOrigin),
    );
  }

  void _requireNonEmpty(String value, String label) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, label, 'must not be empty');
    }
  }
}
