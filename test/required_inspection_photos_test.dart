import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/camera_permission_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_failure.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/image_capture_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_labels.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_workspace_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/widgets/required_inspection_photos_section.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';
import 'support/in_memory_inspection_media_file_store.dart';
import 'support/test_images.dart';

Equipment _equipment(String id) {
  final now = DateTime.utc(2026, 8, 1);
  return Equipment(
    id: id,
    companyId: 'company-a',
    assetName: 'Loader',
    manufacturer: 'Cat',
    model: '950',
    serialNumber: 'SN-$id',
    createdAt: now,
    updatedAt: now,
  );
}

const CapturedImage _photo = CapturedImage(
  bytes: kTinyPngBytes,
  path: '/tmp/required.png',
  mimeType: 'image/png',
);

void main() {
  late OfflineInspectionWorkspace workspace;
  late InMemoryInspectionMediaFileStore mediaFiles;
  late FakeImageCapture photoCapture;
  late FakeCameraPermission photoPermission;
  late FakeImageCapture panelCapture;
  late FakeTextRecognition serialOcr;
  late FakeTextRecognition hoursOcr;

  EquipmentIdCaptureController captureFactory({
    required EquipmentIdCaptureKind kind,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    return EquipmentIdCaptureController(
      kind: kind,
      // Mirrors mobile: the panel's own camera works, but the required-photo
      // reuse path must never open it.
      imageCapture: panelCapture,
      textRecognition: kind == EquipmentIdCaptureKind.serialNumber
          ? serialOcr
          : hoursOcr,
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: initialConfirmed,
    );
  }

  setUp(() {
    mediaFiles = InMemoryInspectionMediaFileStore();
    photoCapture = FakeImageCapture(image: _photo);
    photoPermission = FakeCameraPermission();
    panelCapture = FakeImageCapture(image: _photo);
    serialOcr = FakeTextRecognition(
      blocks: const [RecognizedTextBlock(rawText: 'SN-PHOTO-1')],
    );
    hoursOcr = FakeTextRecognition(
      blocks: const [RecognizedTextBlock(rawText: 'HOURS 321')],
    );
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: mediaFiles,
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  /// Tall viewport so the whole Quick Appraisal capture set is reachable
  /// without scrolling; scroll behaviour has its own dedicated test.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpWorkspace(WidgetTester tester, String inspectionId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InspectionWorkspaceScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: inspectionId,
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
          captureControllerFactory: captureFactory,
          imageCapture: photoCapture,
          cameraPermission: photoPermission,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Reopens the same draft in a fresh screen, as returning to it would.
  Future<void> reopenWorkspace(WidgetTester tester, String inspectionId) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpWorkspace(tester, inspectionId);
  }

  Future<String> openDraft(
    WidgetTester tester, {
    String equipmentId = 'eq-1',
    bool tallViewport = true,
  }) async {
    if (tallViewport) useTallViewport(tester);
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: 'company-a',
      equipment: [_equipment(equipmentId)],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: 'company-a',
      equipmentId: equipmentId,
      createdByUserId: 'user-1',
    );
    await pumpWorkspace(tester, draft.id);
    return draft.id;
  }

  Finder statusOf(InspectionPhotoSlot slot, {required bool completed}) =>
      find.bySemanticsLabel(
        RequiredPhotoLabels.slotStatus(slot, completed: completed),
      );

  Future<void> tapCapture(WidgetTester tester, InspectionPhotoSlot slot) async {
    final capture = find.bySemanticsLabel(
      RequiredPhotoLabels.captureButton(slot),
    );
    final retake = find.bySemanticsLabel(
      RequiredPhotoLabels.retakeButton(slot),
    );
    final target = capture.evaluate().isNotEmpty ? capture : retake;
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('all four required slots start missing and label clearly', (
    tester,
  ) async {
    await openDraft(tester);

    expect(find.text('Required photos'), findsOneWidget);
    for (final slot in InspectionPhotoSlot.requiredSlots) {
      expect(find.text(slot.label), findsOneWidget);
      expect(statusOf(slot, completed: false), findsOneWidget);
    }
    expect(find.text('Missing'), findsNWidgets(4));
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('capture persists the photo and flips the slot to completed', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);

    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);

    expect(photoCapture.captureCallCount, 1);
    final saved = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    expect(saved, isNotNull);
    expect(mediaFiles.files[saved!.localRelativePath], kTinyPngBytes);
    expect(
      statusOf(InspectionPhotoSlot.frontLeftOverview, completed: true),
      findsOneWidget,
    );
    expect(find.text('Missing'), findsNWidgets(3));
  });

  testWidgets('retaking one slot leaves the other slots untouched', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);

    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);
    await tapCapture(tester, InspectionPhotoSlot.rearRightOverview);

    final firstFront = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    final rear = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.rearRightOverview,
    );

    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);

    final retakenFront = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    final rearAfter = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.rearRightOverview,
    );

    expect(retakenFront!.id, isNot(firstFront!.id));
    expect(rearAfter!.id, rear!.id);
    expect(rearAfter.localRelativePath, rear.localRelativePath);
    expect(mediaFiles.files.containsKey(firstFront.localRelativePath), isFalse);
    expect(mediaFiles.files.containsKey(rearAfter.localRelativePath), isTrue);
  });

  testWidgets('cancelled retake keeps the previously captured photo', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);
    final before = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );

    photoCapture.error = EquipmentIdCaptureException(
      EquipmentIdCaptureFailure.captureCancelled(),
    );
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);

    final after = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    expect(after!.id, before!.id);
    expect(mediaFiles.files.containsKey(after.localRelativePath), isTrue);
    expect(
      statusOf(InspectionPhotoSlot.frontLeftOverview, completed: true),
      findsOneWidget,
    );
  });

  testWidgets('denied camera permission preserves the existing photo', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);
    final before = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );

    photoPermission.requestStatus = CameraPermissionStatus.denied;
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);

    expect(photoCapture.captureCallCount, 1);
    expect(
      find.text(EquipmentIdCaptureFailure.permissionDenied().message),
      findsOneWidget,
    );
    final after = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    expect(after!.id, before!.id);
  });

  testWidgets('local persistence failure preserves the previous photo', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);
    final before = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );

    mediaFiles.failWrites = true;
    await tapCapture(tester, InspectionPhotoSlot.frontLeftOverview);

    expect(find.text('Could not save photo locally.'), findsOneWidget);
    final after = await workspace.inspectionMedia.getBySlot(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.frontLeftOverview,
    );
    expect(after!.id, before!.id);
    expect(mediaFiles.files.containsKey(after.localRelativePath), isTrue);
  });

  testWidgets('serial photo capture runs OCR once without saving a value', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester);

    await tapCapture(tester, InspectionPhotoSlot.serialDataPlate);

    expect(photoCapture.captureCallCount, 1);
    expect(serialOcr.recognizeCallCount, 1);
    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: inspectionId,
    );
    expect(
      inspection!.serialNumber,
      isNull,
      reason: 'OCR is advisory until the user confirms',
    );
  });

  testWidgets('OCR scan reuses the required serial photo without recapture', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester, equipmentId: 'eq-2');
    await workspace.inspectionMedia.saveRequiredPhoto(
      companyId: 'company-a',
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.serialDataPlate,
      image: _photo,
    );
    await reopenWorkspace(tester, inspectionId);

    final scanButton = find.bySemanticsLabel(
      EquipmentIdCaptureLabels.serialScanButton,
    );
    await tester.ensureVisible(scanButton);
    await tester.pumpAndSettle();
    await tester.tap(scanButton);
    await tester.pumpAndSettle();

    expect(photoCapture.captureCallCount, 0);
    expect(panelCapture.captureCallCount, 0);
    expect(serialOcr.recognizeCallCount, 1);
    expect(find.textContaining('SN-PHOTO-1'), findsWidgets);

    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: inspectionId,
    );
    expect(inspection!.serialNumber, isNull);
  });

  testWidgets('OCR does not overwrite an already confirmed serial', (
    tester,
  ) async {
    final inspectionId = await openDraft(tester, equipmentId: 'eq-3');
    await workspace.inspections.saveConfirmedEquipmentId(
      companyId: 'company-a',
      inspectionId: inspectionId,
      confirmedValue: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'CONFIRMED-1',
        method: EquipmentIdCaptureMethod.manual,
      ),
      updatedByUserId: 'user-1',
    );
    await reopenWorkspace(tester, inspectionId);

    await tapCapture(tester, InspectionPhotoSlot.serialDataPlate);

    expect(serialOcr.recognizeCallCount, 1);
    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: inspectionId,
    );
    expect(inspection!.serialNumber, 'CONFIRMED-1');
    expect(inspection.serialCaptureMethod, EquipmentIdCaptureMethod.manual);
  });

  testWidgets('captured photos survive reopening the draft', (tester) async {
    final inspectionId = await openDraft(tester, equipmentId: 'eq-4');
    await tapCapture(tester, InspectionPhotoSlot.rearRightOverview);

    await reopenWorkspace(tester, inspectionId);

    expect(
      statusOf(InspectionPhotoSlot.rearRightOverview, completed: true),
      findsOneWidget,
    );
    expect(find.text('Missing'), findsNWidgets(3));
  });

  testWidgets('photo capture preserves Quick Appraisal scroll position', (
    tester,
  ) async {
    await openDraft(tester, equipmentId: 'eq-5', tallViewport: false);

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -80));
    await tester.pumpAndSettle();
    final before = tester.widget<Scrollable>(scrollable).controller!.offset;

    await tester.tap(
      find.bySemanticsLabel(
        RequiredPhotoLabels.captureButton(
          InspectionPhotoSlot.rearRightOverview,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final after = tester.widget<Scrollable>(scrollable).controller!.offset;
    expect(
      after,
      closeTo(before, 1.0),
      reason: 'in-place photo save must not jump Quick Appraisal scroll',
    );
  });

  testWidgets('preview thumbnail renders decoded photo bytes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RequiredInspectionPhotosSection(
              mediaBySlot: const {},
              previewBytesBySlot: {
                InspectionPhotoSlot.frontLeftOverview: Uint8List.fromList(
                  kTinyPngBytes,
                ),
              },
              enabled: true,
              busySlot: null,
              onCapture: (_) async {},
              onRetake: (_) async {},
              onPreview: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Front-left overview'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RequiredPhotoLabels.previewThumbnail(
          InspectionPhotoSlot.frontLeftOverview,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('undecodable preview bytes fall back without breaking the slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RequiredInspectionPhotosSection(
              mediaBySlot: const {},
              previewBytesBySlot: {
                InspectionPhotoSlot.frontLeftOverview: Uint8List.fromList(
                  const [0, 1, 2, 3],
                ),
              },
              enabled: true,
              busySlot: null,
              onCapture: (_) async {},
              onRetake: (_) async {},
              onPreview: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(RequiredPhotoLabels.unreadablePreview), findsOneWidget);
    expect(find.text('Front-left overview'), findsOneWidget);
  });
}
