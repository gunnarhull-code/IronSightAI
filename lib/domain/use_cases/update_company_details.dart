import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Updates editable company settings for the current user's company.
class UpdateCompanyDetails {
  const UpdateCompanyDetails(this._repository);

  final CompanyRepository _repository;

  Future<Company> call({required String name, String? region}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Company name is required');
    }

    final trimmedRegion = region?.trim();
    return _repository.updateCurrentUserCompany(
      name: trimmedName,
      region: trimmedRegion == null || trimmedRegion.isEmpty
          ? null
          : trimmedRegion,
    );
  }
}
