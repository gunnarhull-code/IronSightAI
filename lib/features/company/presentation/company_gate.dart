import 'package:flutter/material.dart';

import '../../../app/inspection_session.dart';
import '../../../data/local/offline_inspection_workspace.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/repositories/auth_session_reader.dart';
import '../../../domain/repositories/company_repository.dart';
import '../../../domain/use_cases/create_company_for_current_user.dart';
import '../../../domain/use_cases/get_current_user_company.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'company_onboarding_screen.dart';

/// Routes an authenticated user to onboarding or the dashboard based on
/// company membership.
///
/// Keeps tenancy navigation centralized (mirrors [AuthGate] for sessions).
class CompanyGate extends StatefulWidget {
  const CompanyGate({
    super.key,
    required this.repository,
    this.workspace,
    this.authSession,
    this.onInspectionSessionChanged,
  });

  final CompanyRepository repository;
  final OfflineInspectionWorkspace? workspace;
  final AuthSessionReader? authSession;
  final ValueChanged<InspectionSession?>? onInspectionSessionChanged;

  @override
  State<CompanyGate> createState() => _CompanyGateState();
}

class _CompanyGateState extends State<CompanyGate> {
  late final GetCurrentUserCompany _getCurrentUserCompany;
  late final CreateCompanyForCurrentUser _createCompany;
  late Future<_CompanyGateResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _getCurrentUserCompany = GetCurrentUserCompany(widget.repository);
    _createCompany = CreateCompanyForCurrentUser(widget.repository);
    _bootstrapFuture = _bootstrap();
  }

  Future<_CompanyGateResult> _bootstrap() async {
    debugPrint('CompanyGate: company lookup starts');
    try {
      final company = await _getCurrentUserCompany();
      if (company == null) {
        widget.onInspectionSessionChanged?.call(null);
        return const _CompanyGateResult.onboarding();
      }

      final workspace = widget.workspace;
      final userId = widget.authSession?.currentUserId;
      InspectionSession? session;
      if (workspace != null && userId != null && userId.isNotEmpty) {
        await workspace.prepareTenant(companyId: company.id, userId: userId);
        session = InspectionSession(
          companyId: company.id,
          userId: userId,
          workspace: workspace,
        );
        widget.onInspectionSessionChanged?.call(session);
      } else {
        widget.onInspectionSessionChanged?.call(null);
      }
      return _CompanyGateResult.dashboard(company: company, session: session);
    } catch (error, stackTrace) {
      debugPrint('CompanyGate: company lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _onCompanyCreated() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  void _retryCompanyLookup() {
    debugPrint('CompanyGate: Retry pressed');
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CompanyGateResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Could not load your company. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retryCompanyLookup,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final result = snapshot.data!;
        if (result.needsOnboarding) {
          return CompanyOnboardingScreen(
            createCompany: _createCompany,
            onCompleted: _onCompanyCreated,
          );
        }

        return DashboardScreen(inspectionSession: result.session);
      },
    );
  }
}

class _CompanyGateResult {
  const _CompanyGateResult._({
    required this.needsOnboarding,
    this.company,
    this.session,
  });

  const _CompanyGateResult.onboarding() : this._(needsOnboarding: true);

  const _CompanyGateResult.dashboard({
    required Company company,
    InspectionSession? session,
  }) : this._(needsOnboarding: false, company: company, session: session);

  final bool needsOnboarding;
  final Company? company;
  final InspectionSession? session;
}
