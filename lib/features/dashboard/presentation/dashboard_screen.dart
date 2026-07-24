import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';

/// The application's landing screen for Sprint 1.
///
/// This is an initial shell only: it displays no live data and the primary
/// action button is intentionally disabled. Real inspection capture, sync,
/// and reporting are built in later sprints (docs/13-roadmap.md).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.signOut});

  /// Optional override for tests. Production uses Supabase Auth directly.
  final Future<void> Function()? signOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSigningOut = false;

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
                  const FilledButton(
                    // Intentionally disabled: inspection capture is not
                    // implemented yet (docs/13-roadmap.md, Weeks 3-5).
                    onPressed: null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Start Quick Appraisal'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coming soon',
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
                  const _PlaceholderSectionCard(
                    icon: Icons.history,
                    title: 'Recent Inspections',
                  ),
                  const _PlaceholderSectionCard(
                    icon: Icons.edit_note_outlined,
                    title: 'Draft Inspections',
                  ),
                  const _PlaceholderSectionCard(
                    icon: Icons.description_outlined,
                    title: 'Reports',
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

/// A placeholder card for a dashboard section whose real content and
/// navigation are not implemented yet.
class _PlaceholderSectionCard extends StatelessWidget {
  const _PlaceholderSectionCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: const Text('Not yet available'),
      ),
    );
  }
}
