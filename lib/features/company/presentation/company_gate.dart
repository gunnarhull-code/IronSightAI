import 'package:flutter/material.dart';

import '../../../app/inspection_session.dart';
import '../../../data/local/offline_inspection_workspace.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/exceptions/local_database_schema_exception.dart';
import '../../../domain/exceptions/remote_service_unavailable_exception.dart';
import '../../../domain/repositories/auth_session_reader.dart';
import '../../../domain/repositories/company_repository.dart';
import '../../../domain/use_cases/create_company_for_current_user.dart';
import '../../../domain/use_cases/resolve_company_access.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'company_onboarding_screen.dart';

/// Routes an authenticated user to onboarding or the dashboard based on
/// company membership.
///
/// Keeps tenancy navigation centralized (mirrors [AuthGate] for sessions).
/// After a successful online membership lookup, tenant context is cached
/// locally so cold starts without PostgREST can reopen the local workspace
/// when the restored auth user matches the cache.
class CompanyGate extends StatefulWidget {
  const CompanyGate({
    super.key,
    required this.repository,
    this.workspace,
    this.authSession,
    this.signOut,
    this.onInspectionSessionChanged,
  });

  final CompanyRepository repository;
  final OfflineInspectionWorkspace? workspace;
  final AuthSessionReader? authSession;

  /// Clears the remote auth session. Tenant cache is cleared by this gate
  /// before [signOut] runs so stale company context cannot outlive sign-out.
  final Future<void> Function()? signOut;
  final ValueChanged<InspectionSession?>? onInspectionSessionChanged;

  @override
  State<CompanyGate> createState() => _CompanyGateState();
}

class _CompanyGateState extends State<CompanyGate> {
  late final CreateCompanyForCurrentUser _createCompany;
  late Future<_CompanyGateResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _createCompany = CreateCompanyForCurrentUser(widget.repository);
    _bootstrapFuture = _bootstrap();
  }

  Future<_CompanyGateResult> _bootstrap() async {
    debugPrint('CompanyGate: company lookup starts');
    final userId = widget.authSession?.currentUserId?.trim();
    final workspace = widget.workspace;

    // Without a stable user id we cannot safely bind or restore tenant cache.
    if (userId == null || userId.isEmpty || workspace == null) {
      return _bootstrapWithoutLocalCache();
    }

    final resolve = ResolveCompanyAccess(
      widget.repository,
      workspace.tenantContext,
    );
    final resolution = await resolve(userId: userId);

    switch (resolution.kind) {
      case CompanyAccessKind.onboarding:
        // Online authority says no membership — drop any stale local context.
        await workspace.tenantContext.clear();
        widget.onInspectionSessionChanged?.call(null);
        return const _CompanyGateResult.onboarding();
      case CompanyAccessKind.online:
        debugPrint('CompanyGate: online company resolution succeeded');
        final company = resolution.company!;
        final _SessionAttempt attempt = await _tryPrepareSession(
          companyId: company.id,
          userId: userId,
        );
        if (attempt.failed) return const _CompanyGateResult.workspaceFailed();
        return _CompanyGateResult.dashboard(
          company: company,
          session: attempt.session,
        );
      case CompanyAccessKind.cached:
        debugPrint(
          'CompanyGate: restored company context from local cache for user',
        );
        final _SessionAttempt attempt = await _tryPrepareSession(
          companyId: resolution.resolvedCompanyId,
          userId: userId,
        );
        if (attempt.failed) return const _CompanyGateResult.workspaceFailed();
        return _CompanyGateResult.dashboardFromCache(session: attempt.session);
      case CompanyAccessKind.offlineUnavailable:
        debugPrint(
          'CompanyGate: company lookup failed with no usable cache: '
          '${resolution.error}',
        );
        if (resolution.stackTrace != null) {
          debugPrintStack(stackTrace: resolution.stackTrace);
        }
        widget.onInspectionSessionChanged?.call(null);
        return const _CompanyGateResult.offlineUnavailable();
      case CompanyAccessKind.lookupFailed:
        debugPrint(
          'CompanyGate: company lookup failed without cache fallback: '
          '${resolution.error}',
        );
        if (resolution.stackTrace != null) {
          debugPrintStack(stackTrace: resolution.stackTrace);
        }
        widget.onInspectionSessionChanged?.call(null);
        return const _CompanyGateResult.lookupFailed();
    }
  }

  /// Legacy / test path when workspace or auth identity is unavailable.
  Future<_CompanyGateResult> _bootstrapWithoutLocalCache() async {
    try {
      final company = await widget.repository.getCurrentUserCompany();
      if (company == null) {
        widget.onInspectionSessionChanged?.call(null);
        return const _CompanyGateResult.onboarding();
      }
      widget.onInspectionSessionChanged?.call(null);
      return _CompanyGateResult.dashboard(company: company);
    } on RemoteServiceUnavailableException catch (error, stackTrace) {
      debugPrint('CompanyGate: company lookup offline: $error');
      debugPrintStack(stackTrace: stackTrace);
      widget.onInspectionSessionChanged?.call(null);
      return const _CompanyGateResult.offlineUnavailable();
    } catch (error, stackTrace) {
      debugPrint('CompanyGate: company lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      widget.onInspectionSessionChanged?.call(null);
      return const _CompanyGateResult.lookupFailed();
    }
  }

  /// Opens the local workspace after company resolution already succeeded.
  ///
  /// A failure here is a local database problem, not a company lookup problem,
  /// and used to surface as the company error with nothing logged.
  Future<_SessionAttempt> _tryPrepareSession({
    required String companyId,
    required String userId,
  }) async {
    try {
      return _SessionAttempt.ready(
        await _prepareSession(companyId: companyId, userId: userId),
      );
    } catch (error, stackTrace) {
      // Log the type and any schema metadata only — never row values.
      debugPrint(
        'CompanyGate: local workspace open failed after company resolution '
        '(${error.runtimeType})',
      );
      if (error is LocalDatabaseSchemaException) {
        debugPrint('CompanyGate: local schema: ${error.details}');
      }
      debugPrintStack(stackTrace: stackTrace);
      widget.onInspectionSessionChanged?.call(null);
      return const _SessionAttempt.failed();
    }
  }

  Future<InspectionSession?> _prepareSession({
    required String companyId,
    required String userId,
  }) async {
    final workspace = widget.workspace;
    if (workspace == null) {
      widget.onInspectionSessionChanged?.call(null);
      return null;
    }

    await workspace.prepareTenant(companyId: companyId, userId: userId);
    final session = InspectionSession(
      companyId: companyId,
      userId: userId,
      workspace: workspace,
    );
    widget.onInspectionSessionChanged?.call(session);
    return session;
  }

  Future<void> _signOutAndClearTenant() async {
    widget.onInspectionSessionChanged?.call(null);
    final workspace = widget.workspace;
    if (workspace != null) {
      await workspace.tenantContext.clear();
    }
    final signOut = widget.signOut;
    if (signOut != null) {
      await signOut();
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
          debugPrint(
            'CompanyGate: bootstrap failed (${snapshot.error.runtimeType})',
          );
          debugPrintStack(stackTrace: snapshot.stackTrace);
        }

        final result = snapshot.data;
        if (result == null ||
            result.offlineUnavailable ||
            result.lookupFailed ||
            result.workspaceFailed) {
          final String message;
          if (result?.offlineUnavailable == true) {
            message =
                'You\'re offline and no company is cached on this '
                'device. Connect to the internet, then try again.';
          } else if (result?.workspaceFailed == true) {
            message =
                'Your company loaded, but this device\'s local inspection '
                'database could not be opened. Nothing was deleted — your '
                'saved inspections are still on this device. Retry, and '
                'contact support if this keeps happening.';
          } else {
            message = 'Could not load your company. Please try again.';
          }
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(message, textAlign: TextAlign.center),
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

        if (result.needsOnboarding) {
          return CompanyOnboardingScreen(
            createCompany: _createCompany,
            onCompleted: _onCompanyCreated,
          );
        }

        return DashboardScreen(
          inspectionSession: result.session,
          signOut: widget.signOut != null || widget.workspace != null
              ? _signOutAndClearTenant
              : null,
        );
      },
    );
  }
}

