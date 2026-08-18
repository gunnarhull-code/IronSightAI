import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_controller.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_result.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_state.dart';
import 'package:ironsight_ai/domain/ai/ai_media_source.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_applier.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_kind.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_outcome.dart';
import 'package:ironsight_ai/domain/ai/walkaround_video.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';

import '../support/fake_ai_service.dart';
import '../support/fake_auth_session_reader.dart';
import '../support/fake_equipment_repository.dart';
import '../support/fake_walkaround_video_capture.dart';
import '../support/in_memory_inspection_media_file_store.dart';
import '../support/test_images.dart';

const _photo = CapturedImage(
  bytes: kTinyPngBytes,
  path: '/tmp/required.png',
  mimeType: 'image/png',
);

AiMediaReviewResult _result(List<AiSuggestion> suggestions) {
  return AiMediaReviewResult(suggestions: suggestions);
}

AiSuggestion _serialSuggestion() {
  return const AiSuggestion(
    id: 's-serial',
    kind: AiSuggestionKind.serialNumber,
    confidence: AiSuggestionConfidence.medium,
    source: AiMediaSource(
      type: AiMediaSourceType.photo,
      label: 'Serial / data plate',
      slot: InspectionPhotoSlot.serialDataPlate,
    ),
    value: 'SN-AI-1',
  );
}

