import 'package:drift/drift.dart';

/// Tenant-scoped local equipment catalog used for offline inspection selection.
@DataClassName('LocalEquipmentCacheRow')
class LocalEquipmentCache extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get assetName => text()();
  TextColumn get manufacturer => text()();
  TextColumn get model => text()();
  TextColumn get serialNumber => text().nullable()();
  IntColumn get year => integer().nullable()();
  RealColumn get hours => real().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get createdByName => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  TextColumn get updatedByName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