class _CompanyGateResult {
  const _CompanyGateResult._({
    required this.needsOnboarding,
    required this.offlineUnavailable,
    required this.lookupFailed,
    this.workspaceFailed = false,
    this.company,
    this.session,
  });

  const _CompanyGateResult.onboarding()
    : this._(
        needsOnboarding: true,
        offlineUnavailable: false,
        lookupFailed: false,
      );

  const _CompanyGateResult.offlineUnavailable()
    : this._(
        needsOnboarding: false,
        offlineUnavailable: true,
        lookupFailed: false,
      );

  const _CompanyGateResult.lookupFailed()
    : this._(
        needsOnboarding: false,
        offlineUnavailable: false,
        lookupFailed: true,
      );

  /// Company resolution succeeded but the local database could not be opened.
  const _CompanyGateResult.workspaceFailed()
    : this._(
        needsOnboarding: false,
        offlineUnavailable: false,
        lookupFailed: false,
        workspaceFailed: true,
      );

  const _CompanyGateResult.dashboard({
    required Company company,
    InspectionSession? session,
  }) : this._(
         needsOnboarding: false,
         offlineUnavailable: false,
         lookupFailed: false,
         company: company,
         session: session,
       );

  const _CompanyGateResult.dashboardFromCache({InspectionSession? session})
    : this._(
        needsOnboarding: false,
        offlineUnavailable: false,
        lookupFailed: false,
        session: session,
      );

  final bool needsOnboarding;
  final bool offlineUnavailable;
  final bool lookupFailed;
  final bool workspaceFailed;
  final Company? company;
  final InspectionSession? session;
}

/// Outcome of opening the local workspace for a resolved company.
class _SessionAttempt {
  const _SessionAttempt.ready(this.session) : failed = false;

  const _SessionAttempt.failed() : session = null, failed = true;

  final InspectionSession? session;
  final bool failed;
}
