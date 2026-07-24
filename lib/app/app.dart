import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/supabase_company_repository.dart';
import '../data/repositories/supabase_equipment_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/company/presentation/company_gate.dart';
import 'router.dart';

/// Root widget of the IronSight AI application.
class IronSightApp extends StatelessWidget {
  const IronSightApp({super.key, this.authGate});

  /// Optional override for [AuthGate], primarily used by widget tests that
  /// do not initialize Supabase.
  final Widget? authGate;

  @override
  Widget build(BuildContext context) {
    final companyRepository = authGate == null
        ? SupabaseCompanyRepository(Supabase.instance.client)
        : null;
    final equipmentRepository = authGate == null
        ? SupabaseEquipmentRepository(Supabase.instance.client)
        : null;

    return MaterialApp(
      title: 'IronSight AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authGate ?? _buildDefaultAuthGate(companyRepository!),
      routes: appRoutes,
      onGenerateRoute:
          (companyRepository == null || equipmentRepository == null)
          ? null
          : (settings) => buildAppRoute(
              settings,
              companyRepository: companyRepository,
              equipmentRepository: equipmentRepository,
            ),
    );
  }

  /// Composition root: wires data-layer repositories into feature gates.
  ///
  /// Keeping Supabase construction here (and in `data/`) preserves the
  /// presentation/domain import boundary from docs/06-mobile-app-spec.md.
  Widget _buildDefaultAuthGate(SupabaseCompanyRepository companyRepository) {
    return AuthGate(signedInHome: CompanyGate(repository: companyRepository));
  }
}
