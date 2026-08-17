import 'package:flutter/foundation.dart';

import '../entities/inspection.dart';
import '../entities/inspection_media.dart';
import '../entities/inspection_photo_slot.dart';
import '../repositories/local_inspection_media_repository.dart';
import '../repositories/local_inspection_repository.dart';
import 'ai_media_analysis_request.dart';
import 'ai_media_review_failure.dart';
import 'ai_media_review_state.dart';
import 'ai_media_source.dart';
import 'ai_service.dart';
import 'ai_suggestion.dart';
import 'ai_suggestion_applier.dart';
import 'ai_suggestion_kind.dart';
import 'video_frame_extraction.dart';
import 'walkaround_video.dart';
import 'walkaround_video_capture_port.dart';

// Public constructor names (`aiService`, `inspections`, `inspectionMedia`)
// are kept for call sites.
// ignore_for_file: prefer_initializing_formals

/// Orchestrates optional AI media review without mutating inspection data
/// until the user explicitly applies a suggestion.
class AiMediaReviewController extends ChangeNotifier {
  AiMediaReviewController({
    required this.companyId,
    required this.inspectionId,
    required this.userId,
    required AIService aiService,
    required LocalInspectionRepository inspections,
    required LocalInspectionMediaRepository inspectionMedia,
    WalkaroundVideoCapturePort? videoCapture,
    AiSuggestionApplier? applier,
  }) : _aiService = aiService,
       _inspections = inspections,
       _inspectionMedia = inspectionMedia,
       _videoCapture =
           videoCapture ?? const UnsupportedWalkaroundVideoCapture(),
       _applier = applier ?? AiSuggestionApplier(inspections: inspections);

  final String companyId;
  final String inspectionId;
  final String userId;
  final AIService _aiService;
  final LocalInspectionRepository _inspections;
  final LocalInspectionMediaRepository _inspectionMedia;
  final WalkaroundVideoCapturePort _videoCapture;
  final AiSuggestionApplier _applier;

  AiMediaReviewViewState _state = const AiMediaReviewViewState(
    phase: AiMediaReviewPhase.ready,
  );
  Inspection? _inspection;
  List<InspectionMedia> _photos = const [];
  WalkaroundVideo? _walkaround;
  AiAnalysisCancelToken? _cancelToken;
  int _analysisGeneration = 0;

  /// Last request actually sent (tests assert it never includes video bytes).
  AiMediaAnalysisRequest? lastRequest;

  AiMediaReviewViewState get state => _state;
  Inspection? get inspection => _inspection;
  WalkaroundVideo? get walkaroundVideo => _walkaround;
  WalkaroundVideoCapturePort get videoCapture => _videoCapture;

  Future<void> load() async {
    final inspection = await _inspections.getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }
    final media = await _inspectionMedia.listForInspection(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    _inspection = inspection;
    _photos = media
        .where((item) => InspectionPhotoSlot.requiredSlots.contains(item.slot))
        .toList(growable: false);
    _emitReady(announcement: _readyAnnouncement());
  }

  Future<void> recordWalkaroundVideo() async {
    if (!_videoCapture.isSupported) {
      _setFailure(
        AiMediaReviewFailure.providerFailure(
          'Walkaround video capture is not available on this device. '
          'You can still analyze inspection photos.',
        ),
      );
      return;
    }
    final recorded = await _videoCapture.recordWalkaround();
    if (recorded.exceedsMaxDuration) {
      _walkaround = null;
      _setFailure(AiMediaReviewFailure.videoTooLong());
      return;
    }
    try {
      VideoFrameExtraction.extractBoundedFrames(recorded);
    } on AiMediaReviewException catch (error) {
      _walkaround = null;
      _setFailure(error.failure);
      return;
    }
    _walkaround = recorded;
    _emitReady(
      announcement:
          'Walkaround video saved on this device. Frame-based review will '
          'send ${VideoFrameExtraction.boundFrames(recorded.representativeFrames).length} '
          'extracted frames, not the original video.',
    );
  }

  void clearWalkaroundVideo() {
    _walkaround = null;
    _emitReady(
      announcement: 'Walkaround video removed. Original file was not uploaded.',
    );
  }

