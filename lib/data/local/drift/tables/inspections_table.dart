import 'package:drift/drift.dart';

/// Local inspections table — source of truth during offline capture.
@DataClassName('LocalInspectionRow')
class Inspections extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get equipmentId => text()();
  TextColumn get createdByUserId => text()();
  TextColumn get updatedByUserId => text().nullable()();
  TextColumn get completionStatus => text()();
  TextColumn get localLifecycle => text()();
  TextColumn get depth => text()();
  TextColumn get syncStatus => text()();
  TextColumn get reportStatus => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get overallNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get discardedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
