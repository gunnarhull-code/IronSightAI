import '../entities/company.dart';
import '../entities/company_membership.dart';

/// Persistence boundary for company tenancy.
///
/// V1 supports one company per user (owner created at onboarding). The
/// interface is intentionally narrow now and ready to grow for:
/// - multiple users per company (invites / roster)
/// - manager and inspector roles
/// - company region settings
/// - equipment and inspection repositories scoped by [Company.id]
abstract class CompanyRepository {
  /// Returns the company for the currently authenticated user, or `null`
  /// when they have not completed onboarding yet.
  Future<Company?> getCurrentUserCompany();

  /// Returns the current user's company plus role, or `null` if they have not
  /// completed onboarding.
  Future<CompanyMembership?> getCurrentUserCompanyMembership();

  /// Creates a company and associates the current user as its owner.
  ///
  /// Returns the newly created [Company]. Callers should treat this as the
  /// completion of first-time company onboarding.
  Future<Company> createCompanyForCurrentUser({required String name});

  /// Updates the current user's company details.
  ///
  /// Implementations must derive company identity from the authenticated
  /// user's membership, never from a UI-provided company id.
  Future<Company> updateCurrentUserCompany({
    required String name,
    String? region,
  });
}
