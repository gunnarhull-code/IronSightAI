import '../entities/company.dart';
import '../entities/country_catalog.dart';
import '../repositories/company_repository.dart';

/// Creates a company and joins the current user as its owner.
///
/// New companies are persisted with [defaultCompanyCountry] in the existing
/// `region` column (UI: Country). No schema change is required.
class CreateCompanyForCurrentUser {
  const CreateCompanyForCurrentUser(this._repository);

  final CompanyRepository _repository;

  Future<Company> call({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Company name is required');
    }

    final company = await _repository.createCompanyForCurrentUser(
      name: trimmed,
    );

    // The create RPC only accepts a name today; apply the country default via
    // the existing update path so new companies land as United States.
    return _repository.updateCurrentUserCompany(
      name: company.name,
      region: defaultCompanyCountry,
    );
  }
}
