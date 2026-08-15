import 'camera_permission_port.dart';
import 'captured_image.dart';
import 'confirmed_equipment_id_value.dart';
import 'equipment_id_candidate.dart';
import 'equipment_id_capture_failure.dart';
import 'equipment_id_capture_kind.dart';
import 'equipment_id_capture_method.dart';
import 'hour_meter_field_extractor.dart';
import 'hour_meter_parser.dart';
import 'image_capture_port.dart';
import 'recognized_text_block.dart';
import 'serial_field_extractor.dart';
import 'serial_normalizer.dart';
import 'text_recognition_port.dart';

/// High-level UI phase for equipment identification capture.
enum EquipmentIdCapturePhase {
  ready,
  requestingPermission,
  capturing,
  recognizing,
  awaitingConfirmation,
  confirmed,
  failed,
}

/// Immutable view-model for the reusable capture panel.
class EquipmentIdCaptureState {
  const EquipmentIdCaptureState({
    required this.kind,
    required this.phase,
    required this.draftValue,
    required this.candidates,
    required this.cameraOcrSupported,
    this.selectedCandidateId,
    this.failure,
    this.confirmed,
    this.lastCapturedImage,
    this.statusMessage,
  });

  final EquipmentIdCaptureKind kind;
  final EquipmentIdCapturePhase phase;
  final String draftValue;
  final List<EquipmentIdCandidate> candidates;
  final bool cameraOcrSupported;
  final String? selectedCandidateId;
  final EquipmentIdCaptureFailure? failure;
  final ConfirmedEquipmentIdValue? confirmed;
  final CapturedImage? lastCapturedImage;
  final String? statusMessage;

  bool get isConfirmed =>
      phase == EquipmentIdCapturePhase.confirmed && confirmed != null;

  bool get canConfirm {
    if (kind == EquipmentIdCaptureKind.serialNumber) {
      return SerialNormalizer().normalizeForStorage(draftValue).isNotEmpty;
    }
    return const HourMeterParser().parse(draftValue) != null;
  }

