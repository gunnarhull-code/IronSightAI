import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/entities/category_rating.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/guided_quick_appraisal_step.dart';
import 'package:ironsight_ai/domain/entities/inspection.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/inspection_media.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/guided_quick_appraisal_completeness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 15, 12);

  Inspection draft({
    InspectionMachineSource? machineSource =
        InspectionMachineSource.newMachine,
    String? equipmentId,
    String? pendingAssetName = 'Unit 1',
    String? pendingManufacturer = 'Cat',
    String? pendingModel = '320',
    String? serialNumber,
    EquipmentIdCaptureMethod? serialCaptureMethod,
    double? hourMeterReading,
    EquipmentIdCaptureMethod? hourMeterCaptureMethod,
    GuidedQuickAppraisalStep? guidedStep,
    List<CategoryRating>? categoryRatings,
  }) {
    return Inspection(
      id: 'insp-1',
      companyId: 'company-a',
      equipmentId: equipmentId,
      createdByUserId: 'user-1',
      completionStatus: InspectionCompletionStatus.inProgress,
      localLifecycle: InspectionLocalLifecycle.active,
      depth: InspectionDepth.quickAppraisal,
      syncStatus: InspectionSyncStatus.localOnly,
      reportStatus: InspectionReportStatus.notGenerated,
      machineSource: machineSource,
      pendingAssetName: pendingAssetName,
      pendingManufacturer: pendingManufacturer,
      pendingModel: pendingModel,
      guidedStep: guidedStep,
      serialNumber: serialNumber,
      serialCaptureMethod: serialCaptureMethod,
      hourMeterReading: hourMeterReading,
      hourMeterCaptureMethod: hourMeterCaptureMethod,
      categoryRatings:
          categoryRatings ??
          [
            for (final category in ScorecardCategory.scorecardOrder)
              CategoryRating(
                category: category,
                rating: ConditionRating.notAssessed,
                updatedAt: now,
              ),
          ],
      createdAt: now,
      updatedAt: now,
      localUpdatedAt: now,
    );
  }

  List<InspectionMedia> allPhotos() {
    return [
      for (final slot in InspectionPhotoSlot.requiredSlots)
        InspectionMedia(
          id: 'm-${slot.storageValue}',
          companyId: 'company-a',
          inspectionId: 'insp-1',
          slot: slot,
          localRelativePath: 'p/${slot.storageValue}.jpg',
          mimeType: 'image/jpeg',
          byteSize: 10,
          capturedAt: now,
          updatedAt: now,
          localUpdatedAt: now,
        ),
    ];
  }

  group('GuidedQuickAppraisalStep', () {
    test('exposes ordered Step X of Y metadata', () {
      expect(GuidedQuickAppraisalStep.order, hasLength(7));
      expect(GuidedQuickAppraisalStep.machineSource.stepNumber, 1);
      expect(GuidedQuickAppraisalStep.reviewAndComplete.stepNumber, 7);
      expect(GuidedQuickAppraisalStep.requiredPhotos.next, GuidedQuickAppraisalStep.serialAndHours);
      expect(GuidedQuickAppraisalStep.serialAndHours.previous, GuidedQuickAppraisalStep.requiredPhotos);
    });
  });

  group('completeness', () {
    test('new machine requires identity, photos, serial, and hours', () {
      final result = evaluateGuidedQuickAppraisalCompleteness(
        inspection: draft(
          pendingAssetName: '',
          serialCaptureMethod: null,
          hourMeterCaptureMethod: null,
        ),
        media: const [],
      );
      expect(result.isComplete, isFalse);
      expect(
        result.missing,
        containsAll({
          GuidedQuickAppraisalRequirement.equipmentIdentity,
          GuidedQuickAppraisalRequirement.requiredPhotos,
          GuidedQuickAppraisalRequirement.serial,
          GuidedQuickAppraisalRequirement.hours,
        }),
      );
      expect(result.firstIncompleteStep, GuidedQuickAppraisalStep.equipmentIdentity);
    });

    test('explicit unavailable serial/hours satisfy requirements', () {
      final result = evaluateGuidedQuickAppraisalCompleteness(
        inspection: draft(
          serialCaptureMethod: EquipmentIdCaptureMethod.unableToVerify,
          hourMeterCaptureMethod: EquipmentIdCaptureMethod.unavailable,
        ),
        media: allPhotos(),
      );
      expect(result.isComplete, isTrue);
      expect(result.firstIncompleteStep, isNull);
    });

    test('existing equipment requires linked equipment id', () {
      final result = evaluateGuidedQuickAppraisalCompleteness(
        inspection: draft(
          machineSource: InspectionMachineSource.existingEquipment,
          equipmentId: null,
          pendingAssetName: null,
          pendingManufacturer: null,
          pendingModel: null,
          serialCaptureMethod: EquipmentIdCaptureMethod.unableToVerify,
          hourMeterCaptureMethod: EquipmentIdCaptureMethod.unavailable,
        ),
        media: allPhotos(),
      );
      expect(
        result.missing,
        contains(GuidedQuickAppraisalRequirement.equipmentIdentity),
      );
    });

    test('seeded not assessed ratings satisfy condition requirement', () {
      final result = evaluateGuidedQuickAppraisalCompleteness(
        inspection: draft(
          serialNumber: 'ABC',
          serialCaptureMethod: EquipmentIdCaptureMethod.manual,
          hourMeterReading: 12,
          hourMeterCaptureMethod: EquipmentIdCaptureMethod.manual,
        ),
        media: allPhotos(),
      );
      expect(result.isComplete, isTrue);
      expect(result.unratedCategories, isEmpty);
    });
  });

  group('resume step', () {
    test('resumes at first incomplete when no guided step saved', () {
      final step = resolveGuidedResumeStep(
        inspection: draft(
          guidedStep: null,
          serialCaptureMethod: null,
          hourMeterCaptureMethod: null,
        ),
        media: allPhotos(),
      );
      expect(step, GuidedQuickAppraisalStep.serialAndHours);
    });

    test('prefers earlier incomplete over later visited step', () {
      final step = resolveGuidedResumeStep(
        inspection: draft(
          guidedStep: GuidedQuickAppraisalStep.notes,
          serialCaptureMethod: null,
          hourMeterCaptureMethod: EquipmentIdCaptureMethod.unavailable,
        ),
        media: allPhotos(),
      );
      expect(step, GuidedQuickAppraisalStep.serialAndHours);
    });

    test('resumes at last visited when earlier steps are complete', () {
      final step = resolveGuidedResumeStep(
        inspection: draft(
          guidedStep: GuidedQuickAppraisalStep.notes,
          serialCaptureMethod: EquipmentIdCaptureMethod.unableToVerify,
          hourMeterCaptureMethod: EquipmentIdCaptureMethod.unavailable,
        ),
        media: allPhotos(),
      );
      expect(step, GuidedQuickAppraisalStep.notes);
    });
  });

  group('Inspection unavailable helpers', () {
    test('hasResolvedSerial/hours honor explicit unavailable choices', () {
      final inspection = draft(
        serialCaptureMethod: EquipmentIdCaptureMethod.unableToVerify,
        hourMeterCaptureMethod: EquipmentIdCaptureMethod.unavailable,
      );
      expect(inspection.hasResolvedSerial, isTrue);
      expect(inspection.hasResolvedHours, isTrue);
      expect(inspection.serialIsUnableToVerify, isTrue);
      expect(inspection.hoursAreUnavailable, isTrue);
      expect(inspection.confirmedSerialNumber?.method, EquipmentIdCaptureMethod.unableToVerify);
      expect(inspection.confirmedHourMeter?.method, EquipmentIdCaptureMethod.unavailable);
    });
  });
}
