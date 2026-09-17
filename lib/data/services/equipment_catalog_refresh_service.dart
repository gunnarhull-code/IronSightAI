import '../../domain/entities/equipment.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';

/// Best-effort remote → local equipment catalog refresh.
///
/// Never throws to callers that fire-and-forget. Inspection flows must keep
/// reading the local catalog even when this fails.
///
/// Successful remote create/edit mirroring [mirrorRemoteEquipment] bumps a
/// per-company generation so a refresh that started against an older snapshot
/// cannot replace newer confirmed local mutations.
class EquipmentCatalogRefreshService {
  EquipmentCatalogRefreshService({
    required EquipmentRepository remoteEquipmentRepository,
    required LocalEquipmentCatalogRepository localCatalog,
  }) : _remote = remoteEquipmentRepository,
       _local = localCatalog;

  final EquipmentRepository _remote;
  final LocalEquipmentCatalogRepository _local;
  final Map<String, int> _generationByCompany = {};
  final Map<String, Future<void>> _locksByCompany = {};

  /// Attempts a remote fetch and replaces the local company catalog.
  ///
  /// Returns `true` when the local catalog was updated. Returns `false` when
  /// the network/remote call failed, or when a newer local create/edit landed
  /// while this refresh was in flight — local data is left unchanged.
  Future<bool> refreshCompanyCatalog(String companyId) async {
    if (companyId.trim().isEmpty) return false;
    final startedGeneration = _generation(companyId);
    try {
      final remote = await _remote.getEquipment();
      return _serialized(companyId, () async {
        if (_generation(companyId) != startedGeneration) {
          return false;
        }
        final scoped = remote
            .where((item) => item.companyId == companyId)
            .toList(growable: false);
        await _local.replaceCompanyCatalog(
          companyId: companyId,
          equipment: scoped,
        );
        return true;
      });
    } on Object {
      return false;
    }
  }

  /// Upserts canonical remote Equipment into its own company catalog.
  ///
  /// Bumps the company generation before writing so in-flight refreshes that
  /// captured an older snapshot are discarded. Failures propagate — callers
  /// must not retry the remote create.
  Future<Equipment> mirrorRemoteEquipment(Equipment equipment) {
    final companyId = equipment.companyId.trim();
    if (companyId.isEmpty) {
      throw ArgumentError.value(
        equipment.companyId,
        'companyId',
        'must not be empty',
      );
    }
    if (equipment.id.trim().isEmpty) {
      throw ArgumentError.value(equipment.id, 'id', 'must not be empty');
    }
    return _serialized(companyId, () async {
      _generationByCompany[companyId] = _generation(companyId) + 1;
      return _local.upsertEquipment(equipment);
    });
  }

  int _generation(String companyId) => _generationByCompany[companyId] ?? 0;

  /// Serializes catalog writes per company so an in-flight replace cannot
  /// interleave with a newer upsert (Dart events can resume between awaits).
  Future<T> _serialized<T>(String companyId, Future<T> Function() action) {
    final previous = _locksByCompany[companyId] ?? Future<void>.value();
    final result = previous.then((_) => action());
    _locksByCompany[companyId] = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
