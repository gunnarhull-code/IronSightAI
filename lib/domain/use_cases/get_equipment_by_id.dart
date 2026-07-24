import '../entities/equipment.dart';
import '../repositories/equipment_repository.dart';

/// Loads a single equipment record by id, scoped to the current company.
class GetEquipmentById {
  const GetEquipmentById(this._repository);

  final EquipmentRepository _repository;

  Future<Equipment?> call(String id) => _repository.getEquipmentById(id);
}
