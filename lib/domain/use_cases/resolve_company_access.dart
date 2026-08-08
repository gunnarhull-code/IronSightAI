import '../entities/company.dart';
import '../entities/local_tenant_context.dart';
import '../exceptions/remote_service_unavailable_exception.dart';
import '../repositories/company_repository.dart';
import '../repositories/local_tenant_context_repository.dart';

/// Resolves company membership for the signed-in user.
///
/// Online success returns the remote company. Only
/// [RemoteServiceUnavailableException] (connectivity / unreachable remote)
/// may fall back to the locally cached [LocalTenantContext], and only when
/// that cache belongs to [userId].
///
/// Authorization, authentication, RLS, malformed-response, server, and
/// unexpected programming failures never unlock the cached workspace.
/// Cached context never authorizes server access.
class ResolveCompanyAccess {
  const ResolveCompanyAccess(
    this._companyRepository,
    this._tenantContextRepository,
  );

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
    } on RemoteServiceUnavailableException catch (error, stackTrace) {
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
    } catch (error, stackTrace) {
      return CompanyAccessResolution.lookupFailed(
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

  const CompanyAccessResolution.lookupFailed({
    required Object error,
    StackTrace? stackTrace,
  }) : this._(
         kind: CompanyAccessKind.lookupFailed,
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
      case CompanyAccessKind.lookupFailed:
        throw StateError('No resolved company for $kind');
    }
  }
}

enum CompanyAccessKind {
  onboarding,
  online,
  cached,
  offlineUnavailable,
  lookupFailed,
}
