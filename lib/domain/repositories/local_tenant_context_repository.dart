import '../entities/local_tenant_context.dart';

/// Persists the active company/user pair used for offline inspection reads.
///
/// Implementations must clear cross-tenant cached equipment when the active
/// company or user changes.
abstract class LocalTenantContextRepository {
  Future<LocalTenantContext?> getActive();

  /// Activates [companyId]/[userId], clearing equipment cache for any other
  /// company and refusing empty identifiers.
  Future<LocalTenantContext> activate({
    required String companyId,
    required String userId,
  });

  Future<void> clear();
}