  EquipmentIdCaptureState copyWith({
    EquipmentIdCapturePhase? phase,
    String? draftValue,
    List<EquipmentIdCandidate>? candidates,
    String? selectedCandidateId,
    bool clearSelectedCandidate = false,
    EquipmentIdCaptureFailure? failure,
    bool clearFailure = false,
    ConfirmedEquipmentIdValue? confirmed,
    bool clearConfirmed = false,
    CapturedImage? lastCapturedImage,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return EquipmentIdCaptureState(
      kind: kind,
      phase: phase ?? this.phase,
      draftValue: draftValue ?? this.draftValue,
      candidates: candidates ?? this.candidates,
      cameraOcrSupported: cameraOcrSupported,
      selectedCandidateId: clearSelectedCandidate
          ? null
          : (selectedCandidateId ?? this.selectedCandidateId),
      failure: clearFailure ? null : (failure ?? this.failure),
      confirmed: clearConfirmed ? null : (confirmed ?? this.confirmed),
      lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }
}

/// Testable capture orchestrator: permissions → capture → OCR → candidates →
/// explicit confirmation. Never silently accepts OCR output.
class EquipmentIdCaptureController {
  EquipmentIdCaptureController({
    required EquipmentIdCaptureKind kind,
    required ImageCapturePort imageCapture,
    required TextRecognitionPort textRecognition,
    required this.cameraPermission,
    this.serialNormalizer = const SerialNormalizer(),
    this.hourMeterParser = const HourMeterParser(),
    this.serialExtractor = const SerialFieldExtractor(),
    this.hourExtractor = const HourMeterFieldExtractor(),
    String initialDraftValue = '',
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) : _imageCapture = imageCapture,
       _textRecognition = textRecognition,
       _lastSaved = initialConfirmed,
       _state = _initialState(
         kind: kind,
         imageCapture: imageCapture,
         textRecognition: textRecognition,
         initialDraftValue: initialDraftValue,
         initialConfirmed: initialConfirmed,
       );

  static EquipmentIdCaptureState _initialState({
    required EquipmentIdCaptureKind kind,
    required ImageCapturePort imageCapture,
    required TextRecognitionPort textRecognition,
    required String initialDraftValue,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    final cameraOcrSupported =
        imageCapture.isSupported && textRecognition.isSupported;
    if (initialConfirmed != null) {
      if (initialConfirmed.kind != kind) {
        throw ArgumentError.value(
          initialConfirmed.kind,
          'initialConfirmed.kind',
          'must match controller kind $kind',
        );
      }
      return EquipmentIdCaptureState(
        kind: kind,
        phase: EquipmentIdCapturePhase.confirmed,
        draftValue: initialConfirmed.value,
        candidates: const [],
        cameraOcrSupported: cameraOcrSupported,
        confirmed: initialConfirmed,
        statusMessage: kind == EquipmentIdCaptureKind.serialNumber
            ? 'Serial number saved to this inspection draft.'
            : 'Hour meter reading saved to this inspection draft.',
      );
    }
    return EquipmentIdCaptureState(
      kind: kind,
      phase: EquipmentIdCapturePhase.ready,
      draftValue: initialDraftValue,
      candidates: const [],
      cameraOcrSupported: cameraOcrSupported,
    );
  }

  final ImageCapturePort _imageCapture;
  final TextRecognitionPort _textRecognition;
  final CameraPermissionPort cameraPermission;
  final SerialNormalizer serialNormalizer;
  final HourMeterParser hourMeterParser;
  final SerialFieldExtractor serialExtractor;
  final HourMeterFieldExtractor hourExtractor;

  ConfirmedEquipmentIdValue? _lastSaved;

  EquipmentIdCaptureState _state;
  EquipmentIdCaptureState get state => _state;

  final List<void Function(EquipmentIdCaptureState)> _listeners = [];

  void addListener(void Function(EquipmentIdCaptureState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(EquipmentIdCaptureState) listener) {
    _listeners.remove(listener);
  }

  void _emit(EquipmentIdCaptureState next) {
    _state = next;
    for (final listener in List.of(_listeners)) {
      listener(_state);
    }
  }

  /// Updates the always-visible manual field. Clears confirmation.
  void updateManualEntry(String value) {
    final matchesSelected =
        _state.selectedCandidateId != null &&
        _state.candidates.any(
          (c) => c.id == _state.selectedCandidateId && c.displayValue == value,
        );

    _emit(
      _state.copyWith(
        draftValue: value,
        phase: EquipmentIdCapturePhase.awaitingConfirmation,
        clearConfirmed: true,
        clearSelectedCandidate: !matchesSelected,
        clearFailure: true,
        clearStatusMessage: true,
        statusMessage:
            'Finish editing to save. Detected text is never saved '
            'automatically.',
      ),
    );
  }

  /// Highlights a candidate, copies it into the draft, and immediately
  /// confirms it. The tap is the explicit human confirmation.
  ///
  /// Does not persist by itself — the panel / workspace writes the local
  /// draft after this returns true.
  bool selectCandidate(String candidateId) {
    EquipmentIdCandidate? selected;
    for (final candidate in _state.candidates) {
      if (candidate.id == candidateId) {
        selected = candidate;
        break;
      }
    }
    if (selected == null) return false;

    _emit(
      _state.copyWith(
        selectedCandidateId: selected.id,
        draftValue: selected.displayValue,
        clearConfirmed: true,
        clearFailure: true,
        statusMessage: 'Saving selected value to this inspection draft.',
      ),
    );
    return confirm();
  }

  /// Saves the current manual draft when editing is completed.
  ///
  /// Returns `false` when the draft is invalid (previous saved value is
  /// restored) or when the draft already matches the last saved value.
  bool completeManualEntry() {
    final normalizedDraft = _normalizedDraft(_state.draftValue);
    if (normalizedDraft == null) {
      _restoreLastSaved(
        statusMessage:
            'That value is not valid. The previous saved value '
            'was kept. Enter a valid value to replace it.',
      );
      return false;
    }
    if (_state.isConfirmed &&
        _state.confirmed != null &&
        _sameStoredValue(_state.confirmed!, normalizedDraft)) {
      return false;
    }
    if (_lastSaved != null && _sameStoredValue(_lastSaved!, normalizedDraft)) {
      _restoreLastSaved();
      return false;
    }

    _emit(_state.copyWith(clearSelectedCandidate: true, clearFailure: true));
    return confirm();
  }

  /// Records that [state.confirmed] was persisted to the local draft.
  void markSaved() {
    if (_state.confirmed == null) return;
    _lastSaved = _state.confirmed;
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.confirmed,
        statusMessage: _state.kind == EquipmentIdCaptureKind.serialNumber
            ? 'Serial number saved to this inspection draft.'
            : 'Hour meter reading saved to this inspection draft.',
        clearFailure: true,
      ),
    );
  }

  /// Restores the last persisted value after a save failure.
  void revertToLastSaved(EquipmentIdCaptureFailure failure) {
    _restoreLastSaved(failure: failure);
  }

  bool get isAlreadySaved {
    final confirmed = _state.confirmed;
    if (confirmed == null || _lastSaved == null) return false;
    return _sameStoredValue(confirmed, confirmed.value) &&
        _sameStoredValue(_lastSaved!, confirmed.value);
  }

  /// Explicit human confirmation of the current draft value.
  bool confirm() {
    if (!_state.canConfirm) return false;

    final method =
        _state.selectedCandidateId != null &&
            _state.candidates.any(
              (c) =>
                  c.id == _state.selectedCandidateId &&
                  c.displayValue == _state.draftValue,
            )
        ? EquipmentIdCaptureMethod.ocrConfirmed
        : EquipmentIdCaptureMethod.manual;

    if (_state.kind == EquipmentIdCaptureKind.serialNumber) {
      final normalized = serialNormalizer.normalizeForStorage(
        _state.draftValue,
      );
      if (normalized.isEmpty) return false;
      final confirmed = ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: normalized,
        method: method,
      );
      _emit(
        _state.copyWith(
          draftValue: normalized,
          phase: EquipmentIdCapturePhase.confirmed,
          confirmed: confirmed,
          clearFailure: true,
          statusMessage: 'Serial number saved to this inspection draft.',
        ),
      );
      return true;
    }

    final hours = hourMeterParser.parse(_state.draftValue);
    if (hours == null || hours < 0) return false;
    final display = hourMeterParser.formatHours(hours);
    final confirmed = ConfirmedEquipmentIdValue(
      kind: EquipmentIdCaptureKind.hourMeter,
      value: display,
      method: method,
      hours: hours,
    );
    _emit(
      _state.copyWith(
        draftValue: display,
        phase: EquipmentIdCapturePhase.confirmed,
        confirmed: confirmed,
        clearFailure: true,
        statusMessage: 'Hour meter reading saved to this inspection draft.',
      ),
    );
    return true;
  }

  /// Clears the in-progress confirmation chrome so the user can revise.
  /// The last persisted value is kept until a replacement is saved.
  void clearConfirmation() {
    if (!_state.isConfirmed) return;
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.awaitingConfirmation,
        clearConfirmed: true,
        statusMessage:
            'Saved value kept. Edit or tap a replacement to change it.',
      ),
    );
  }

