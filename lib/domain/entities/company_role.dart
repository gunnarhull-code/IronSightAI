/// User role within a company.
///
/// The database currently supports the V1 roles. `inspector` is included in
/// the domain model as a read-only forward-compatible role name.
enum CompanyRole {
  owner,
  admin,
  manager,
  inspector,
  rep,
  unknown;

  static CompanyRole fromDatabase(String? value) {
    return switch (value) {
      'owner' => CompanyRole.owner,
      'admin' => CompanyRole.admin,
      'manager' => CompanyRole.manager,
      'inspector' => CompanyRole.inspector,
      'rep' => CompanyRole.rep,
      _ => CompanyRole.unknown,
    };
  }

  String get label {
    return switch (this) {
      CompanyRole.owner => 'Owner',
      CompanyRole.admin => 'Admin',
      CompanyRole.manager => 'Manager',
      CompanyRole.inspector => 'Inspector',
      CompanyRole.rep => 'Rep',
      CompanyRole.unknown => 'Unknown',
    };
  }

  /// For this sprint, only owners can edit company settings.
  bool get canEditCompanySettings => this == CompanyRole.owner;
}
