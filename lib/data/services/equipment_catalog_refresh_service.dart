import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';

/// Best-effort remote → local equipment catalog refresh.
///
/// Never throws to callers that fire-and-forget. Inspection flows must keep
/// reading the local catalog even when this fails.
class EquipmentCatalogRefreshService {
  EquipmentCatalogRefreshService({
    required EquipmentRepository remoteEquipmentRepository,
    required LocalEquipmentCatalogRepository localCatalog,
  }) : _remote = remoteEquipmentRepository,
       _local = localCatalog;

  final EquipmentRepository _remote;
  final LocalEquipmentCatalogRepository _local;

  /// Attempts a remote fetch and replaces the local company catalog.
  ///
  /// Returns `true` when the local catalog was updated. Returns `false` when
  /// the network/remote call failed — local data is left unchanged.
  Future<bool> refreshCompanyCatalog(String companyId) async {
    if (companyId.trim().isEmpty) return false;
    try {
      final remote = await _remote.getEquipment();
      final scoped = remote
          .where((item) => item.companyId == companyId)
          .toList(growable: false);
      await _local.replaceCompanyCatalog(
        companyId: companyId,
        equipment: scoped,
      );
      return true;
    } on Object {
      return false;
    }
  }
}
