import 'entities/guided_quick_appraisal_step.dart';
import 'entities/inspection.dart';
import 'entities/inspection_machine_source.dart';
import 'entities/inspection_media.dart';
import 'entities/inspection_photo_slot.dart';
import 'entities/scorecard_category.dart';

/// Missing requirements that block guided Quick Appraisal completion.
enum GuidedQuickAppraisalRequirement {
  machineSource,
  equipmentIdentity,
  requiredPhotos,
  serial,
  hours,
  conditionRatings,
}

/// Result of evaluating guided draft completeness for Review & Complete.
class GuidedQuickAppraisalCompleteness {
  const GuidedQuickAppraisalCompleteness({
    required this.missing,
    required this.missingPhotoSlots,
    required this.unratedCategories,
  });

  final Set<GuidedQuickAppraisalRequirement> missing;
  final List<InspectionPhotoSlot> missingPhotoSlots;
  final List<ScorecardCategory> unratedCategories;

  bool get isComplete => missing.isEmpty;

  GuidedQuickAppraisalStep? get firstIncompleteStep {
    if (missing.contains(GuidedQuickAppraisalRequirement.machineSource)) {
      return GuidedQuickAppraisalStep.machineSource;
    }
    if (missing.contains(GuidedQuickAppraisalRequirement.equipmentIdentity)) {
      return GuidedQuickAppraisalStep.equipmentIdentity;
    }
    if (missing.contains(GuidedQuickAppraisalRequirement.requiredPhotos)) {
      return GuidedQuickAppraisalStep.requiredPhotos;
    }
    if (missing.contains(GuidedQuickAppraisalRequirement.serial) ||
        missing.contains(GuidedQuickAppraisalRequirement.hours)) {
      return GuidedQuickAppraisalStep.serialAndHours;
    }
    if (missing.contains(GuidedQuickAppraisalRequirement.conditionRatings)) {
      return GuidedQuickAppraisalStep.quickCondition;
    }
    return null;
  }
}

/// Evaluates whether a guided draft is ready to complete.
///
/// Condition categories seeded as [ConditionRating.notAssessed] satisfy the
/// deliberate Good/Fair/Poor/Not assessed requirement. Notes remain optional.
GuidedQuickAppraisalCompleteness evaluateGuidedQuickAppraisalCompleteness({
  required Inspection inspection,
  required List<InspectionMedia> media,
}) {
  final missing = <GuidedQuickAppraisalRequirement>{};
  final presentSlots = media.map((item) => item.slot).toSet();
  final missingPhotos = InspectionPhotoSlot.requiredSlots
      .where((slot) => !presentSlots.contains(slot))
      .toList(growable: false);

  final source = inspection.machineSource;
  // Guided completeness applies only to guided drafts. Callers must not use
  // this helper to gate legacy (machineSource == null) completion.
  if (source == null) {
    return const GuidedQuickAppraisalCompleteness(
      missing: {},
      missingPhotoSlots: [],
      unratedCategories: [],
    );
  }

  if (source == InspectionMachineSource.newMachine) {
    final name = inspection.pendingAssetName?.trim() ?? '';
    final manufacturer = inspection.pendingManufacturer?.trim() ?? '';
    final model = inspection.pendingModel?.trim() ?? '';
    if (name.isEmpty || manufacturer.isEmpty || model.isEmpty) {
      missing.add(GuidedQuickAppraisalRequirement.equipmentIdentity);
    }
  } else if (source == InspectionMachineSource.existingEquipment) {
    if (inspection.equipmentId == null || inspection.equipmentId!.isEmpty) {
      missing.add(GuidedQuickAppraisalRequirement.equipmentIdentity);
    }
  }

  if (missingPhotos.isNotEmpty) {
    missing.add(GuidedQuickAppraisalRequirement.requiredPhotos);
  }
  if (!inspection.hasResolvedSerial) {
    missing.add(GuidedQuickAppraisalRequirement.serial);
  }
  if (!inspection.hasResolvedHours) {
    missing.add(GuidedQuickAppraisalRequirement.hours);
  }

  final unrated = <ScorecardCategory>[];
  for (final category in ScorecardCategory.scorecardOrder) {
    final hasRow = inspection.categoryRatings.any(
      (rating) => rating.category == category,
    );
    if (!hasRow) {
      unrated.add(category);
      missing.add(GuidedQuickAppraisalRequirement.conditionRatings);
    }
  }

  return GuidedQuickAppraisalCompleteness(
    missing: missing,
    missingPhotoSlots: missingPhotos,
    unratedCategories: unrated,
  );
}

/// Chooses the step to resume: last visited when set, otherwise first incomplete.
GuidedQuickAppraisalStep resolveGuidedResumeStep({
  required Inspection inspection,
  required List<InspectionMedia> media,
}) {
  final completeness = evaluateGuidedQuickAppraisalCompleteness(
    inspection: inspection,
    media: media,
  );
  final incomplete = completeness.firstIncompleteStep;
  final visited = inspection.guidedStep;

  if (visited == null) {
    return incomplete ?? GuidedQuickAppraisalStep.reviewAndComplete;
  }

  if (incomplete != null && incomplete.index <= visited.index) {
    return incomplete;
  }
  return visited;
}
