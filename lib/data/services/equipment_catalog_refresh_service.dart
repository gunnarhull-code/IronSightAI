import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';

/// Best-effort remote → local equipment catalog refresh.
///
/// Never throws to callers that fire-and-forget. Inspection flows must keep
/// reading the local catalog even when this fails.
///
/// Overlapping refreshes are generation-guarded: a slower older fetch must not
/// replace the catalog after a newer refresh (or a create upsert) has already
/// applied a fresher remote snapshot.
class EquipmentCatalogRefreshService {
  EquipmentCatalogRefreshService({
    required EquipmentRepository remoteEquipmentRepository,
    required LocalEquipmentCatalogRepository localCatalog,
  }) : _remote = remoteEquipmentRepository,
       _local = localCatalog;

  final EquipmentRepository _remote;
  final LocalEquipmentCatalogRepository _local;

  int _generation = 0;

  /// Drops in-flight refresh results so they cannot overwrite a newer local
  /// catalog mutation (for example an equipment create upsert).
  void discardInFlightRefreshes() {
    _generation++;
  }

  /// Attempts a remote fetch and replaces the local company catalog.
  ///
  /// Returns `true` when the local catalog was updated. Returns `false` when
  /// the network/remote call failed, or when a newer refresh / local mutation
  /// superseded this one — local data is left unchanged in those cases.
  Future<bool> refreshCompanyCatalog(String companyId) async {
    if (companyId.trim().isEmpty) return false;
    final generation = ++_generation;
    try {
      final remote = await _remote.getEquipment();
      if (generation != _generation) return false;
      final scoped = remote
          .where((item) => item.companyId == companyId)
          .toList(growable: false);
      if (generation != _generation) return false;
      await _local.replaceCompanyCatalog(
        companyId: companyId,
        equipment: scoped,
      );
      return generation == _generation;
    } on Object {
      return false;
    }
  }
}
