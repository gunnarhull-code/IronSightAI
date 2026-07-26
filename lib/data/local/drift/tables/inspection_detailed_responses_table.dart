import 'package:drift/drift.dart';

import 'inspections_table.dart';

/// Category-level detailed checklist responses for future expansion.
@DataClassName('LocalDetailedResponseRow')
class InspectionDetailedResponses extends Table {
  TextColumn get id => text()();
  TextColumn get inspectionId =>
      text().references(Inspections, #id, onDelete: KeyAction.cascade)();
  TextColumn get companyId => text()();
  TextColumn get category => text()();
  TextColumn get itemKey => text()();
  TextColumn get labelSnapshot => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get rating => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {inspectionId, category, itemKey},
      ];
}
