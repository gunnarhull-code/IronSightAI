import '../../domain/repositories/auth_session_reader.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../domain/repositories/local_inspection_repository.dart';
import '../../domain/repositories/local_tenant_context_repository.dart';
import '../repositories/drift_local_equipment_catalog_repository.dart';
import '../repositories/drift_local_inspection_repository.dart';
import '../repositories/drift_local_tenant_context_repository.dart';
import '../services/equipment_catalog_refresh_service.dart';
import 'drift/app_database.dart';
import 'drift/open_inspection_database.dart';

/// Local-first offline inspection workspace dependencies.
///
/// Constructed at the composition root. Feature widgets depend only on the
/// repository interfaces exposed here.
class OfflineInspectionWorkspace {
  OfflineInspectionWorkspace({
    required this.database,
    required this.inspections,
    required this.equipmentCatalog,
    required this.tenantContext,
    required this.catalogRefresh,
    required this.authSession,
  });

  final AppDatabase database;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;
  final LocalTenantContextRepository tenantContext;
  final EquipmentCatalogRefreshService catalogRefresh;
  final AuthSessionReader authSession;

  static Future<OfflineInspectionWorkspace> open({
    required EquipmentRepository remoteEquipmentRepository,
    required AuthSessionReader authSession,
    bool requireCipher = true,
  }) async {
    final database = await openEncryptedInspectionDatabase(
      requireCipher: requireCipher,
    );
    return fromDatabase(
      database: database,
      remoteEquipmentRepository: remoteEquipmentRepository,
      authSession: authSession,
    );
  }

  /// Builds a workspace around an already-opened database (tests / memory).
  static OfflineInspectionWorkspace fromDatabase({
    required AppDatabase database,
    required EquipmentRepository remoteEquipmentRepository,
    required AuthSessionReader authSession,
  }) {
    final equipmentCatalog = DriftLocalEquipmentCatalogRepository(database);
    final tenantContext = DriftLocalTenantContextRepository(
      database,
      equipmentCatalog,
    );
    final inspections = DriftLocalInspectionRepository(database);
    final catalogRefresh = EquipmentCatalogRefreshService(
      remoteEquipmentRepository: remoteEquipmentRepository,
      localCatalog: equipmentCatalog,
    );
    return OfflineInspectionWorkspace(
      database: database,
      inspections: inspections,
      equipmentCatalog: equipmentCatalog,
      tenantContext: tenantContext,
      catalogRefresh: catalogRefresh,
      authSession: authSession,
    );
  }

  /// Activates tenant context and kicks a non-blocking catalog refresh.
  Future<void> prepareTenant({
    required String companyId,
    required String userId,
  }) async {
    await tenantContext.activate(companyId: companyId, userId: userId);
    // Fire-and-forget: inspection UI must not await network.
    catalogRefresh.refreshCompanyCatalog(companyId).ignore();
  }

  Future<void> dispose() => database.close();
}

extension<T> on Future<T> {
  void ignore() {
    then((_) {}, onError: (_) {});
  }
}
