/// Ordered steps for the guided Quick Appraisal intake.
enum GuidedQuickAppraisalStep {
  machineSource,
  equipmentIdentity,
  requiredPhotos,
  serialAndHours,
  quickCondition,
  notes,
  reviewAndComplete;

  static const List<GuidedQuickAppraisalStep> order = GuidedQuickAppraisalStep.values;

  int get stepNumber => index + 1;

  int get totalSteps => order.length;

  String get storageValue => switch (this) {
    GuidedQuickAppraisalStep.machineSource => 'machine_source',
    GuidedQuickAppraisalStep.equipmentIdentity => 'equipment_identity',
    GuidedQuickAppraisalStep.requiredPhotos => 'required_photos',
    GuidedQuickAppraisalStep.serialAndHours => 'serial_and_hours',
    GuidedQuickAppraisalStep.quickCondition => 'quick_condition',
    GuidedQuickAppraisalStep.notes => 'notes',
    GuidedQuickAppraisalStep.reviewAndComplete => 'review_and_complete',
  };

  String get title => switch (this) {
    GuidedQuickAppraisalStep.machineSource => 'Machine source',
    GuidedQuickAppraisalStep.equipmentIdentity => 'Equipment identity',
    GuidedQuickAppraisalStep.requiredPhotos => 'Required photos',
    GuidedQuickAppraisalStep.serialAndHours => 'Serial number and hours',
    GuidedQuickAppraisalStep.quickCondition => 'Quick condition',
    GuidedQuickAppraisalStep.notes => 'Notes',
    GuidedQuickAppraisalStep.reviewAndComplete => 'Review & Complete',
  };

  GuidedQuickAppraisalStep? get previous {
    if (index == 0) return null;
    return order[index - 1];
  }

  GuidedQuickAppraisalStep? get next {
    if (index >= order.length - 1) return null;
    return order[index + 1];
  }

  static GuidedQuickAppraisalStep fromStorage(String value) {
    return switch (value) {
      'machine_source' => GuidedQuickAppraisalStep.machineSource,
      'equipment_identity' => GuidedQuickAppraisalStep.equipmentIdentity,
      'required_photos' => GuidedQuickAppraisalStep.requiredPhotos,
      'serial_and_hours' => GuidedQuickAppraisalStep.serialAndHours,
      'quick_condition' => GuidedQuickAppraisalStep.quickCondition,
      'notes' => GuidedQuickAppraisalStep.notes,
      'review_and_complete' => GuidedQuickAppraisalStep.reviewAndComplete,
      _ => throw FormatException('Unknown guided Quick Appraisal step: $value'),
    };
  }
}
