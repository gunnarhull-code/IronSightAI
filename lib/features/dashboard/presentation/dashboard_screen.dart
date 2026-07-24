import 'package:flutter/material.dart';

/// The application's landing screen for Sprint 1.
///
/// This is an initial shell only: it displays no live data and the primary
/// action button is intentionally disabled. Real inspection capture, sync,
/// and reporting are built in later sprints (docs/13-roadmap.md).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('IronSight AI')),
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
