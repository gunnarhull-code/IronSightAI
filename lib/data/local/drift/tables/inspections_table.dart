import 'package:drift/drift.dart';

/// Local inspections table — source of truth during offline capture.
@DataClassName('LocalInspectionRow')
class Inspections extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();

  /// Linked Equipment id. Null only while a New-machine guided draft is
  /// incomplete — Equipment is created atomically at successful completion.
  TextColumn get equipmentId => text().nullable()();

  TextColumn get createdByUserId => text()();
  TextColumn get updatedByUserId => text().nullable()();
  TextColumn get completionStatus => text()();
  TextColumn get localLifecycle => text()();
  TextColumn get depth => text()();
  TextColumn get syncStatus => text()();
  TextColumn get reportStatus => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get overallNotes => text().nullable()();

  /// Confirmed serial for this inspection draft (explicit human confirm only).
  TextColumn get serialNumber => text().nullable()();
  TextColumn get serialCaptureMethod => text().nullable()();

  /// Confirmed hour-meter reading for this inspection draft.
  RealColumn get hourMeterReading => real().nullable()();
  TextColumn get hourMeterCaptureMethod => text().nullable()();

  /// Guided intake: new_machine | existing_equipment. Null = legacy draft.
  TextColumn get machineSource => text().nullable()();

  /// Pending New-machine identity (not an Equipment row until completion).
  TextColumn get pendingAssetName => text().nullable()();
  TextColumn get pendingManufacturer => text().nullable()();
  TextColumn get pendingModel => text().nullable()();

  /// Last visited guided step storage value.
  TextColumn get guidedStep => text().nullable()();

  /// Stable Equipment id reserved for New-machine completion idempotency.
  TextColumn get pendingEquipmentId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get discardedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
