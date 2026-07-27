import '../../domain/entities/local_tenant_context.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../domain/repositories/local_tenant_context_repository.dart';
import '../local/drift/app_database.dart';
import '../local/drift/tables/local_tenant_contexts_table.dart';

/// Drift-backed [LocalTenantContextRepository].
class DriftLocalTenantContextRepository
    implements LocalTenantContextRepository {
  DriftLocalTenantContextRepository(
    this._db,
    this._equipmentCatalog, {
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final LocalEquipmentCatalogRepository _equipmentCatalog;
  final DateTime Function() _clock;

  @override
  Future<LocalTenantContext?> getActive() async {
    final row =
        await (_db.select(_db.localTenantContexts)
              ..where((table) => table.id.equals(kActiveLocalTenantContextId)))
            .getSingleOrNull();
    if (row == null) return null;
    return LocalTenantContext(
      companyId: row.companyId,
      userId: row.userId,
      activatedAt: row.activatedAt,
    );
  }

  @override
  Future<LocalTenantContext> activate({
    required String companyId,
    required String userId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(userId, 'userId');

    final previous = await getActive();
    final now = _clock();
    final next = LocalTenantContext(
      companyId: companyId,
      userId: userId,
      activatedAt: now,
    );

    await _db
        .into(_db.localTenantContexts)
        .insertOnConflictUpdate(
          LocalTenantContextsCompanion.insert(
            id: kActiveLocalTenantContextId,
            companyId: companyId,
            userId: userId,
            activatedAt: now,
          ),
        );

    final switchedTenant =
        previous != null &&
        (previous.companyId != companyId || previous.userId != userId);
    if (switchedTenant) {
      // Drop other tenants' cached equipment so selection never mixes catalogs.
      await _equipmentCatalog.clearAllExceptCompany(companyId);
    }

    return next;
  }

  @override
  Future<void> clear() async {
    await (_db.delete(
      _db.localTenantContexts,
    )..where((table) => table.id.equals(kActiveLocalTenantContextId))).go();
  }

  void _requireNonEmpty(String value, String label) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, label, 'must not be empty');
    }
  }
}
