import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Creates a company and joins the current user as its owner.
class CreateCompanyForCurrentUser {
  const CreateCompanyForCurrentUser(this._repository);

  final CompanyRepository _repository;

  Future<Company> call({required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Company name is required');
    }
    return _repository.createCompanyForCurrentUser(name: trimmed);
  }
}
