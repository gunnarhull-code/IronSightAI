import 'package:flutter/material.dart';

import '../domain/repositories/company_repository.dart';
import '../domain/repositories/equipment_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/company/presentation/company_settings_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/equipment/presentation/equipment_form_screen.dart';
import '../features/equipment/presentation/equipment_list_screen.dart';
import '../features/inspection/presentation/inspection_equipment_select_screen.dart';
import '../features/inspection/presentation/inspection_list_screen.dart';
import '../features/inspection/presentation/inspection_review_screen.dart';
import '../features/inspection/presentation/inspection_workspace_screen.dart';
import 'inspection_session.dart';

/// Named route identifiers for the app.
///
/// Uses Flutter's built-in named-routes API (no third-party routing
/// package), per the approved V1 tech stack. Add a new constant here and a
/// matching entry in [appRoutes] (or [buildAppRoute] for routes that need a
/// repository) as each new screen is implemented.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String companySettings = '/company-settings';
  static const String dashboard = '/dashboard';
  static const String equipmentList = '/equipment';
  static const String equipmentNew = '/equipment/new';
  static const String inspections = '/inspections';
  static const String inspectionNew = '/inspections/new';

  static const String _equipmentEditPrefix = '/equipment/edit/';
  static const String _inspectionWorkspacePrefix = '/inspections/workspace/';
  static const String _inspectionReviewPrefix = '/inspections/review/';

  /// Builds the route name for editing a specific equipment record.
  ///
  /// Flutter's built-in `Navigator.routes` map only supports static route
  /// names, so this dynamic segment is parsed in [buildAppRoute] instead —
  /// the equivalent of a `/equipment/:id` route without pulling in a routing
  /// package.
  static String equipmentEdit(String id) => '$_equipmentEditPrefix$id';

  static String inspectionWorkspace(String id) =>
      '$_inspectionWorkspacePrefix$id';

  static String inspectionReview(String id) => '$_inspectionReviewPrefix$id';

  static String? _equipmentIdFromRoute(String name) {
    if (!name.startsWith(_equipmentEditPrefix)) return null;
    final id = name.substring(_equipmentEditPrefix.length);
    return id.isEmpty ? null : id;
  }

  static String? _inspectionIdFromPrefix(String name, String prefix) {
    if (!name.startsWith(prefix)) return null;
    final id = name.substring(prefix.length);
    return id.isEmpty ? null : id;
  }
}

/// Route table consumed by [MaterialApp.routes].
///
/// Session-aware startup is owned by [AuthGate]; company membership routing
/// (onboarding vs dashboard) is owned by [CompanyGate]. Named routes remain
/// available for login ↔ signup navigation and for any direct navigation that
/// still needs a stable path.
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.signup: (context) => const SignupScreen(),
  AppRoutes.dashboard: (context) => const DashboardScreen(),
};

/// Builds routes that need a repository instance from the composition root
/// (`app/app.dart`), which [appRoutes] cannot express since it is a static,
/// top-level map with no access to per-app dependencies.
Route<dynamic>? buildAppRoute(
  RouteSettings settings, {
  required CompanyRepository companyRepository,
  required EquipmentRepository equipmentRepository,
  InspectionSession? inspectionSession,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final name = settings.name;
  if (name == null) return null;

  if (name == AppRoutes.companySettings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) =>
          CompanySettingsScreen(repository: companyRepository),
    );
  }

  if (name == AppRoutes.equipmentList) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) =>
          EquipmentListScreen(repository: equipmentRepository),
    );
  }

  // These use MaterialPageRoute<bool?> (not <void>) because
  // EquipmentListScreen pushes them with pushNamed<bool?> and reads the
  // popped result to decide whether to refresh the list.
  if (name == AppRoutes.equipmentNew) {
    return MaterialPageRoute<bool?>(
      settings: settings,
      builder: (context) => EquipmentFormScreen(
        repository: equipmentRepository,
        companyRepository: companyRepository,
      ),
    );
  }

  final editId = AppRoutes._equipmentIdFromRoute(name);
  if (editId != null) {
    return MaterialPageRoute<bool?>(
      settings: settings,
      builder: (context) => EquipmentFormScreen(
        repository: equipmentRepository,
        companyRepository: companyRepository,
        equipmentId: editId,
      ),
    );
  }

  final session = inspectionSession;
  if (session != null) {
    if (name == AppRoutes.inspections) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => InspectionListScreen(
          companyId: session.companyId,
          userId: session.userId,
          inspections: session.workspace.inspections,
          equipmentCatalog: session.workspace.equipmentCatalog,
        ),
      );
    }

    if (name == AppRoutes.inspectionNew) {
      return MaterialPageRoute<bool?>(
        settings: settings,
        builder: (context) => InspectionEquipmentSelectScreen(
          companyId: session.companyId,
          userId: session.userId,
          inspections: session.workspace.inspections,
          equipmentCatalog: session.workspace.equipmentCatalog,
          refreshCatalog:
              session.workspace.catalogRefresh.refreshCompanyCatalog,
        ),
      );
    }

    final workspaceId = AppRoutes._inspectionIdFromPrefix(
      name,
      AppRoutes._inspectionWorkspacePrefix,
    );
    if (workspaceId != null) {
      return MaterialPageRoute<bool?>(
        settings: settings,
        builder: (context) => InspectionWorkspaceScreen(
          companyId: session.companyId,
          userId: session.userId,
          inspectionId: workspaceId,
          inspections: session.workspace.inspections,
          equipmentCatalog: session.workspace.equipmentCatalog,
          inspectionMedia: session.workspace.inspectionMedia,
          navigatorKey: navigatorKey,
        ),
      );
    }

    final reviewId = AppRoutes._inspectionIdFromPrefix(
      name,
      AppRoutes._inspectionReviewPrefix,
    );
    if (reviewId != null) {
      return MaterialPageRoute<bool?>(
        settings: settings,
        builder: (context) => InspectionReviewScreen(
          companyId: session.companyId,
          userId: session.userId,
          inspectionId: reviewId,
          inspections: session.workspace.inspections,
          equipmentCatalog: session.workspace.equipmentCatalog,
        ),
      );
    }
  }

  return null;
}
