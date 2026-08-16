import '../../../../app/router.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/inspection_status.dart';

/// Resolves the correct incomplete-draft route without converting legacy drafts.
///
/// Guided drafts (`machineSource != null`) use the guided intake. Migrated
/// legacy drafts keep the pre-guided workspace so prior completion rules apply.
String incompleteInspectionRoute(Inspection inspection) {
  if (inspection.completionStatus == InspectionCompletionStatus.completed) {
    return AppRoutes.inspectionReview(inspection.id);
  }
  if (inspection.isGuidedDraft) {
    return AppRoutes.guidedQuickAppraisal(inspection.id);
  }
  return AppRoutes.inspectionWorkspace(inspection.id);
}
