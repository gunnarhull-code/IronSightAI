import '../repositories/equipment_repository.dart';

/// Deletes an existing equipment record belonging to the current user's
/// company.
class DeleteEquipment {
  const DeleteEquipment(this._repository);

  final EquipmentRepository _repository;

  Future<void> call(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Equipment id is required');
    }
    return _repository.deleteEquipment(id);
  }
}
