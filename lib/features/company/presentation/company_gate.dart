import 'package:flutter/material.dart';

import '../../../domain/entities/company.dart';
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
  const CompanyGate({super.key, required this.repository});

  final CompanyRepository repository;

  @override
  State<CompanyGate> createState() => _CompanyGateState();
}

class _CompanyGateState extends State<CompanyGate> {
  late final GetCurrentUserCompany _getCurrentUserCompany;
  late final CreateCompanyForCurrentUser _createCompany;
  late Future<Company?> _companyFuture;

  @override
  void initState() {
    super.initState();
    _getCurrentUserCompany = GetCurrentUserCompany(widget.repository);
    _createCompany = CreateCompanyForCurrentUser(widget.repository);
    _companyFuture = _loadCompany();
  }

  Future<Company?> _loadCompany() async {
    debugPrint('CompanyGate: company lookup starts');
    try {
      return await _getCurrentUserCompany();
    } catch (error, stackTrace) {
      debugPrint('CompanyGate: company lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _onCompanyCreated() {
    // Reload so the gate advances from the repository source of truth.
    setState(() {
      _companyFuture = _loadCompany();
    });
  }

  void _retryCompanyLookup() {
    debugPrint('CompanyGate: Retry pressed');
    setState(() {
      _companyFuture = _loadCompany();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Company?>(
      future: _companyFuture,
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

        final company = snapshot.data;
        if (company == null) {
          return CompanyOnboardingScreen(
            createCompany: _createCompany,
            onCompleted: _onCompanyCreated,
          );
        }

        return const DashboardScreen();
      },
    );
  }
}
