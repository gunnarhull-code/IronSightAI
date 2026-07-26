import 'package:drift/drift.dart';

import 'inspections_table.dart';

/// Quick Condition Scorecard ratings keyed by inspection + category.
@DataClassName('LocalCategoryRatingRow')
class InspectionCategoryRatings extends Table {
  TextColumn get id => text()();
  TextColumn get inspectionId =>
      text().references(Inspections, #id, onDelete: KeyAction.cascade)();
  TextColumn get companyId => text()();
  TextColumn get category => text()();
  TextColumn get rating => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {inspectionId, category},
      ];
}
