import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/guided_quick_appraisal_step.dart';
import 'package:ironsight_ai/domain/entities/inspection.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/detailed_category_response.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';
import 'package:ironsight_ai/features/inspection/presentation/guided_quick_appraisal_screen.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';
import 'support/in_memory_inspection_media_file_store.dart';

class _ControllableInspectionRepository implements LocalInspectionRepository {
  _ControllableInspectionRepository(this._inner);

  final LocalInspectionRepository _inner;
  bool failGuidedIntake = false;
  bool failMetadata = false;
  bool failPendingIdentityOnly = false;
  int guidedIntakeCalls = 0;
  int metadataCalls = 0;

  @override
  Future<Inspection> updateGuidedIntake({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionMachineSource? machineSource,
    String? equipmentId,
    bool clearEquipmentId = false,
    String? pendingAssetName,
    String? pendingManufacturer,
    String? pendingModel,
    bool clearPendingIdentity = false,
    GuidedQuickAppraisalStep? guidedStep,
    String? pendingEquipmentId,
  }) async {
    guidedIntakeCalls += 1;
    if (failGuidedIntake) {
      throw StateError('simulated guided intake failure');
    }
    if (failPendingIdentityOnly &&
        (pendingAssetName != null ||
            pendingManufacturer != null ||
            pendingModel != null)) {
      throw StateError('simulated pending identity failure');
    }
    return _inner.updateGuidedIntake(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: updatedByUserId,
      machineSource: machineSource,
      equipmentId: equipmentId,
      clearEquipmentId: clearEquipmentId,
      pendingAssetName: pendingAssetName,
      pendingManufacturer: pendingManufacturer,
      pendingModel: pendingModel,
      clearPendingIdentity: clearPendingIdentity,
      guidedStep: guidedStep,
      pendingEquipmentId: pendingEquipmentId,
    );
  }

  @override
  Future<Inspection> updateMetadata({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionDepth? depth,
    String? overallNotes,
    bool clearOverallNotes = false,
    String? remoteId,
    bool clearRemoteId = false,
    InspectionSyncStatus? syncStatus,
    InspectionReportStatus? reportStatus,
  }) async {
    metadataCalls += 1;
    if (failMetadata) {
      throw StateError('simulated metadata failure');
    }
    return _inner.updateMetadata(
      companyId: companyId,
      inspectionId: inspectionId,
      updatedByUserId: updatedByUserId,
      depth: depth,
      overallNotes: overallNotes,
      clearOverallNotes: clearOverallNotes,
      remoteId: remoteId,
      clearRemoteId: clearRemoteId,
      syncStatus: syncStatus,
      reportStatus: reportStatus,
    );
  }

