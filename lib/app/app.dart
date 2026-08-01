import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../data/local/offline_inspection_workspace.dart';
import '../data/repositories/supabase_auth_session_reader.dart';
import '../data/repositories/supabase_company_repository.dart';
import '../data/repositories/supabase_equipment_repository.dart';
import '../domain/repositories/auth_session_reader.dart';
import '../domain/repositories/company_repository.dart';
import '../domain/repositories/equipment_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/company/presentation/company_gate.dart';
import 'inspection_session.dart';
import 'router.dart';

/// Root widget of the IronSight AI application.
class IronSightApp extends StatefulWidget {
  const IronSightApp({
    super.key,
    this.authGate,
    this.workspaceOverride,
    this.companyRepositoryOverride,
    this.equipmentRepositoryOverride,
    this.authSessionOverride,
  });

  /// Optional override for [AuthGate], primarily used by widget tests that
  /// do not initialize Supabase.
  final Widget? authGate;

  /// Optional offline workspace for tests / pre-opened composition.
  final OfflineInspectionWorkspace? workspaceOverride;

  final CompanyRepository? companyRepositoryOverride;
  final EquipmentRepository? equipmentRepositoryOverride;
  final AuthSessionReader? authSessionOverride;

  @override
  State<IronSightApp> createState() => _IronSightAppState();
}

class _IronSightAppState extends State<IronSightApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  OfflineInspectionWorkspace? _workspace;
  Object? _workspaceError;
  bool _openingWorkspace = false;
  InspectionSession? _inspectionSession;

  CompanyRepository? _companyRepository;
  EquipmentRepository? _equipmentRepository;
  AuthSessionReader? _authSession;

  @override
  void initState() {
    super.initState();
    if (widget.authGate == null) {
      final client = Supabase.instance.client;
      _companyRepository =
          widget.companyRepositoryOverride ?? SupabaseCompanyRepository(client);
      _equipmentRepository =
          widget.equipmentRepositoryOverride ??
          SupabaseEquipmentRepository(client);
      _authSession =
          widget.authSessionOverride ?? SupabaseAuthSessionReader(client);
      if (widget.workspaceOverride != null) {
        _workspace = widget.workspaceOverride;
      } else {
        _openWorkspace();
      }
    } else {
      _companyRepository = widget.companyRepositoryOverride;
      _equipmentRepository = widget.equipmentRepositoryOverride;
      _authSession = widget.authSessionOverride;
      _workspace = widget.workspaceOverride;
    }
  }

  Future<void> _openWorkspace() async {
    setState(() {
      _openingWorkspace = true;
      _workspaceError = null;
    });
    try {
      final workspace = await OfflineInspectionWorkspace.open(
        remoteEquipmentRepository: _equipmentRepository!,
        authSession: _authSession!,
        // Web founder QA cannot use SQLCipher; mobile/desktop keep requireCipher.
        requireCipher: !kIsWeb,
      );
      if (!mounted) {
        await workspace.dispose();
        return;
      }
      setState(() {
        _workspace = workspace;
        _openingWorkspace = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _workspaceError = error;
        _openingWorkspace = false;
      });
    }
  }

  void _onInspectionSessionChanged(InspectionSession? session) {
    setState(() => _inspectionSession = session);
  }

  @override
  void dispose() {
    final workspace = _workspace;
    if (workspace != null && widget.workspaceOverride == null) {
      workspace.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronSight AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      home: widget.authGate ?? _buildHome(),
      routes: appRoutes,
      onGenerateRoute:
          _companyRepository == null || _equipmentRepository == null
          ? null
          : (settings) => buildAppRoute(
              settings,
              companyRepository: _companyRepository!,
              equipmentRepository: _equipmentRepository!,
              inspectionSession: _inspectionSession,
              navigatorKey: _navigatorKey,
            ),
    );
  }

  Widget _buildHome() {
    if (_openingWorkspace && _workspace == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_workspaceError != null && _workspace == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Could not open the local inspection workspace.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _openWorkspace,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AuthGate(
      signedInHome: CompanyGate(
        repository: _companyRepository!,
        workspace: _workspace,
        authSession: _authSession,
        onInspectionSessionChanged: _onInspectionSessionChanged,
      ),
    );
  }
}
