import 'company.dart';
import 'company_role.dart';

/// The current authenticated user's company relationship.
///
/// Keeps company identity separate from the user's role so future multiple
/// employees, managers, and inspection collaboration can grow without changing
/// the company entity itself.
class CompanyMembership {
  const CompanyMembership({required this.company, required this.role});

  final Company company;
  final CompanyRole role;

  bool get canEditCompanySettings => role.canEditCompanySettings;
}
