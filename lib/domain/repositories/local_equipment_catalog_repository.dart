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

  Future<void> clearCompany(String companyId);

  /// Removes cached equipment that does not belong to [companyId].
  Future<void> clearAllExceptCompany(String companyId);

  Future<void> clearAll();
}
