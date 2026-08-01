/// Active company + user identity persisted for offline inspection work.
class LocalTenantContext {
  const LocalTenantContext({
    required this.companyId,
    required this.userId,
    required this.activatedAt,
  });

  final String companyId;
  final String userId;
  final DateTime activatedAt;
}
