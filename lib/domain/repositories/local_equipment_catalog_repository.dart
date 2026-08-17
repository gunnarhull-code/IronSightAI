import '../entities/equipment.dart';

/// Tenant-scoped local equipment catalog for offline inspection selection.
///
/// Reads never hit the network. Refresh is a separate, non-blocking operation.
abstract class LocalEquipmentCatalogRepository {
  Future<List<Equipment>> listForCompany(String companyId);

  Future<Equipment?> getById({
    required String companyId,
    required String equipmentId,
  });

  /// Replaces the entire cached catalog for [companyId].
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  });

  /// Inserts or updates one cached equipment row for its [Equipment.companyId].
  ///
  /// Used when remote create/update succeeds so Quick Appraisal can start from
  /// the new record without waiting on a full catalog refresh.
  Future<void> upsertEquipment(Equipment equipment);

  /// Removes one cached row when it belongs to [companyId].
  Future<void> removeEquipment({
    required String companyId,
    required String equipmentId,
  });

  Future<void> clearCompany(String companyId);

  /// Removes cached equipment that does not belong to [companyId].
  Future<void> clearAllExceptCompany(String companyId);

  Future<void> clearAll();
}
