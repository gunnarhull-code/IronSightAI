import 'package:drift/drift.dart';

/// Local inspection media metadata — binary files live under app documents.
@DataClassName('LocalInspectionMediaRow')
class InspectionMediaItems extends Table {
  @override
  String get tableName => 'inspection_media';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get inspectionId => text()();
  TextColumn get slot => text()();
  TextColumn get localRelativePath => text()();
  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer()();
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
