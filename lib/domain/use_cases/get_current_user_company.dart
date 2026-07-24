import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Loads the authenticated user's company membership, if any.
class GetCurrentUserCompany {
  const GetCurrentUserCompany(this._repository);

  final CompanyRepository _repository;

  Future<Company?> call() => _repository.getCurrentUserCompany();
}
