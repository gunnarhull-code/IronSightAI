import '../entities/company.dart';
import '../entities/local_tenant_context.dart';
import '../repositories/company_repository.dart';
import '../repositories/local_tenant_context_repository.dart';

/// Resolves company membership for the signed-in user.
///
/// Online success returns the remote company. Online failure falls back to the
/// locally cached [LocalTenantContext] only when it belongs to [userId].
/// Cached context never authorizes server access — it only unlocks the local
/// workspace after auth session restore.
class ResolveCompanyAccess {
  const ResolveCompanyAccess({
    required CompanyRepository companyRepository,
    required LocalTenantContextRepository tenantContextRepository,
  }) : _companyRepository = companyRepository,
       _tenantContextRepository = tenantContextRepository;

  final CompanyRepository _companyRepository;
  final LocalTenantContextRepository _tenantContextRepository;

  Future<CompanyAccessResolution> call({required String userId}) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }

    try {
      final company = await _companyRepository.getCurrentUserCompany();
      if (company == null) {
        return const CompanyAccessResolution.onboarding();
      }
      return CompanyAccessResolution.online(company: company);
    } catch (error, stackTrace) {
      final cached = await _tenantContextRepository.getActive();
      if (_isUsableCache(cached, trimmedUserId)) {
        return CompanyAccessResolution.cached(
          companyId: cached!.companyId,
          userId: cached.userId,
        );
      }
      return CompanyAccessResolution.offlineUnavailable(
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isUsableCache(LocalTenantContext? cached, String userId) {
    if (cached == null) return false;
    if (cached.userId != userId) return false;
    if (cached.companyId.trim().isEmpty) return false;
    return true;
  }
}

/// Outcome of [ResolveCompanyAccess].
class CompanyAccessResolution {
  const CompanyAccessResolution._({
    required this.kind,
    this.company,
    this.companyId,
    this.userId,
    this.error,
    this.stackTrace,
  });

  const CompanyAccessResolution.onboarding()
    : this._(kind: CompanyAccessKind.onboarding);

  const CompanyAccessResolution.online({required Company company})
    : this._(kind: CompanyAccessKind.online, company: company);

  const CompanyAccessResolution.cached({
    required String companyId,
    required String userId,
  }) : this._(
         kind: CompanyAccessKind.cached,
         companyId: companyId,
         userId: userId,
       );

  const CompanyAccessResolution.offlineUnavailable({
    required Object error,
    StackTrace? stackTrace,
  }) : this._(
         kind: CompanyAccessKind.offlineUnavailable,
         error: error,
         stackTrace: stackTrace,
       );

  final CompanyAccessKind kind;
  final Company? company;
  final String? companyId;
  final String? userId;
  final Object? error;
  final StackTrace? stackTrace;

  String get resolvedCompanyId {
    switch (kind) {
      case CompanyAccessKind.online:
        return company!.id;
      case CompanyAccessKind.cached:
        return companyId!;
      case CompanyAccessKind.onboarding:
      case CompanyAccessKind.offlineUnavailable:
        throw StateError('No resolved company for $kind');
    }
  }
}

enum CompanyAccessKind { onboarding, online, cached, offlineUnavailable }
