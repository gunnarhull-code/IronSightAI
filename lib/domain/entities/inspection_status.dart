/// Local completion status set on-device without requiring connectivity.
///
/// Matches the product split where completion is independent of sync/report.
enum InspectionCompletionStatus {
  inProgress,
  completed;

  String get storageValue => switch (this) {
        InspectionCompletionStatus.inProgress => 'in_progress',
        InspectionCompletionStatus.completed => 'completed',
      };

  static InspectionCompletionStatus fromStorage(String value) {
    return switch (value) {
      'in_progress' => InspectionCompletionStatus.inProgress,
      'completed' => InspectionCompletionStatus.completed,
      _ => throw FormatException('Invalid completion status: $value'),
    };
  }
}

/// Local lifecycle distinct from completion — supports safe discard of drafts.
enum InspectionLocalLifecycle {
  active,
  discarded;

  String get storageValue => name;

  static InspectionLocalLifecycle fromStorage(String value) {
    return switch (value) {
      'active' => InspectionLocalLifecycle.active,
      'discarded' => InspectionLocalLifecycle.discarded,
      _ => throw FormatException('Invalid local lifecycle: $value'),
    };
  }
}

/// Optional synchronization bookkeeping. Never blocks offline capture.
enum InspectionSyncStatus {
  localOnly,
  pending,
  syncing,
  synced,
  error;

  String get storageValue => switch (this) {
        InspectionSyncStatus.localOnly => 'local_only',
        InspectionSyncStatus.pending => 'pending',
        InspectionSyncStatus.syncing => 'syncing',
        InspectionSyncStatus.synced => 'synced',
        InspectionSyncStatus.error => 'error',
      };

  static InspectionSyncStatus fromStorage(String value) {
    return switch (value) {
      'local_only' => InspectionSyncStatus.localOnly,
      'pending' => InspectionSyncStatus.pending,
      'syncing' => InspectionSyncStatus.syncing,
      'synced' => InspectionSyncStatus.synced,
      'error' => InspectionSyncStatus.error,
      _ => throw FormatException('Invalid sync status: $value'),
    };
  }
}

/// Report generation status. Stored locally for future sync; unused this sprint.
enum InspectionReportStatus {
  notGenerated,
  generating,
  generated;

  String get storageValue => switch (this) {
        InspectionReportStatus.notGenerated => 'not_generated',
        InspectionReportStatus.generating => 'generating',
        InspectionReportStatus.generated => 'generated',
      };

  static InspectionReportStatus fromStorage(String value) {
    return switch (value) {
      'not_generated' => InspectionReportStatus.notGenerated,
      'generating' => InspectionReportStatus.generating,
      'generated' => InspectionReportStatus.generated,
      _ => throw FormatException('Invalid report status: $value'),
    };
  }
}
