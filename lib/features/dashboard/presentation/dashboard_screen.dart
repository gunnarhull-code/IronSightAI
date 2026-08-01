import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/inspection_session.dart';
import '../../../app/router.dart';

/// The application's landing screen for authenticated company members.
///
/// Inspection navigation is enabled when an [InspectionSession] is supplied by
/// the composition root. Reports remain a later-sprint placeholder.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.signOut, this.inspectionSession});

  /// Optional override for tests. Production uses Supabase Auth directly.
  final Future<void> Function()? signOut;

  /// When non-null, inspection actions navigate using local repositories.
  final InspectionSession? inspectionSession;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSigningOut = false;

  bool get _inspectionsEnabled {
    final session = widget.inspectionSession;
    return session != null &&
        session.companyId.isNotEmpty &&
        session.userId.isNotEmpty;
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      if (widget.signOut != null) {
        await widget.signOut!();
      } else {
        await Supabase.instance.client.auth.signOut();
      }
      // AuthGate owns the resulting navigation via onAuthStateChange.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IronSight AI'),
        actions: [
          IconButton(
            tooltip: 'Company Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.companySettings),
            icon: const Icon(Icons.business),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Heavy Equipment Inspections',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fast inspections. Clear reports. Better equipment '
                    'decisions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _inspectionsEnabled
                        ? () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.inspectionNew)
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Start Quick Appraisal'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _inspectionsEnabled
                        ? 'Starts from equipment cached on this device'
                        : 'Local inspection workspace unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _EquipmentSectionCard(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.equipmentList),
                  ),
                  _NavigationSectionCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Inspections',
                    subtitle: _inspectionsEnabled
                        ? 'Local drafts and completed inspections'
                        : 'Not yet available',
                    onTap: _inspectionsEnabled
                        ? () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.inspections)
                        : null,
                  ),
                  _NavigationSectionCard(
                    icon: Icons.edit_note_outlined,
                    title: 'Draft Inspections',
                    subtitle: _inspectionsEnabled
                        ? 'Open the inspection list to resume drafts'
                        : 'Not yet available',
                    onTap: _inspectionsEnabled
                        ? () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.inspections)
                        : null,
                  ),
                  const _NavigationSectionCard(
                    icon: Icons.description_outlined,
                    title: 'Reports',
                    subtitle: 'Not yet available',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard entry point into the Equipment module — the first fully
/// functional (non-placeholder) section on this screen.
class _EquipmentSectionCard extends StatelessWidget {
  const _EquipmentSectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.precision_manufacturing_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text('Equipment', style: theme.textTheme.titleMedium),
        subtitle: const Text('View and manage company equipment'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _NavigationSectionCard extends StatelessWidget {
  const _NavigationSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
