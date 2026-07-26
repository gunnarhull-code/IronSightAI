import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/entities/company_membership.dart';
import 'package:ironsight_ai/domain/entities/company_role.dart';
import 'package:ironsight_ai/domain/repositories/company_repository.dart';

/// In-memory [CompanyRepository] for widget and unit tests.
class FakeCompanyRepository implements CompanyRepository {
  FakeCompanyRepository({
    this.company,
    this.role = CompanyRole.owner,
    this.getError,
    this.createDelay = Duration.zero,
    this.updateDelay = Duration.zero,
  });

  Company? company;
  CompanyRole role;
  Object? getError;
  Duration createDelay;
  Duration updateDelay;
  int createCallCount = 0;
  int updateCallCount = 0;
  String? lastCreatedName;
  String? lastUpdatedName;
  String? lastUpdatedRegion;
  Object? createError;
  Object? updateError;

  @override
  Future<Company?> getCurrentUserCompany() async {
    if (getError != null) {
      throw getError!;
    }
    return company;
  }

  @override
  Future<CompanyMembership?> getCurrentUserCompanyMembership() async {
    if (getError != null) {
      throw getError!;
    }
    final currentCompany = company;
    if (currentCompany == null) return null;
    return CompanyMembership(company: currentCompany, role: role);
  }

  @override
  Future<Company> createCompanyForCurrentUser({required String name}) async {
    createCallCount += 1;
    lastCreatedName = name;
    if (createDelay > Duration.zero) {
      await Future<void>.delayed(createDelay);
    }
    if (createError != null) {
      throw createError!;
    }
    company = Company(
      id: 'company-1',
      name: name,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    return company!;
  }

  @override
  Future<Company> updateCurrentUserCompany({
    required String name,
    String? region,
  }) async {
    updateCallCount += 1;
    lastUpdatedName = name;
    lastUpdatedRegion = region;
    if (updateDelay > Duration.zero) {
      await Future<void>.delayed(updateDelay);
    }
    if (updateError != null) {
      throw updateError!;
    }
    if (company == null) {
      throw StateError('No company');
    }
    if (!role.canEditCompanySettings) {
      throw StateError('Read-only role');
    }
    company = company!.copyWith(name: name, region: region);
    return company!;
  }
}
