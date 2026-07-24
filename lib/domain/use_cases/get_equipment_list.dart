import '../entities/equipment.dart';
import '../repositories/equipment_repository.dart';

/// Loads all equipment belonging to the current user's company.
class GetEquipmentList {
  const GetEquipmentList(this._repository);

  final EquipmentRepository _repository;

  Future<List<Equipment>> call() => _repository.getEquipment();
}
