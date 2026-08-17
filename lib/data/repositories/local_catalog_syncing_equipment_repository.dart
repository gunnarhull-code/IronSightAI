import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_details.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';

/// Remote [EquipmentRepository] that keeps the local inspection catalog in sync.
///
/// Quick Appraisal starts from Drift `local_equipment_cache`, not live
/// PostgREST. Without this mirror, a just-created equipment row can be missing
/// from the local catalog until a racy full refresh completes.
class LocalCatalogSyncingEquipmentRepository implements EquipmentRepository {
  LocalCatalogSyncingEquipmentRepository({
    required EquipmentRepository remote,
    required LocalEquipmentCatalogRepository localCatalog,
  }) : _remote = remote,
       _localCatalog = localCatalog;

  final EquipmentRepository _remote;
  final LocalEquipmentCatalogRepository _localCatalog;

  /// Underlying remote repository (catalog refresh must not recurse through
  /// sync-on-write).
  EquipmentRepository get remote => _remote;

  @override
  Future<List<Equipment>> getEquipment() => _remote.getEquipment();

  @override
  Future<Equipment?> getEquipmentById(String id) =>
      _remote.getEquipmentById(id);

  @override
  Future<Equipment> createEquipment(EquipmentDetails details) async {
    final created = await _remote.createEquipment(details);
    await _localCatalog.upsertEquipment(created);
    return created;
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) async {
    final updated = await _remote.updateEquipment(id, details);
    await _localCatalog.upsertEquipment(updated);
    return updated;
  }

  @override
  Future<void> deleteEquipment(String id) async {
    final existing = await _remote.getEquipmentById(id);
    await _remote.deleteEquipment(id);
    if (existing != null) {
      await _localCatalog.removeEquipment(
        companyId: existing.companyId,
        equipmentId: existing.id,
      );
    }
  }

  @override
  Future<bool> isSerialNumberTaken(
    String serialNumber, {
    String? excludeEquipmentId,
  }) {
    return _remote.isSerialNumberTaken(
      serialNumber,
      excludeEquipmentId: excludeEquipmentId,
    );
  }
}
