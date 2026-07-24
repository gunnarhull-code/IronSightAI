import '../entities/equipment.dart';
import '../entities/equipment_details.dart';
import '../exceptions/duplicate_serial_number_exception.dart';
import '../repositories/equipment_repository.dart';

/// Creates a new equipment record for the current user's company.
class CreateEquipment {
  const CreateEquipment(this._repository);

  final EquipmentRepository _repository;

  Future<Equipment> call({
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
      );
      if (taken) {
        throw const DuplicateSerialNumberException();
      }
    }

    return _repository.createEquipment(details);
  }
}
