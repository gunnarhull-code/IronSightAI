import '../entities/inspection.dart';
import '../entities/inspection_status.dart';
import '../repositories/local_inspection_repository.dart';

/// Returns active in-progress drafts for one equipment record.
class FindActiveDraftsForEquipment {
  const FindActiveDraftsForEquipment(this._repository);

  final LocalInspectionRepository _repository;

  Future<List<Inspection>> call({
    required String companyId,
    required String equipmentId,
  }) async {
    final inspections = await _repository.listForCompany(companyId);
    return inspections
        .where(
          (inspection) =>
              inspection.equipmentId == equipmentId &&
              inspection.localLifecycle == InspectionLocalLifecycle.active &&
              inspection.completionStatus ==
                  InspectionCompletionStatus.inProgress,
        )
        .toList(growable: false);
  }
}