  Future<void> analyzeMediaOnline() async {
    if (_state.isBusy) return;
    if (_photos.isEmpty) {
      _setFailure(AiMediaReviewFailure.noMedia());
      return;
    }

    final generation = ++_analysisGeneration;
    final token = AiAnalysisCancelToken();
    _cancelToken = token;
    _state = AiMediaReviewViewState(
      phase: AiMediaReviewPhase.uploading,
      photoCount: _photos.length,
      hasWalkaroundVideo: _walkaround != null,
      videoFrameCount: _walkaround == null
          ? 0
          : VideoFrameExtraction.boundFrames(
              _walkaround!.representativeFrames,
            ).length,
      videoDuration: _walkaround?.duration,
      statusAnnouncement:
          'Uploading selected images and extracted video frames for AI '
          'analysis. Inspection data is unchanged until you apply a suggestion.',
    );
    notifyListeners();

    try {
      final request = await _buildRequest();
      if (token.isCancelled || generation != _analysisGeneration) {
        return;
      }
      lastRequest = request;
      if (request.containsOriginalVideo) {
        throw StateError('Original walkaround video must never be uploaded.');
      }
      final result = await _aiService.analyzeInspectionMedia(
        request,
        cancelToken: token,
      );
      if (token.isCancelled || generation != _analysisGeneration) {
        return;
      }
      _state = AiMediaReviewViewState(
        phase: AiMediaReviewPhase.results,
        photoCount: _photos.length,
        hasWalkaroundVideo: _walkaround != null,
        videoFrameCount: request.videoFrames.length,
        videoDuration: _walkaround?.duration,
        result: result,
        statusAnnouncement:
            'AI suggestions available. ${result.suggestions.length} items for '
            'human review. Nothing was written to the inspection yet.',
      );
      notifyListeners();
    } on AiMediaReviewException catch (error) {
      if (token.isCancelled || generation != _analysisGeneration) return;
      _setFailure(error.failure);
    } catch (_) {
      if (token.isCancelled || generation != _analysisGeneration) return;
      _setFailure(AiMediaReviewFailure.providerFailure());
    }
  }

  void cancelAnalysis() {
    if (!_state.isBusy) return;
    _analysisGeneration += 1;
    _cancelToken?.cancel();
    _cancelToken = null;
    _state = AiMediaReviewViewState(
      phase: AiMediaReviewPhase.cancelled,
      photoCount: _photos.length,
      hasWalkaroundVideo: _walkaround != null,
      videoFrameCount: _frameCount,
      videoDuration: _walkaround?.duration,
      result: _state.result,
      failure: AiMediaReviewFailure.cancelled(),
      statusAnnouncement: AiMediaReviewFailure.cancelled().spokenMessage,
    );
    notifyListeners();
  }

