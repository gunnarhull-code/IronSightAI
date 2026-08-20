import '../entities/equipment.dart';

/// Whether the remote Equipment write that succeeded was a create or update.
enum EquipmentRemoteSaveOperation { create, update }

/// Remote Equipment create/update succeeded but the local catalog mirror failed.
///
/// Callers must not repeat the remote operation. Use
/// [LocalCatalogSyncingEquipmentRepository.retryLocalMirror] to retry only the
/// local upsert with [equipment].
class EquipmentLocalCatalogMirrorException implements Exception {
  const EquipmentLocalCatalogMirrorException({
    required this.equipment,
    required this.operation,
    required this.cause,
  });

  final Equipment equipment;
  final EquipmentRemoteSaveOperation operation;
  final Object cause;

  String get userMessage => messageFor(operation);

  static String messageFor(
    EquipmentRemoteSaveOperation operation,
  ) => switch (operation) {
    EquipmentRemoteSaveOperation.create =>
      'Equipment was saved online but could not yet be saved on this device.',
    EquipmentRemoteSaveOperation.update =>
      'Equipment was updated online but could not yet be saved on this device.',
  };

  @override
  String toString() => userMessage;
}
