import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_details.dart';
import '../../domain/exceptions/equipment_local_catalog_mirror_exception.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_catalog_mirror_recovery.dart';
import '../services/equipment_catalog_refresh_service.dart';

/// Remote [EquipmentRepository] that mirrors successful create/update into the
/// company-local catalog immediately.
///
/// Remote work runs first. A remote failure never mutates the local catalog.
/// A local-catalog failure after remote success throws
/// [EquipmentLocalCatalogMirrorException] and does not retry the remote write.
/// Delete is not mirrored.
class LocalCatalogSyncingEquipmentRepository
    implements EquipmentRepository, LocalCatalogMirrorRecovery {
  LocalCatalogSyncingEquipmentRepository({
    required EquipmentRepository remoteEquipmentRepository,
    required EquipmentCatalogRefreshService catalogRefreshService,
  }) : _remote = remoteEquipmentRepository,
       _catalogRefresh = catalogRefreshService;

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
    try {
      await _catalogRefresh.mirrorRemoteEquipment(created);
    } on Object catch (cause) {
      throw EquipmentLocalCatalogMirrorException(
        equipment: created,
        operation: EquipmentRemoteSaveOperation.create,
        cause: cause,
      );
    }
    return created;
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) async {
    final updated = await _remote.updateEquipment(id, details);
    try {
      await _catalogRefresh.mirrorRemoteEquipment(updated);
    } on Object catch (cause) {
      throw EquipmentLocalCatalogMirrorException(
        equipment: updated,
        operation: EquipmentRemoteSaveOperation.update,
        cause: cause,
      );
    }
    return updated;
  }

  @override
  Future<Equipment> retryLocalMirror(Equipment equipment) async {
    await _catalogRefresh.mirrorRemoteEquipment(equipment);
    return equipment;
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
