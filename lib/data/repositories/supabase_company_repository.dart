import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company.dart';
import '../../domain/entities/company_membership.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/repositories/company_repository.dart';

/// Supabase-backed [CompanyRepository].
///
/// Company creation goes through the `create_company_for_current_user` RPC so
/// the company row and owner `user_profiles` row are inserted atomically under
/// a security-definer function (required for first-time onboarding under RLS).
class SupabaseCompanyRepository implements CompanyRepository {
  SupabaseCompanyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Company?> getCurrentUserCompany() async {
    final membership = await getCurrentUserCompanyMembership();
    return membership?.company;
  }

  @override
  Future<CompanyMembership?> getCurrentUserCompanyMembership() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _client
        .from('user_profiles')
        .select('company_id, role')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) return null;

    final companyId = profile['company_id'] as String?;
    if (companyId == null) {
      throw StateError('Current user profile is missing a company_id');
    }

    final company = await _client
        .from('companies')
        .select('id, name, region, created_at, updated_at')
        .eq('id', companyId)
        .single();

    return CompanyMembership(
      company: Company.fromMap(company),
      role: CompanyRole.fromDatabase(profile['role'] as String?),
    );
  }

  @override
  Future<Company> createCompanyForCurrentUser({required String name}) async {
    final response = await _client.rpc(
      'create_company_for_current_user',
      params: {'p_name': name},
    );

    final map = switch (response) {
      final Map<String, dynamic> row => row,
      final List<dynamic> rows when rows.isNotEmpty =>
        Map<String, dynamic>.from(rows.first as Map),
      _ => throw StateError('Unexpected response creating company'),
    };

    return Company.fromMap(map);
  }

  @override
  Future<Company> updateCurrentUserCompany({
    required String name,
    String? region,
  }) async {
    final membership = await getCurrentUserCompanyMembership();
    if (membership == null) {
      throw StateError('Current user does not belong to a company');
    }
    if (!membership.canEditCompanySettings) {
      throw StateError('Current user cannot edit company settings');
    }

    final company = await _client
        .from('companies')
        .update({'name': name, 'region': region})
        .eq('id', membership.company.id)
        .select('id, name, region, created_at, updated_at')
        .single();

    return Company.fromMap(company);
  }
}