  /// Runs OCR against an already-captured image (required photo reuse).
  ///
  /// Does not open the camera. Preserves draft/confirmed values on failure.
  /// Never silently confirms OCR output.
  Future<void> recognizeExistingImage(CapturedImage image) async {
    final preservedDraft = _state.draftValue;
    final preservedConfirmed = _lastSaved ?? _state.confirmed;

    if (!_textRecognition.isSupported) {
      _emitRecognizeFailure(
        EquipmentIdCaptureFailure.unsupportedPlatform(),
        preservedDraft: preservedDraft,
        preservedConfirmed: preservedConfirmed,
        image: image,
      );
      return;
    }

    if (image.isEmpty) {
      _emitRecognizeFailure(
        EquipmentIdCaptureFailure.cameraUnavailable(),
        preservedDraft: preservedDraft,
        preservedConfirmed: preservedConfirmed,
      );
      return;
    }

    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.recognizing,
        lastCapturedImage: image,
        draftValue: preservedDraft,
        confirmed: preservedConfirmed,
        clearFailure: true,
        clearStatusMessage: true,
      ),
    );

    late final List<RecognizedTextBlock> blocks;
    try {
      blocks = await _textRecognition.recognize(image);
    } catch (error) {
      _emitRecognizeFailure(
        EquipmentIdCaptureFailure.ocrFailure(error.toString()),
        preservedDraft: preservedDraft,
        preservedConfirmed: preservedConfirmed,
        image: image,
      );
      return;
    }

    if (blocks.isEmpty) {
      _emitRecognizeFailure(
        EquipmentIdCaptureFailure.noTextDetected(),
        preservedDraft: preservedDraft,
        preservedConfirmed: preservedConfirmed,
        image: image,
      );
      return;
    }

    _presentOcrResults(
      _buildCandidates(blocks),
      preservedDraft: preservedDraft,
      preservedConfirmed: preservedConfirmed,
      image: image,
    );
  }

  void _emitRecognizeFailure(
    EquipmentIdCaptureFailure failure, {
    required String preservedDraft,
    ConfirmedEquipmentIdValue? preservedConfirmed,
    CapturedImage? image,
  }) {
    final saved = preservedConfirmed ?? _lastSaved;
    if (saved != null) {
      _emit(
        _state.copyWith(
          phase: EquipmentIdCapturePhase.confirmed,
          failure: failure,
          draftValue: saved.value,
          confirmed: saved,
          lastCapturedImage: image,
          statusMessage: failure.message,
        ),
      );
      return;
    }
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.failed,
        failure: failure,
        draftValue: preservedDraft,
        clearConfirmed: true,
        lastCapturedImage: image,
        statusMessage: failure.message,
      ),
    );
  }

  /// Runs permission → capture → OCR → candidate presentation.
  Future<void> captureAndRecognize() async {
    final preservedDraft = _state.draftValue;
    final preservedConfirmed = _lastSaved ?? _state.confirmed;

    if (!_imageCapture.isSupported || !_textRecognition.isSupported) {
      _emitRecognizeFailure(
        EquipmentIdCaptureFailure.unsupportedPlatform(),
        preservedDraft: preservedDraft,
        preservedConfirmed: preservedConfirmed,
      );
      return;
    }

    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.requestingPermission,
        clearFailure: true,
        clearStatusMessage: true,
        draftValue: preservedDraft,
        confirmed: preservedConfirmed,
      ),
    );

    final permission = await cameraPermission.request();
    if (permission == CameraPermissionStatus.denied) {
      _fail(EquipmentIdCaptureFailure.permissionDenied(), preservedDraft);
      return;
    }
    if (permission == CameraPermissionStatus.permanentlyDenied ||
        permission == CameraPermissionStatus.restricted) {
      _fail(
        EquipmentIdCaptureFailure.permissionPermanentlyDenied(),
        preservedDraft,
      );
      return;
    }
    if (permission == CameraPermissionStatus.unavailable) {
      _fail(EquipmentIdCaptureFailure.cameraUnavailable(), preservedDraft);
      return;
    }

    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.capturing,
        draftValue: preservedDraft,
        confirmed: preservedConfirmed,
      ),
    );

    late final CapturedImage image;
    try {
      image = await _imageCapture.captureStill();
    } on EquipmentIdCaptureException catch (error) {
      _fail(error.failure, preservedDraft);
      return;
    } catch (_) {
      _fail(EquipmentIdCaptureFailure.cameraUnavailable(), preservedDraft);
      return;
    }

    if (image.isEmpty) {
      _fail(EquipmentIdCaptureFailure.cameraUnavailable(), preservedDraft);
      return;
    }

    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.recognizing,
        lastCapturedImage: image,
        draftValue: preservedDraft,
        confirmed: preservedConfirmed,
      ),
    );

    late final List<RecognizedTextBlock> blocks;
    try {
      blocks = await _textRecognition.recognize(image);
    } catch (error) {
      _fail(
        EquipmentIdCaptureFailure.ocrFailure(error.toString()),
        preservedDraft,
        image: image,
      );
      return;
    }

    if (blocks.isEmpty) {
      _fail(
        EquipmentIdCaptureFailure.noTextDetected(),
        preservedDraft,
        image: image,
      );
      return;
    }

    _presentOcrResults(
      _buildCandidates(blocks),
      preservedDraft: preservedDraft,
      preservedConfirmed: preservedConfirmed,
      image: image,
    );
  }

  void _presentOcrResults(
    List<EquipmentIdCandidate> candidates, {
    required String preservedDraft,
    ConfirmedEquipmentIdValue? preservedConfirmed,
    required CapturedImage image,
  }) {
    final saved = preservedConfirmed ?? _lastSaved;
    final hasRecommended = candidates.any((c) => c.isRecommended);
    final status = () {
      final kept = saved == null ? '' : ' Saved value was kept.';
      if (candidates.isEmpty) {
        return 'No clear reading. Enter the value manually. Detected text '
            'is never saved automatically.$kept';
      }
      if (hasRecommended) {
        return 'Tap the recommended value to save it. Detected text is '
            'never saved automatically.$kept';
      }
      return 'No clear reading. Other possibilities are listed, or enter '
          'the value manually.$kept';
    }();

    _emit(
      _state.copyWith(
        phase: saved != null
            ? EquipmentIdCapturePhase.confirmed
            : EquipmentIdCapturePhase.awaitingConfirmation,
        draftValue: saved?.value ?? preservedDraft,
        candidates: candidates,
        confirmed: saved,
        clearConfirmed: saved == null,
        lastCapturedImage: image,
        clearFailure: true,
        statusMessage: status,
      ),
    );
  }

  List<EquipmentIdCandidate> _buildCandidates(
    List<RecognizedTextBlock> blocks,
  ) {
    final texts = blocks.map((b) => b.rawText);
    if (_state.kind == EquipmentIdCaptureKind.serialNumber) {
      final extraction = serialExtractor.extract(texts);
      return [
        for (var i = 0; i < extraction.visibleCandidates.length; i++)
          EquipmentIdCandidate(
            id: 'serial-$i',
            displayValue: extraction.visibleCandidates[i].value,
            sourceRawText: extraction.visibleCandidates[i].sourceRawText,
            isRecommended:
                extraction.recommended != null &&
                i == 0 &&
                extraction.visibleCandidates[i].value ==
                    extraction.recommended!.value,
            confidence: extraction.visibleCandidates[i].confidence,
            hasAmbiguousCharacters:
                extraction.visibleCandidates[i].hasAmbiguousCharacters,
          ),
      ];
    }

    final extraction = hourExtractor.extract(texts);
    return [
      for (var i = 0; i < extraction.visibleCandidates.length; i++)
        EquipmentIdCandidate(
          id: 'hours-$i',
          displayValue: extraction.visibleCandidates[i].displayValue,
          hours: extraction.visibleCandidates[i].hours,
          sourceRawText: extraction.visibleCandidates[i].sourceRawText,
          isRecommended:
              extraction.recommended != null &&
              i == 0 &&
              extraction.visibleCandidates[i].displayValue ==
                  extraction.recommended!.displayValue,
          confidence: i == 0 && extraction.recommended != null
              ? HourMeterFieldExtractor.labelledScore
              : HourMeterFieldExtractor.alternativeThreshold,
        ),
    ];
  }

  void _fail(
    EquipmentIdCaptureFailure failure,
    String preservedDraft, {
    CapturedImage? image,
  }) {
    final saved = _lastSaved;
    if (saved != null) {
      _emit(
        _state.copyWith(
          phase: EquipmentIdCapturePhase.confirmed,
          failure: failure,
          draftValue: saved.value,
          confirmed: saved,
          lastCapturedImage: image,
          statusMessage: failure.message,
        ),
      );
      return;
    }
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.failed,
        failure: failure,
        draftValue: preservedDraft,
        clearConfirmed: true,
        lastCapturedImage: image,
        statusMessage: failure.message,
      ),
    );
  }

  String? _normalizedDraft(String draft) {
    if (_state.kind == EquipmentIdCaptureKind.serialNumber) {
      final normalized = serialNormalizer.normalizeForStorage(draft);
      return normalized.isEmpty ? null : normalized;
    }
    final hours = hourMeterParser.parse(draft);
    if (hours == null || hours < 0) return null;
    return hourMeterParser.formatHours(hours);
  }

  bool _sameStoredValue(ConfirmedEquipmentIdValue saved, String normalized) {
    if (saved.kind == EquipmentIdCaptureKind.hourMeter) {
      final hours = hourMeterParser.parse(normalized);
      return hours != null && saved.hours == hours;
    }
    return saved.value == normalized;
  }

  void _restoreLastSaved({
    EquipmentIdCaptureFailure? failure,
    String? statusMessage,
  }) {
    final saved = _lastSaved;
    if (saved == null) {
      _emit(
        _state.copyWith(
          phase: EquipmentIdCapturePhase.failed,
          failure: failure,
          clearConfirmed: true,
          statusMessage: statusMessage ?? failure?.message,
        ),
      );
      return;
    }
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.confirmed,
        confirmed: saved,
        draftValue: saved.value,
        failure: failure,
        clearFailure: failure == null,
        statusMessage:
            statusMessage ??
            (failure?.message ??
                (_state.kind == EquipmentIdCaptureKind.serialNumber
                    ? 'Serial number saved to this inspection draft.'
                    : 'Hour meter reading saved to this inspection draft.')),
      ),
    );
  }

  Future<void> dispose() async {
    _listeners.clear();
    await _textRecognition.dispose();
  }
}