void main() {
  late OfflineInspectionWorkspace workspace;
  late FakeAIService ai;

  setUp(() {
    ai = FakeAIService(result: _result([_serialSuggestion()]));
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

  Future<String> openDraft({String companyId = 'company-a'}) async {
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: companyId,
      equipment: [
        Equipment(
          id: 'eq-1',
          companyId: companyId,
          assetName: 'Loader',
          manufacturer: 'Cat',
          model: '950',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: companyId,
      equipmentId: 'eq-1',
      createdByUserId: 'user-1',
    );
    return draft.id;
  }

  Future<void> addPhoto(String inspectionId, {String companyId = 'company-a'}) {
    return workspace.inspectionMedia.saveRequiredPhoto(
      companyId: companyId,
      inspectionId: inspectionId,
      slot: InspectionPhotoSlot.serialDataPlate,
      image: _photo,
    );
  }

  AiMediaReviewController controllerFor(
    String inspectionId, {
    String companyId = 'company-a',
    FakeWalkaroundVideoCapture? video,
  }) {
    return AiMediaReviewController(
      companyId: companyId,
      inspectionId: inspectionId,
      userId: 'user-1',
      aiService: ai,
      inspections: workspace.inspections,
      inspectionMedia: workspace.inspectionMedia,
      videoCapture: video ?? FakeWalkaroundVideoCapture(),
    );
  }

  test(
    'does not mutate inspection when analyzing, cancelling, or failing',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'CONFIRMED',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );

      final controller = controllerFor(id);
      await controller.load();
      await controller.analyzeMediaOnline();
      expect(controller.state.phase, AiMediaReviewPhase.results);
      expect(ai.analyzeCallCount, 1);
      expect(ai.lastRequestHadVideoMime, isFalse);
      expect(ai.lastRequest!.containsOriginalVideo, isFalse);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.serialNumber,
        'CONFIRMED',
      );

      ai.error = AiMediaReviewException(AiMediaReviewFailure.offline());
      await controller.analyzeMediaOnline();
      expect(controller.state.phase, AiMediaReviewPhase.offline);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.serialNumber,
        'CONFIRMED',
      );

      ai
        ..error = null
        ..hangUntilCancel = true;
      final pending = controller.analyzeMediaOnline();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phase, AiMediaReviewPhase.uploading);
      controller.cancelAnalysis();
      await pending;
      expect(controller.state.phase, AiMediaReviewPhase.cancelled);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.serialNumber,
        'CONFIRMED',
      );
      controller.dispose();
    },
  );

  test('AIService can be substituted with a fake provider', () async {
    final id = await openDraft();
    await addPhoto(id);
    final controller = controllerFor(id);
    await controller.load();
    await controller.analyzeMediaOnline();
    expect(controller.state.result!.suggestions.single.value, 'SN-AI-1');
    controller.dispose();
  });

  test(
    'records bounded walkaround frames and never uploads the original video',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      final videoPath = '/secret/original-walkaround.mp4';
      final video = FakeWalkaroundVideoCapture(
        video: WalkaroundVideo(
          localPath: videoPath,
          duration: const Duration(seconds: 20),
          representativeFrames: [
            for (var i = 0; i < 8; i++)
              decodedFrame(
                videoPath: videoPath,
                bytes: List<int>.filled(4, i + 1),
                timeOffsetMs: i * 2500,
              ),
          ],
          mimeType: 'video/mp4',
          byteSize: 99999,
        ),
      );
      final controller = controllerFor(id, video: video);
      await controller.load();
      await controller.recordWalkaroundVideo();
      expect(controller.state.videoFrameCount, 6);
      await controller.analyzeMediaOnline();
      final request = ai.lastRequest!;
      expect(request.includesVideoFrames, isTrue);
      expect(request.videoFrames, hasLength(6));
      expect(request.containsOriginalVideo, isFalse);
      expect(
        request.images.every(
          (image) => image.image.mimeType.startsWith('image/'),
        ),
        isTrue,
      );
      expect(request.toString().contains('original-walkaround.mp4'), isFalse);
      controller.dispose();
    },
  );

  test(
    'rejects a walkaround video over 30 seconds without uploading',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      final video = FakeWalkaroundVideoCapture(
        video: WalkaroundVideo(
          localPath: '/tmp/too-long.mp4',
          duration: const Duration(seconds: 31),
          representativeFrames: [
            decodedFrame(
              videoPath: '/tmp/too-long.mp4',
              bytes: const [1, 2, 3],
            ),
          ],
        ),
      );
      final controller = controllerFor(id, video: video);
      await controller.load();
      await controller.recordWalkaroundVideo();
      expect(controller.walkaroundVideo, isNull);
      expect(
        controller.state.failure!.kind,
        AiMediaReviewFailureKind.videoTooLong,
      );
      expect(ai.analyzeCallCount, 0);
      controller.dispose();
    },
  );

  test('applying and dismissing suggestions is per-item', () async {
    final id = await openDraft();
    await addPhoto(id);
    ai.result = _result([
      _serialSuggestion(),
      const AiSuggestion(
        id: 's-rust',
        kind: AiSuggestionKind.rust,
        confidence: AiSuggestionConfidence.low,
        source: AiMediaSource(
          type: AiMediaSourceType.photo,
          label: 'Front-left overview',
          slot: InspectionPhotoSlot.frontLeftOverview,
        ),
        value: 'Surface rust',
      ),
    ]);
    final controller = controllerFor(id);
    await controller.load();
    await controller.analyzeMediaOnline();
    await controller.dismissSuggestion('s-rust');
    final applied = await controller.applySuggestion('s-serial');
    expect(applied.status, AiApplyStatus.applied);
    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(inspection!.serialNumber, 'SN-AI-1');
    expect(inspection.overallNotes, isNull);
    expect(
      controller.state.result!.suggestions
          .firstWhere((item) => item.id == 's-rust')
          .decision,
      AiSuggestionDecision.dismissed,
    );
    controller.dispose();
  });

  test('tenant isolation: company B cannot load company A photos', () async {
    final id = await openDraft();
    await addPhoto(id);
    final other = controllerFor(id, companyId: 'company-b');
    await expectLater(other.load(), throwsA(isA<StateError>()));
  });

  test(
    'provider timeout and malformed responses stay non-destructive',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      final controller = controllerFor(id);
      await controller.load();

      ai.error = AiMediaReviewException(AiMediaReviewFailure.timeout());
      await controller.analyzeMediaOnline();
      expect(controller.state.phase, AiMediaReviewPhase.providerFailure);

      ai.error = AiMediaReviewException(
        AiMediaReviewFailure.malformedResponse(),
      );
      await controller.analyzeMediaOnline();
      expect(controller.state.phase, AiMediaReviewPhase.providerFailure);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.serialNumber,
        isNull,
      );
      controller.dispose();
    },
  );

  test(
    'successful Android recording result updates walkaround state',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      const recordedPath = '/cache/s22-walkaround.mp4';
      final capture = FakeWalkaroundVideoCapture(
        video: sampleWalkaroundVideo(localPath: recordedPath, frameCount: 4),
      );
      final controller = controllerFor(id, video: capture);
      await controller.load();
      expect(controller.state.hasWalkaroundVideo, isFalse);
      expect(controller.state.canAnalyze, isTrue);

      await controller.recordWalkaroundVideo();

      expect(capture.recordCallCount, 1);
      expect(controller.state.hasWalkaroundVideo, isTrue);
      expect(controller.state.videoFrameCount, 4);
      expect(controller.walkaroundVideo!.localPath, recordedPath);
      expect(
        controller.walkaroundVideo!.representativeFrames.every(
          (frame) => frame.originatesFrom(recordedPath),
        ),
        isTrue,
      );
      expect(controller.state.canAnalyze, isTrue);
      controller.dispose();
    },
  );

  test(
    'cancelled recording keeps the previous valid video and frames',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      final first = sampleWalkaroundVideo(
        localPath: '/cache/kept.mp4',
        frameCount: 3,
      );
      final capture = FakeWalkaroundVideoCapture(
        queued: [
          WalkaroundCaptureOutcome.success(first),
          WalkaroundCaptureOutcome.cancelled(),
        ],
      );
      final controller = controllerFor(id, video: capture);
      await controller.load();
      await controller.recordWalkaroundVideo();
      expect(controller.state.videoFrameCount, 3);

      await controller.recordWalkaroundVideo();

      expect(controller.walkaroundVideo, same(first));
      expect(controller.state.hasWalkaroundVideo, isTrue);
      expect(controller.state.videoFrameCount, 3);
      expect(controller.state.failure, isNull);
      controller.dispose();
    },
  );

  test(
    'decode failure keeps the previous video and does not enable a fake one',
    () async {
      final id = await openDraft();
      await addPhoto(id);
      final first = sampleWalkaroundVideo(
        localPath: '/cache/kept.mp4',
        frameCount: 2,
      );
      final capture = FakeWalkaroundVideoCapture(
        queued: [
          WalkaroundCaptureOutcome.success(first),
          WalkaroundCaptureOutcome.failed(
            AiMediaReviewFailure.videoFramesMissing(),
          ),
        ],
      );
      final controller = controllerFor(id, video: capture);
      await controller.load();
      await controller.recordWalkaroundVideo();
      await controller.recordWalkaroundVideo();

      expect(controller.walkaroundVideo, same(first));
      expect(controller.state.hasWalkaroundVideo, isTrue);
      expect(controller.state.videoFrameCount, 2);
      expect(
        controller.state.failure!.kind,
        AiMediaReviewFailureKind.videoFramesMissing,
      );
      expect(controller.state.canAnalyze, isTrue);
      controller.dispose();
    },
  );

  test('analyze stays disabled until photos or decoded frames exist', () async {
    final id = await openDraft();
    final capture = FakeWalkaroundVideoCapture(
      queued: [
        WalkaroundCaptureOutcome.cancelled(),
        WalkaroundCaptureOutcome.success(
          sampleWalkaroundVideo(localPath: '/cache/only-video.mp4'),
        ),
      ],
    );
    final controller = controllerFor(id, video: capture);
    await controller.load();
    expect(controller.state.photoCount, 0);
    expect(controller.state.canAnalyze, isFalse);

    await controller.recordWalkaroundVideo();
    expect(controller.state.canAnalyze, isFalse);

    await controller.recordWalkaroundVideo();
    expect(controller.state.hasWalkaroundVideo, isTrue);
    expect(controller.state.canAnalyze, isTrue);
    controller.dispose();
  });
}
