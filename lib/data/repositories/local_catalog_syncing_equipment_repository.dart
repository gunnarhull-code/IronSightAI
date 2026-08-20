import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_details.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../services/equipment_catalog_refresh_service.dart';

/// Remote [EquipmentRepository] that mirrors successful create/update into the
/// company-local catalog immediately.
///
/// Remote work runs first. A remote failure never mutates the local catalog.
/// A local-catalog failure after remote success propagates and does not retry
/// the remote write. Delete is not mirrored.
class LocalCatalogSyncingEquipmentRepository implements EquipmentRepository {
  LocalCatalogSyncingEquipmentRepository({
    required EquipmentRepository remote,
    required EquipmentCatalogRefreshService catalogRefresh,
  }) : _remote = remote,
       _catalogRefresh = catalogRefresh;

  final EquipmentRepository _remote;
  final EquipmentCatalogRefreshService _catalogRefresh;

  @override
  Future<List<Equipment>> getEquipment() => _remote.getEquipment();

  @override
  Future<Equipment?> getEquipmentById(String id) =>
      _remote.getEquipmentById(id);

  @override
  Future<Equipment> createEquipment(EquipmentDetails details) async {
    final created = await _remote.createEquipment(details);
    await _catalogRefresh.mirrorRemoteEquipment(created);
    return created;
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) async {
    final updated = await _remote.updateEquipment(id, details);
    await _catalogRefresh.mirrorRemoteEquipment(updated);
    return updated;
  }

  @override
  Future<void> deleteEquipment(String id) => _remote.deleteEquipment(id);

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
