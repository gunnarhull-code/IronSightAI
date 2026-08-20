import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/guided_quick_appraisal_step.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/features/inspection/presentation/ai_media_review_labels.dart';
import 'package:ironsight_ai/features/inspection/presentation/guided_quick_appraisal_entry_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/guided_quick_appraisal_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/widgets/condition_rating_controls.dart';

import 'support/fake_ai_service.dart';
import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';
import 'support/fake_walkaround_video_capture.dart';
import 'support/in_memory_inspection_media_file_store.dart';

void main() {
  late OfflineInspectionWorkspace workspace;

  EquipmentIdCaptureController manualCapture({
    required EquipmentIdCaptureKind kind,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    return EquipmentIdCaptureController(
      kind: kind,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: initialConfirmed,
    );
  }

  Equipment equipment({required String id}) {
    final now = DateTime.utc(2026, 8, 1);
    return Equipment(
      id: id,
      companyId: 'company-a',
      assetName: 'Excavator $id',
      manufacturer: 'Caterpillar',
      model: '320',
      serialNumber: 'SN-$id',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpGuided(
    WidgetTester tester, {
    required String inspectionId,
    GuidedQuickAppraisalStep? initialStep,
    FakeAIService? aiService,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedQuickAppraisalScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: inspectionId,
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
          captureControllerFactory: manualCapture,
          initialStepOverride: initialStep,
          aiService: aiService,
          videoCapture: FakeWalkaroundVideoCapture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    final database = openMemoryAppDatabase();
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: database,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  testWidgets('entry shows New machine and Existing equipment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedQuickAppraisalEntryScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New machine'), findsOneWidget);
    expect(find.text('Existing equipment'), findsOneWidget);
    expect(find.text('Resume in-progress drafts'), findsOneWidget);
  });

  testWidgets('guided shell shows Step X of Y, Back, Next, Save and exit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );

    await pumpGuided(
      tester,
      inspectionId: draft.id,
      initialStep: GuidedQuickAppraisalStep.equipmentIdentity,
    );

    expect(find.textContaining('Step '), findsWidgets);
    expect(find.text('Save and exit'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('new machine identity fields save uppercase model on Next', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );

    await pumpGuided(
      tester,
      inspectionId: draft.id,
      initialStep: GuidedQuickAppraisalStep.equipmentIdentity,
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'Unit A');
    await tester.enterText(fields.at(1), 'Komatsu');
    await tester.enterText(fields.at(2), 'wa380');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final saved = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: draft.id,
    );
    expect(saved!.pendingAssetName, 'Unit A');
    expect(saved.pendingManufacturer, 'Komatsu');
    expect(saved.pendingModel, 'WA380');
    expect(saved.guidedStep, GuidedQuickAppraisalStep.requiredPhotos);
  });

  testWidgets(
    'serial unable-to-verify and hours unavailable persist without Confirm',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Unit',
        pendingManufacturer: 'Cat',
        pendingModel: '320',
      );

      await pumpGuided(
        tester,
        inspectionId: draft.id,
        initialStep: GuidedQuickAppraisalStep.serialAndHours,
      );

      expect(find.text('Confirm'), findsNothing);
      await tester.ensureVisible(find.text('Unable to verify'));
      await tester.tap(find.text('Unable to verify'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unavailable / not displayed'));
      await tester.tap(find.text('Unavailable / not displayed'));
      await tester.pumpAndSettle();

      final saved = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(saved!.serialIsUnableToVerify, isTrue);
      expect(saved.hoursAreUnavailable, isTrue);
    },
  );

  testWidgets('condition ratings include Not assessed and persist', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );
    await workspace.inspections.updateGuidedIntake(
      companyId: 'company-a',
      inspectionId: draft.id,
      pendingAssetName: 'Unit',
      pendingManufacturer: 'Cat',
      pendingModel: '320',
    );

    await pumpGuided(
      tester,
      inspectionId: draft.id,
      initialStep: GuidedQuickAppraisalStep.quickCondition,
    );

    expect(find.byType(ConditionRatingControls), findsWidgets);
    expect(find.text('Not assessed'), findsWidgets);
    expect(find.text('Engine'), findsOneWidget);

    // First "Good" belongs to Engine (first category).
    final goodButtons = find.text('Good');
    await tester.ensureVisible(goodButtons.first);
    await tester.tap(goodButtons.first);
    await tester.pumpAndSettle();

    final saved = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: draft.id,
    );
    expect(saved!.ratingFor(ScorecardCategory.engine), ConditionRating.good);
  });

  testWidgets('review lists missing requirements and jumps to step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );

    await pumpGuided(
      tester,
      inspectionId: draft.id,
      initialStep: GuidedQuickAppraisalStep.reviewAndComplete,
    );

    expect(find.text('Review & Complete'), findsWidgets);
    expect(find.textContaining('Missing'), findsWidgets);

    final missingIdentity = find.textContaining('Equipment identity');
    expect(missingIdentity, findsWidgets);
    await tester.tap(missingIdentity.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 2'), findsWidgets);
  });

  testWidgets('existing equipment selection from local catalog', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: 'company-a',
      equipment: [equipment(id: 'eq-1')],
    );
    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.existingEquipment,
      equipmentId: 'eq-1',
    );

    await pumpGuided(
      tester,
      inspectionId: draft.id,
      initialStep: GuidedQuickAppraisalStep.equipmentIdentity,
    );
    expect(find.text('Excavator eq-1'), findsWidgets);
  });

  testWidgets(
    'guided photos step exposes optional AI Media Review without requiring it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );
      await workspace.inspections.updateGuidedIntake(
        companyId: 'company-a',
        inspectionId: draft.id,
        pendingAssetName: 'Unit',
        pendingManufacturer: 'Cat',
        pendingModel: '320',
      );

      await pumpGuided(
        tester,
        inspectionId: draft.id,
        initialStep: GuidedQuickAppraisalStep.requiredPhotos,
        aiService: FakeAIService(),
      );

      expect(find.text(AiMediaReviewLabels.actionButton), findsOneWidget);
      expect(find.textContaining('works offline without AI'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text(AiMediaReviewLabels.actionButton));
      await tester.pumpAndSettle();
      expect(find.text(AiMediaReviewLabels.analyzeButton), findsOneWidget);
      expect(find.text(AiMediaReviewLabels.continueWithoutAi), findsOneWidget);

      await tester.tap(find.text(AiMediaReviewLabels.continueWithoutAi));
      await tester.pumpAndSettle();
      expect(find.text(AiMediaReviewLabels.actionButton), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    },
  );

  testWidgets(
    'guided review step keeps AI Media Review optional and reachable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final draft = await workspace.inspections.createGuidedDraft(
        companyId: 'company-a',
        createdByUserId: 'user-1',
        machineSource: InspectionMachineSource.newMachine,
      );

      await pumpGuided(
        tester,
        inspectionId: draft.id,
        initialStep: GuidedQuickAppraisalStep.reviewAndComplete,
        aiService: FakeAIService(),
      );

      expect(find.text(AiMediaReviewLabels.actionButton), findsOneWidget);
      expect(find.textContaining('works offline without AI'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    },
  );
}
