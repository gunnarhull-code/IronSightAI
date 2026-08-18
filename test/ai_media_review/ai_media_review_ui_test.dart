import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_controller.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_result.dart';
import 'package:ironsight_ai/domain/ai/ai_media_source.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_kind.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/features/inspection/presentation/ai_media_review_labels.dart';
import 'package:ironsight_ai/features/inspection/presentation/ai_media_review_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_workspace_screen.dart';

import '../support/fake_ai_service.dart';
import '../support/fake_auth_session_reader.dart';
import '../support/fake_equipment_id_capture.dart';
import '../support/fake_equipment_repository.dart';
import '../support/fake_walkaround_video_capture.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_outcome.dart';
import '../support/in_memory_inspection_media_file_store.dart';
import '../support/test_images.dart';

const _photo = CapturedImage(
  bytes: kTinyPngBytes,
  path: '/tmp/required.png',
  mimeType: 'image/png',
);

void main() {
  late OfflineInspectionWorkspace workspace;
  late FakeAIService ai;

  setUp(() {
    ai = FakeAIService(
      result: const AiMediaReviewResult(
        suggestions: [
          AiSuggestion(
            id: 's-serial',
            kind: AiSuggestionKind.serialNumber,
            confidence: AiSuggestionConfidence.medium,
            source: AiMediaSource(
              type: AiMediaSourceType.photo,
              label: 'Serial / data plate',
              slot: InspectionPhotoSlot.serialDataPlate,
            ),
            value: 'SN-AI-1',
            hasAmbiguousSerialCharacters: true,
          ),
          AiSuggestion(
            id: 's-rust',
            kind: AiSuggestionKind.rust,
            confidence: AiSuggestionConfidence.low,
            source: AiMediaSource(
              type: AiMediaSourceType.photo,
              label: 'Front-left overview',
              slot: InspectionPhotoSlot.frontLeftOverview,
            ),
            value: 'Surface rust',
            uncertainty: 'Could be dirt',
          ),
        ],
      ),
    );
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<String> openDraft() async {
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: 'company-a',
      equipment: [
        Equipment(
          id: 'eq-1',
          companyId: 'company-a',
          assetName: 'Loader',
          manufacturer: 'Cat',
          model: '950',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: 'company-a',
      equipmentId: 'eq-1',
      createdByUserId: 'user-1',
    );
    await workspace.inspectionMedia.saveRequiredPhoto(
      companyId: 'company-a',
      inspectionId: draft.id,
      slot: InspectionPhotoSlot.serialDataPlate,
      image: _photo,
    );
    return draft.id;
  }

  testWidgets('workspace exposes AI Media Review without requiring it', (
    tester,
  ) async {
    useTallViewport(tester);
    final id = await openDraft();
    await tester.pumpWidget(
      MaterialApp(
        home: InspectionWorkspaceScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: id,
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
          captureControllerFactory:
              ({required kind, ConfirmedEquipmentIdValue? initialConfirmed}) {
                return EquipmentIdCaptureController(
                  kind: kind,
                  imageCapture: FakeImageCapture(image: _photo),
                  textRecognition: FakeTextRecognition(),
                  cameraPermission: FakeCameraPermission(),
                  initialConfirmed: initialConfirmed,
                );
              },
          imageCapture: FakeImageCapture(image: _photo),
          cameraPermission: FakeCameraPermission(),
          aiService: ai,
          videoCapture: FakeWalkaroundVideoCapture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AiMediaReviewLabels.actionButton), findsOneWidget);
    expect(find.textContaining('works offline without AI'), findsOneWidget);
    await tester.tap(find.text(AiMediaReviewLabels.actionButton));
    await tester.pumpAndSettle();
    expect(find.text(AiMediaReviewLabels.analyzeButton), findsOneWidget);
    expect(find.text(AiMediaReviewLabels.consentBody), findsOneWidget);
    expect(
      find.text(AiMediaReviewLabels.frameBasedExplanation),
      findsOneWidget,
    );
  });

  testWidgets('analyze, apply, edit, and dismiss keep accessibility labels', (
    tester,
  ) async {
    useTallViewport(tester);
    final id = await openDraft();
    final controller = AiMediaReviewController(
      companyId: 'company-a',
      inspectionId: id,
      userId: 'user-1',
      aiService: ai,
      inspections: workspace.inspections,
      inspectionMedia: workspace.inspectionMedia,
      videoCapture: FakeWalkaroundVideoCapture(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AiMediaReviewScreen(
          companyId: 'company-a',
          inspectionId: id,
          userId: 'user-1',
          aiService: ai,
          inspections: workspace.inspections,
          inspectionMedia: workspace.inspectionMedia,
          videoCapture: FakeWalkaroundVideoCapture(),
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(AiMediaReviewLabels.analyzeButton),
      findsWidgets,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AiMediaReviewLabels.analyzeButton),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Confidence: Medium'), findsOneWidget);
    expect(find.textContaining('Confidence: Low'), findsOneWidget);
    expect(find.text(AiMediaReviewLabels.ambiguityNote), findsOneWidget);
    expect(find.textContaining('Supported by'), findsWidgets);

    await tester.tap(find.text(AiMediaReviewLabels.dismissButton).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rust · Dismissed'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'SN-AI-1'),
      'SN-EDITED',
    );
    await tester.tap(find.text(AiMediaReviewLabels.applyButton).first);
    await tester.pumpAndSettle();

    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(inspection!.serialNumber, 'SN-EDITED');
    expect(inspection.overallNotes, isNull);
  });

  testWidgets('offline failure is announced without losing inspection data', (
    tester,
  ) async {
    useTallViewport(tester);
    final id = await openDraft();
    ai.error = AiMediaReviewException(AiMediaReviewFailure.offline());
    await tester.pumpWidget(
      MaterialApp(
        home: AiMediaReviewScreen(
          companyId: 'company-a',
          inspectionId: id,
          userId: 'user-1',
          aiService: ai,
          inspections: workspace.inspections,
          inspectionMedia: workspace.inspectionMedia,
          videoCapture: FakeWalkaroundVideoCapture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AiMediaReviewLabels.analyzeButton),
    );
    await tester.pumpAndSettle();
    expect(find.text('Offline / unavailable'), findsOneWidget);
    expect(find.text(AiMediaReviewLabels.retryButton), findsOneWidget);
    expect(
      find.bySemanticsLabel(AiMediaReviewFailure.offline().spokenMessage),
      findsWidgets,
    );
    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(inspection!.serialNumber, isNull);
  });

  testWidgets(
    'successful recording updates the review UI with decoded frames',
    (tester) async {
      useTallViewport(tester);
      final id = await openDraft();
      final capture = FakeWalkaroundVideoCapture(
        video: sampleWalkaroundVideo(
          localPath: '/cache/ui-walkaround.mp4',
          frameCount: 3,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AiMediaReviewScreen(
            companyId: 'company-a',
            inspectionId: id,
            userId: 'user-1',
            aiService: ai,
            inspections: workspace.inspections,
            inspectionMedia: workspace.inspectionMedia,
            videoCapture: capture,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No walkaround video (optional)'),
        findsOneWidget,
      );

      await tester.tap(find.text(AiMediaReviewLabels.recordVideoButton));
      await tester.pumpAndSettle();

      expect(capture.recordCallCount, 1);
      expect(
        find.textContaining('No walkaround video (optional)'),
        findsNothing,
      );
      expect(
        find.textContaining('3 extracted walkaround frames'),
        findsOneWidget,
      );
      final analyze = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AiMediaReviewLabels.analyzeButton),
      );
      expect(analyze.onPressed, isNotNull);
    },
  );

  testWidgets(
    'cancelled recording leaves a previous walkaround on the review screen',
    (tester) async {
      useTallViewport(tester);
      final id = await openDraft();
      final kept = sampleWalkaroundVideo(
        localPath: '/cache/kept-ui.mp4',
        frameCount: 2,
      );
      final capture = FakeWalkaroundVideoCapture(
        queued: [
          WalkaroundCaptureOutcome.success(kept),
          WalkaroundCaptureOutcome.cancelled(),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AiMediaReviewScreen(
            companyId: 'company-a',
            inspectionId: id,
            userId: 'user-1',
            aiService: ai,
            inspections: workspace.inspections,
            inspectionMedia: workspace.inspectionMedia,
            videoCapture: capture,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AiMediaReviewLabels.recordVideoButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AiMediaReviewLabels.recordVideoButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('2 extracted walkaround frames'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No walkaround video (optional)'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'decode failure keeps previous frames and shows a non-destructive error',
    (tester) async {
      useTallViewport(tester);
      final id = await openDraft();
      final kept = sampleWalkaroundVideo(
        localPath: '/cache/kept-decode.mp4',
        frameCount: 2,
      );
      final capture = FakeWalkaroundVideoCapture(
        queued: [
          WalkaroundCaptureOutcome.success(kept),
          WalkaroundCaptureOutcome.failed(
            AiMediaReviewFailure.videoFramesMissing(),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AiMediaReviewScreen(
            companyId: 'company-a',
            inspectionId: id,
            userId: 'user-1',
            aiService: ai,
            inspections: workspace.inspections,
            inspectionMedia: workspace.inspectionMedia,
            videoCapture: capture,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AiMediaReviewLabels.recordVideoButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AiMediaReviewLabels.recordVideoButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('2 extracted walkaround frames'),
        findsOneWidget,
      );
      expect(find.text('Frames missing'), findsOneWidget);
      final analyze = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AiMediaReviewLabels.analyzeButton),
      );
      expect(analyze.onPressed, isNotNull);
    },
  );
}
