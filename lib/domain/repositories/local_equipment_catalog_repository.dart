import '../entities/equipment.dart';
import '../entities/local_equipment_catalog_origin.dart';

/// Tenant-scoped local equipment catalog for offline inspection selection.
///
/// Reads never hit the network. Refresh is a separate, non-blocking operation.
abstract class LocalEquipmentCatalogRepository {
  Future<List<Equipment>> listForCompany(String companyId);

  Future<Equipment?> getById({
    required String companyId,
    required String equipmentId,
  });

  /// Finds same-company equipment whose serial matches [serialNumber]
  /// (case-insensitive, trimmed). Never returns other companies.
  Future<Equipment?> findBySerial({
    required String companyId,
    required String serialNumber,
  });

  /// Inserts or updates a locally created Equipment row (offline New-machine).
  Future<Equipment> upsertLocalCreated(Equipment equipment);

  /// Inserts or updates a remote-canonical Equipment row for its own company.
  ///
  /// Never writes into a different company's catalog. If [equipment.id]
  /// already exists under another company, implementations must refuse rather
  /// than overwrite or fall back across tenants.
  Future<Equipment> upsertEquipment(Equipment equipment);

  /// Replaces the remote-mirrored catalog for [companyId].
  ///
  /// Rows with [LocalEquipmentCatalogOrigin.localCreated] that are absent from
  /// [equipment] are preserved so offline-created machines are not wiped.
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  });

  Future<void> clearCompany(String companyId);

  /// Removes cached equipment that does not belong to [companyId].
  Future<void> clearAllExceptCompany(String companyId);

  Future<void> clearAll();
}
