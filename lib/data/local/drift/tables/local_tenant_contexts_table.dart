import 'package:drift/drift.dart';

/// Active local company/user context for offline inspection work.
///
/// Single-row table (`id` is always [kActiveLocalTenantContextId]). Switching
/// tenants updates this row and clears non-matching cached equipment.
@DataClassName('LocalTenantContextRow')
class LocalTenantContexts extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get activatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

const String kActiveLocalTenantContextId = 'active';
