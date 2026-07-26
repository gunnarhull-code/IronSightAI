import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/equipment_details.dart';
import 'package:ironsight_ai/domain/repositories/equipment_repository.dart';

/// In-memory [EquipmentRepository] for widget and unit tests.
class FakeEquipmentRepository implements EquipmentRepository {
  FakeEquipmentRepository({
    List<Equipment>? equipment,
    this.getError,
    this.createDelay = Duration.zero,
    this.updateDelay = Duration.zero,
  }) : equipment = equipment ?? [];

  List<Equipment> equipment;
  Object? getError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Duration createDelay;
  Duration updateDelay;

  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  EquipmentDetails? lastCreatedDetails;
  EquipmentDetails? lastUpdatedDetails;
  String? lastUpdatedId;
  String? lastDeletedId;

  static const String _companyId = 'company-1';
  int _nextId = 1;

  @override
  Future<List<Equipment>> getEquipment() async {
    if (getError != null) throw getError!;
    return List.unmodifiable(equipment);
  }

  @override
  Future<Equipment?> getEquipmentById(String id) async {
    if (getError != null) throw getError!;
    for (final item in equipment) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Equipment> createEquipment(EquipmentDetails details) async {
    createCallCount += 1;
    lastCreatedDetails = details;
    if (createDelay > Duration.zero) {
      await Future<void>.delayed(createDelay);
    }
    if (createError != null) throw createError!;

    final now = DateTime.utc(2026, 1, 1);
    final created = Equipment(
      id: 'equipment-${_nextId++}',
      companyId: _companyId,
      assetName: details.assetName,
      manufacturer: details.manufacturer,
      model: details.model,
      serialNumber: details.serialNumber,
      year: details.year,
      hours: details.hours,
      location: details.location,
      notes: details.notes,
      createdBy: 'user-1',
      createdByName: 'Gunnar Hull',
      updatedBy: 'user-1',
      updatedByName: 'Gunnar Hull',
      createdAt: now,
      updatedAt: now,
    );
    equipment = [...equipment, created];
    return created;
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) async {
    updateCallCount += 1;
    lastUpdatedId = id;
    lastUpdatedDetails = details;
    if (updateDelay > Duration.zero) {
      await Future<void>.delayed(updateDelay);
    }
    if (updateError != null) throw updateError!;

    final index = equipment.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Equipment not found');
    }

    final existing = equipment[index];
    final updated = Equipment(
      id: existing.id,
      companyId: existing.companyId,
      assetName: details.assetName,
      manufacturer: details.manufacturer,
      model: details.model,
      serialNumber: details.serialNumber,
      year: details.year,
      hours: details.hours,
      location: details.location,
      notes: details.notes,
      createdBy: existing.createdBy,
      createdByName: existing.createdByName,
      updatedBy: 'user-1',
      updatedByName: 'Gunnar Hull',
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    equipment = [...equipment]..[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEquipment(String id) async {
    deleteCallCount += 1;
    lastDeletedId = id;
    if (deleteError != null) throw deleteError!;

    equipment = equipment.where((item) => item.id != id).toList();
  }

  int isSerialNumberTakenCallCount = 0;

  @override
  Future<bool> isSerialNumberTaken(
    String serialNumber, {
    String? excludeEquipmentId,
  }) async {
    isSerialNumberTakenCallCount += 1;
    return equipment.any(
      (item) =>
          item.serialNumber == serialNumber && item.id != excludeEquipmentId,
    );
  }
}