  @override
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.complete(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> completeGuidedExistingEquipment({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.completeGuidedExistingEquipment(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> completeGuidedNewMachine({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.completeGuidedNewMachine(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) => _inner.createDraft(
    companyId: companyId,
    equipmentId: equipmentId,
    createdByUserId: createdByUserId,
    depth: depth,
  );

  @override
  Future<Inspection> createGuidedDraft({
    required String companyId,
    required String createdByUserId,
    required InspectionMachineSource machineSource,
    String? equipmentId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) => _inner.createGuidedDraft(
    companyId: companyId,
    createdByUserId: createdByUserId,
    machineSource: machineSource,
    equipmentId: equipmentId,
    depth: depth,
  );

  @override
  Future<Inspection> discardIncomplete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.discardIncomplete(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection?> getById({
    required String companyId,
    required String inspectionId,
  }) => _inner.getById(companyId: companyId, inspectionId: inspectionId);

  @override
  Future<List<Inspection>> listForCompany(
    String companyId, {
    bool includeDiscarded = false,
  }) => _inner.listForCompany(companyId, includeDiscarded: includeDiscarded);

  @override
  Future<Inspection> markHoursUnavailable({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.markHoursUnavailable(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> markSerialUnableToVerify({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => _inner.markSerialUnableToVerify(
    companyId: companyId,
    inspectionId: inspectionId,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> saveCategoryRating({
    required String companyId,
    required String inspectionId,
    required ScorecardCategory category,
    required ConditionRating rating,
    String? updatedByUserId,
  }) => _inner.saveCategoryRating(
    companyId: companyId,
    inspectionId: inspectionId,
    category: category,
    rating: rating,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> saveConfirmedEquipmentId({
    required String companyId,
    required String inspectionId,
    required ConfirmedEquipmentIdValue confirmedValue,
    String? updatedByUserId,
  }) => _inner.saveConfirmedEquipmentId(
    companyId: companyId,
    inspectionId: inspectionId,
    confirmedValue: confirmedValue,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> saveDetailedCategoryResponse({
    required String companyId,
    required String inspectionId,
    required DetailedCategoryResponse response,
    String? updatedByUserId,
  }) => _inner.saveDetailedCategoryResponse(
    companyId: companyId,
    inspectionId: inspectionId,
    response: response,
    updatedByUserId: updatedByUserId,
  );

  @override
  Future<Inspection> switchGuidedDraftToExistingEquipment({
    required String companyId,
    required String inspectionId,
    required String equipmentId,
    String? updatedByUserId,
  }) => _inner.switchGuidedDraftToExistingEquipment(
    companyId: companyId,
    inspectionId: inspectionId,
    equipmentId: equipmentId,
    updatedByUserId: updatedByUserId,
  );
}

void main() {
  late OfflineInspectionWorkspace workspace;
  late _ControllableInspectionRepository inspections;

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

  Future<String> createNewMachineDraft() async {
    final draft = await inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );
    return draft.id;
  }

  Future<void> pumpGuided(
    WidgetTester tester, {
    required String inspectionId,
    required GuidedQuickAppraisalStep step,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedQuickAppraisalScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: inspectionId,
          inspections: inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
          captureControllerFactory: manualCapture,
          initialStepOverride: step,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
    inspections = _ControllableInspectionRepository(workspace.inspections);
  });

  tearDown(() async {
    await workspace.dispose();
  });

  testWidgets('identity save failure keeps typed values and does not pop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final id = await createNewMachineDraft();
    await pumpGuided(
      tester,
      inspectionId: id,
      step: GuidedQuickAppraisalStep.equipmentIdentity,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Keep Me');
    await tester.enterText(fields.at(1), 'Volvo');
    await tester.enterText(fields.at(2), 'ec480');

    inspections.failPendingIdentityOnly = true;
    await tester.tap(find.text('Save and exit'));
    await tester.pumpAndSettle();

    expect(find.text('Save and exit'), findsOneWidget);
    expect(
      find.textContaining('Could not save equipment identity'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'Retry'), findsOneWidget);
    expect(find.text('Keep Me'), findsOneWidget);
    expect(find.text('Volvo'), findsOneWidget);
    expect(find.text('EC480'), findsOneWidget);

    final persisted = await inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(persisted!.pendingAssetName, isNull);
  });

  testWidgets('notes save failure keeps typed notes and does not pop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final id = await createNewMachineDraft();
    await inspections.updateGuidedIntake(
      companyId: 'company-a',
      inspectionId: id,
      pendingAssetName: 'Unit',
      pendingManufacturer: 'Cat',
      pendingModel: '320',
    );
    await pumpGuided(
      tester,
      inspectionId: id,
      step: GuidedQuickAppraisalStep.notes,
    );

    await tester.enterText(find.byType(TextField), 'Do not lose these notes');
    inspections.failMetadata = true;
    await tester.tap(find.text('Save and exit'));
    await tester.pumpAndSettle();

    expect(find.text('Save and exit'), findsOneWidget);
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('Do not lose these notes'), findsOneWidget);

    final persisted = await inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(persisted!.overallNotes, isNull);
  });

  testWidgets('step progress failure on Next stays onscreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final id = await createNewMachineDraft();
    await inspections.updateGuidedIntake(
      companyId: 'company-a',
      inspectionId: id,
      pendingAssetName: 'Unit',
      pendingManufacturer: 'Cat',
      pendingModel: '320',
    );
    await pumpGuided(
      tester,
      inspectionId: id,
      step: GuidedQuickAppraisalStep.requiredPhotos,
    );

    inspections.failGuidedIntake = true;
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Required photos'), findsWidgets);
    expect(find.textContaining('Could not save step progress'), findsOneWidget);
  });

  testWidgets('retry after identity failure exits with saved values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final id = await createNewMachineDraft();
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<bool?>(
                        builder: (_) => GuidedQuickAppraisalScreen(
                          companyId: 'company-a',
                          userId: 'user-1',
                          inspectionId: id,
                          inspections: inspections,
                          equipmentCatalog: workspace.equipmentCatalog,
                          inspectionMedia: workspace.inspectionMedia,
                          captureControllerFactory: manualCapture,
                          initialStepOverride:
                              GuidedQuickAppraisalStep.equipmentIdentity,
                        ),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('Open guided'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open guided'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Retry Unit');
    await tester.enterText(fields.at(1), 'Hitachi');
    await tester.enterText(fields.at(2), 'zx350');

    inspections.failPendingIdentityOnly = true;
    await tester.tap(find.text('Save and exit'));
    await tester.pumpAndSettle();
    expect(popped, isFalse);

    inspections.failPendingIdentityOnly = false;
    await tester.tap(find.widgetWithText(SnackBarAction, 'Retry'));
    await tester.pumpAndSettle();
    expect(popped, isTrue);

    final saved = await inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(saved!.pendingAssetName, 'Retry Unit');
    expect(saved.pendingManufacturer, 'Hitachi');
    expect(saved.pendingModel, 'ZX350');
  });

  testWidgets('Next does not discard identity when persist fails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final id = await createNewMachineDraft();
    await pumpGuided(
      tester,
      inspectionId: id,
      step: GuidedQuickAppraisalStep.equipmentIdentity,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Still Here');
    await tester.enterText(fields.at(1), 'Liebherr');
    await tester.enterText(fields.at(2), 'r956');

    inspections.failPendingIdentityOnly = true;
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Still Here'), findsOneWidget);
    expect(find.text('Enter the machine identity'), findsOneWidget);
  });
}
