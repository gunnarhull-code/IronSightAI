import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/local_equipment_catalog_origin.dart';
import 'package:ironsight_ai/domain/repositories/local_equipment_catalog_repository.dart';

/// In-memory [LocalEquipmentCatalogRepository] for catalog-sync unit tests.
class FakeLocalEquipmentCatalogRepository
    implements LocalEquipmentCatalogRepository {
  final Map<String, Equipment> _byId = {};
  Object? upsertError;
  int upsertCallCount = 0;

  List<Equipment> storedFor(String companyId) {
    return _byId.values
        .where((item) => item.companyId == companyId)
        .toList(growable: false);
  }

  @override
  Future<List<Equipment>> listForCompany(String companyId) async {
    return storedFor(companyId);
  }

  @override
  Future<Equipment?> getById({
    required String companyId,
    required String equipmentId,
  }) async {
    final item = _byId[equipmentId];
    if (item == null || item.companyId != companyId) return null;
    return item;
  }

  @override
  Future<Equipment?> findBySerial({
    required String companyId,
    required String serialNumber,
  }) async {
    final normalized = serialNumber.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final item in storedFor(companyId)) {
      final serial = item.serialNumber?.trim().toUpperCase();
      if (serial != null && serial == normalized) return item;
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
    upsertCallCount += 1;
    if (upsertError != null) throw upsertError!;
    final existing = _byId[equipment.id];
    if (existing != null && existing.companyId != equipment.companyId) {
      throw StateError(
        'Refusing to cache equipment ${equipment.id} for company '
        '${equipment.companyId}; already cached for ${existing.companyId}.',
      );
    }
    final stored = equipment.copyWith(catalogOrigin: origin);
    _byId[equipment.id] = stored;
    return stored;
  }

  @override
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  }) async {
    _byId.removeWhere((id, item) {
      if (item.companyId != companyId) return false;
      return item.catalogOrigin != LocalEquipmentCatalogOrigin.localCreated ||
          equipment.any((remote) => remote.id == id);
    });
    for (final item in equipment) {
      if (item.companyId != companyId) {
        throw StateError(
          'Refusing to cache equipment ${item.id} for company '
          '${item.companyId} into company $companyId catalog.',
        );
      }
      _byId[item.id] = item.copyWith(
        catalogOrigin: LocalEquipmentCatalogOrigin.remoteCache,
      );
    }
  }

  @override
  Future<void> clearCompany(String companyId) async {
    _byId.removeWhere((_, item) => item.companyId == companyId);
  }

  @override
  Future<void> clearAllExceptCompany(String companyId) async {
    _byId.removeWhere((_, item) => item.companyId != companyId);
  }

  @override
  Future<void> clearAll() async {
    _byId.clear();
  }
}
