import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/inspection_media_file_store.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_labels.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_workspace_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/widgets/required_inspection_photos_section.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';

Equipment _eq(String id) {
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

void main() {
  late OfflineInspectionWorkspace workspace;
  late Directory mediaRoot;
  late FakeImageCapture photoCapture;
  late FakeTextRecognition serialOcr;
  late FakeTextRecognition hoursOcr;

  EquipmentIdCaptureController captureFactory({
    required EquipmentIdCaptureKind kind,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    return EquipmentIdCaptureController(
      kind: kind,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: kind == EquipmentIdCaptureKind.serialNumber
          ? serialOcr
          : hoursOcr,
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: initialConfirmed,
    );
  }

  setUp(() {
    mediaRoot = Directory.systemTemp.createTempSync('ironsight_photo_ui_');
    photoCapture = FakeImageCapture(
      image: const CapturedImage(bytes: [1, 2, 3, 4, 5], path: '/tmp/p.jpg'),
    );
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
      mediaFiles: InspectionMediaFileStore(
        documentsDirectoryOverride: () => mediaRoot,
      ),
    );
  });

  tearDown(() async {
    await workspace.dispose();
    if (mediaRoot.existsSync()) mediaRoot.deleteSync(recursive: true);
  });

  testWidgets(
    'required photo slots show missing then completed after capture',
    (tester) async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_eq('eq-1')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionWorkspaceScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
            inspectionMedia: workspace.inspectionMedia,
            captureControllerFactory: captureFactory,
            imageCapture: photoCapture,
            cameraPermission: FakeCameraPermission(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Required photos'), findsOneWidget);
      for (final slot in InspectionPhotoSlot.requiredSlots) {
        expect(find.text(slot.label), findsOneWidget);
        expect(
          find.bySemanticsLabel(RequiredPhotoLabels.slotStatus(slot)),
          findsOneWidget,
        );
      }
      expect(find.text('Missing'), findsNWidgets(4));
      expect(find.text('Completed'), findsNothing);

      await tester.tap(
        find.bySemanticsLabel(
          RequiredPhotoLabels.captureButton(
            InspectionPhotoSlot.frontLeftOverview,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(photoCapture.captureCallCount, 1);
      final saved = await workspace.inspectionMedia.getBySlot(
        companyId: 'company-a',
        inspectionId: draft.id,
        slot: InspectionPhotoSlot.frontLeftOverview,
      );
      expect(saved, isNotNull);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Missing'), findsNWidgets(3));
    },
  );

  testWidgets('OCR scan reuses required serial photo without second capture', (
    tester,
  ) async {
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: 'company-a',
      equipment: [_eq('eq-2')],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: 'company-a',
      equipmentId: 'eq-2',
      createdByUserId: 'user-1',
    );
    await workspace.inspectionMedia.saveRequiredPhoto(
      companyId: 'company-a',
      inspectionId: draft.id,
      slot: InspectionPhotoSlot.serialDataPlate,
      image: const CapturedImage(bytes: [9, 8, 7], path: '/tmp/serial.jpg'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InspectionWorkspaceScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: draft.id,
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
          captureControllerFactory: captureFactory,
          imageCapture: photoCapture,
          cameraPermission: FakeCameraPermission(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.serialScanButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.serialScanButton),
    );
    await tester.pumpAndSettle();

    expect(photoCapture.captureCallCount, 0);
    expect(serialOcr.recognizeCallCount, 1);
    expect(find.textContaining('SN-PHOTO-1'), findsWidgets);
  });

  testWidgets('RequiredInspectionPhotosSection renders previews', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequiredInspectionPhotosSection(
            mediaBySlot: const {},
            previewBytesBySlot: {
              InspectionPhotoSlot.frontLeftOverview: Uint8List.fromList(
                // Minimal invalid JPEG bytes still build an Image.memory widget;
                // errorBuilder is not required for finder presence.
                [0xFF, 0xD8, 0xFF, 0xD9],
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
    );
    await tester.pump();
    expect(find.text('Front-left overview'), findsOneWidget);
    expect(find.text('Missing'), findsNWidgets(4));
  });
}
