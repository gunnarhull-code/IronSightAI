import '../entities/company_membership.dart';
import '../repositories/company_repository.dart';

/// Loads the authenticated user's company membership and role, if any.
class GetCurrentUserCompanyMembership {
  const GetCurrentUserCompanyMembership(this._repository);

  final CompanyRepository _repository;

  Future<CompanyMembership?> call() {
    return _repository.getCurrentUserCompanyMembership();
  }
}
