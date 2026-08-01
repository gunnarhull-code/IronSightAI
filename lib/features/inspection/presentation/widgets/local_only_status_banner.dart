import 'package:flutter/material.dart';

import '../../../../domain/entities/inspection_status.dart';

/// Honest local-only status chip — never implies remote sync occurred.
class LocalOnlyStatusBanner extends StatelessWidget {
  const LocalOnlyStatusBanner({super.key, this.syncStatus});

  final InspectionSyncStatus? syncStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (syncStatus) {
      InspectionSyncStatus.localOnly ||
      null => 'Saved on this device only — not synced',
      InspectionSyncStatus.pending =>
        'Saved on this device only — sync not started',
      InspectionSyncStatus.syncing =>
        'Saved on this device only — sync not available in this sprint',
      InspectionSyncStatus.synced =>
        'Saved on this device only — remote sync is out of scope',
      InspectionSyncStatus.error =>
        'Saved on this device only — sync error state is local metadata only',
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.phone_android,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
