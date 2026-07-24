import '../entities/equipment.dart';
import '../entities/equipment_details.dart';

/// Persistence boundary for equipment records.
///
/// Every method scopes automatically to the authenticated user's company.
/// Implementations must derive the company from the current session — never
/// from a company id supplied by the UI — and rely on Postgres Row Level
/// Security as the enforced tenant boundary underneath that.
abstract class EquipmentRepository {
  /// Returns all equipment belonging to the current user's company.
  Future<List<Equipment>> getEquipment();

  /// Returns a single equipment record by id, or `null` if it does not
  /// exist or does not belong to the current user's company.
  Future<Equipment?> getEquipmentById(String id);

  /// Creates a new equipment record for the current user's company.
  Future<Equipment> createEquipment(EquipmentDetails details);

  /// Updates an existing equipment record belonging to the current user's
  /// company.
  Future<Equipment> updateEquipment(String id, EquipmentDetails details);

  /// Returns true if [serialNumber] is already used by another equipment
  /// record in the current user's company.
  ///
  /// Never checks across companies — this is scoped identically to every
  /// other method on this repository. When [excludeEquipmentId] is provided,
  /// that record is excluded from the check, so editing a record without
  /// changing its own serial number is not flagged as a duplicate of itself.
  Future<bool> isSerialNumberTaken(
    String serialNumber, {
    String? excludeEquipmentId,
  });
}