  Future<AiApplyOutcome> applySuggestion(
    String suggestionId, {
    bool replaceExisting = false,
    String? editedValue,
  }) async {
    final current = _requirePending(suggestionId);
    if (current == null) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion:
            _suggestionById(suggestionId) ??
            AiSuggestion(
              id: suggestionId,
              kind: AiSuggestionKind.unreadableOrUncertain,
              confidence: AiSuggestionConfidence.low,
              source: const AiMediaSource(
                type: AiMediaSourceType.photo,
                label: 'Unknown',
              ),
            ),
        message: 'That suggestion is no longer pending.',
      );
    }
    final inspection = await _reloadInspection();
    final outcome = await _applier.apply(
      companyId: companyId,
      inspectionId: inspectionId,
      userId: userId,
      inspection: inspection,
      suggestion: current,
      replaceExisting: replaceExisting,
      editedValue: editedValue,
    );
    if (outcome.status == AiApplyStatus.applied) {
      _inspection = outcome.inspection ?? inspection;
      _replaceSuggestion(outcome.suggestion);
    }
    return outcome;
  }

  Future<AiApplyOutcome> dismissSuggestion(String suggestionId) async {
    final current = _requirePending(suggestionId);
    if (current == null) {
      return AiApplyOutcome(
        status: AiApplyStatus.rejected,
        suggestion:
            _suggestionById(suggestionId) ??
            AiSuggestion(
              id: suggestionId,
              kind: AiSuggestionKind.unreadableOrUncertain,
              confidence: AiSuggestionConfidence.low,
              source: const AiMediaSource(
                type: AiMediaSourceType.photo,
                label: 'Unknown',
              ),
            ),
        message: 'That suggestion is no longer pending.',
      );
    }
    final before = _inspection;
    final outcome = await _applier.dismiss(current);
    _replaceSuggestion(outcome.suggestion);
    _inspection = before;
    return outcome;
  }

  void editSuggestion(String suggestionId, String editedValue) {
    final current = _suggestionById(suggestionId);
    if (current == null || !current.isPending) return;
    _replaceSuggestion(current.copyWith(editedValue: editedValue));
  }

  Future<AiMediaAnalysisRequest> buildRequestForTest() => _buildRequest();

  int get _frameCount {
    final video = _walkaround;
    if (video == null) return 0;
    return VideoFrameExtraction.boundFrames(video.representativeFrames).length;
  }

  Future<Inspection> _reloadInspection() async {
    final inspection = await _inspections.getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }
    _inspection = inspection;
    return inspection;
  }

  Future<AiMediaAnalysisRequest> _buildRequest() async {
    final images = <AiMediaImage>[];
    for (final photo in _photos) {
      final captured = await _inspectionMedia.loadCapturedImage(
        companyId: companyId,
        media: photo,
      );
      images.add(
        AiMediaImage(
          id: photo.id,
          role: AiMediaImageRole.inspectionPhoto,
          image: captured,
          label: photo.slot.label,
          slot: photo.slot,
        ),
      );
    }
    final video = _walkaround;
    if (video != null) {
      final frames = VideoFrameExtraction.extractBoundedFrames(video);
      for (var i = 0; i < frames.length; i++) {
        images.add(
          AiMediaImage(
            id: 'walkaround-frame-$i',
            role: AiMediaImageRole.videoFrame,
            image: frames[i],
            label: 'Walkaround video frame ${i + 1}',
            frameIndex: i,
          ),
        );
      }
    }
    if (images.isEmpty) {
      throw AiMediaReviewException(AiMediaReviewFailure.noMedia());
    }
    return AiMediaAnalysisRequest(
      companyId: companyId,
      inspectionId: inspectionId,
      images: List<AiMediaImage>.unmodifiable(
        images.take(AiMediaAnalysisRequest.maxImageCount),
      ),
      includesVideoFrames: video != null,
    );
  }

  AiSuggestion? _suggestionById(String id) {
    final result = _state.result;
    if (result == null) return null;
    for (final suggestion in result.suggestions) {
      if (suggestion.id == id) return suggestion;
    }
    return null;
  }

  AiSuggestion? _requirePending(String id) {
    final suggestion = _suggestionById(id);
    if (suggestion == null || !suggestion.isPending) return null;
    return suggestion;
  }

  void _replaceSuggestion(AiSuggestion next) {
    final result = _state.result;
    if (result == null) return;
    final suggestions = [
      for (final item in result.suggestions)
        if (item.id == next.id) next else item,
    ];
    _state = AiMediaReviewViewState(
      phase: AiMediaReviewPhase.results,
      photoCount: _photos.length,
      hasWalkaroundVideo: _walkaround != null,
      videoFrameCount: _frameCount,
      videoDuration: _walkaround?.duration,
      result: result.withSuggestions(suggestions),
      statusAnnouncement: _state.statusAnnouncement,
    );
    notifyListeners();
  }

  void _setFailure(AiMediaReviewFailure failure) {
    final phase = switch (failure.kind) {
      AiMediaReviewFailureKind.offline => AiMediaReviewPhase.offline,
      AiMediaReviewFailureKind.cancelled => AiMediaReviewPhase.cancelled,
      AiMediaReviewFailureKind.timeout ||
      AiMediaReviewFailureKind.providerFailure ||
      AiMediaReviewFailureKind.malformedResponse =>
        AiMediaReviewPhase.providerFailure,
      AiMediaReviewFailureKind.noMedia ||
      AiMediaReviewFailureKind.videoTooLong ||
      AiMediaReviewFailureKind.videoFramesMissing => AiMediaReviewPhase.ready,
    };
    _state = AiMediaReviewViewState(
      phase: phase,
      photoCount: _photos.length,
      hasWalkaroundVideo: _walkaround != null,
      videoFrameCount: _frameCount,
      videoDuration: _walkaround?.duration,
      result: _state.result,
      failure: failure,
      statusAnnouncement: failure.spokenMessage,
    );
    notifyListeners();
  }

  void _emitReady({String? announcement}) {
    _state = AiMediaReviewViewState(
      phase: AiMediaReviewPhase.ready,
      photoCount: _photos.length,
      hasWalkaroundVideo: _walkaround != null,
      videoFrameCount: _frameCount,
      videoDuration: _walkaround?.duration,
      result: _state.result,
      statusAnnouncement: announcement ?? _readyAnnouncement(),
    );
    notifyListeners();
  }

  String _readyAnnouncement() {
    if (_photos.isEmpty) {
      return 'AI media review is optional. Capture inspection photos first. '
          'Quick Appraisal works offline without AI.';
    }
    final video = _walkaround;
    if (video == null) {
      return 'Ready to analyze ${_photos.length} inspection photos online. '
          'Nothing will be sent until you choose Analyze media online.';
    }
    return 'Ready to analyze ${_photos.length} photos and $_frameCount '
        'walkaround frames. The original video stays on this device.';
  }
}
