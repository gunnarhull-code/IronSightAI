import '../entities/equipment.dart';
import '../entities/equipment_details.dart';
import '../exceptions/duplicate_serial_number_exception.dart';
import '../repositories/equipment_repository.dart';

/// Updates an existing equipment record belonging to the current user's
/// company.
class UpdateEquipment {
  const UpdateEquipment(this._repository);

  final EquipmentRepository _repository;

  Future<Equipment> call({
    required String id,
    required String assetName,
    required String manufacturer,
    required String model,
    String? serialNumber,
    int? year,
    double? hours,
    String? location,
    String? notes,
  }) async {
    final details = EquipmentDetails.validated(
      assetName: assetName,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      year: year,
      hours: hours,
      location: location,
      notes: notes,
    );

    if (details.serialNumber != null) {
      final taken = await _repository.isSerialNumberTaken(
        details.serialNumber!,
        excludeEquipmentId: id,
      );
      if (taken) {
        throw const DuplicateSerialNumberException();
      }
    }

    return _repository.updateEquipment(id, details);
  }
}
