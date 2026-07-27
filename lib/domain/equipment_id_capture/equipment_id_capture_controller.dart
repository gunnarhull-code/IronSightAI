import 'camera_permission_port.dart';
import 'captured_image.dart';
import 'confirmed_equipment_id_value.dart';
import 'equipment_id_candidate.dart';
import 'equipment_id_capture_failure.dart';
import 'equipment_id_capture_kind.dart';
import 'equipment_id_capture_method.dart';
import 'hour_meter_parser.dart';
import 'image_capture_port.dart';
import 'recognized_text_block.dart';
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
    if (phase == EquipmentIdCapturePhase.confirmed) return false;
    if (kind == EquipmentIdCaptureKind.serialNumber) {
      return SerialNormalizer().normalize(draftValue).isNotEmpty;
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
    String initialDraftValue = '',
  }) : _imageCapture = imageCapture,
       _textRecognition = textRecognition,
       _state = EquipmentIdCaptureState(
         kind: kind,
         phase: EquipmentIdCapturePhase.ready,
         draftValue: initialDraftValue,
         candidates: const [],
         cameraOcrSupported:
             imageCapture.isSupported && textRecognition.isSupported,
       );

  final ImageCapturePort _imageCapture;
  final TextRecognitionPort _textRecognition;
  final CameraPermissionPort cameraPermission;
  final SerialNormalizer serialNormalizer;
  final HourMeterParser hourMeterParser;

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
    final matchesSelected = _state.selectedCandidateId != null &&
        _state.candidates.any(
          (c) =>
              c.id == _state.selectedCandidateId && c.displayValue == value,
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
            'Edit the value, then tap Confirm. Detected text is never saved '
            'automatically.',
      ),
    );
  }

  /// Highlights a candidate and copies it into the draft field — does not
  /// confirm.
  void selectCandidate(String candidateId) {
    EquipmentIdCandidate? selected;
    for (final candidate in _state.candidates) {
      if (candidate.id == candidateId) {
        selected = candidate;
        break;
      }
    }
    if (selected == null) return;

    _emit(
      _state.copyWith(
        selectedCandidateId: selected.id,
        draftValue: selected.displayValue,
        phase: EquipmentIdCapturePhase.awaitingConfirmation,
        clearConfirmed: true,
        clearFailure: true,
        statusMessage:
            'Candidate selected. Tap Confirm to accept it, or edit manually.',
      ),
    );
  }

  /// Explicit human confirmation of the current draft value.
  bool confirm() {
    if (!_state.canConfirm) return false;

    final method = _state.selectedCandidateId != null &&
            _state.candidates.any(
              (c) =>
                  c.id == _state.selectedCandidateId &&
                  c.displayValue == _state.draftValue,
            )
        ? EquipmentIdCaptureMethod.ocrConfirmed
        : EquipmentIdCaptureMethod.manual;

    if (_state.kind == EquipmentIdCaptureKind.serialNumber) {
      final normalized = serialNormalizer.normalize(_state.draftValue);
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
          statusMessage: 'Serial number confirmed.',
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
        statusMessage: 'Hour meter reading confirmed.',
      ),
    );
    return true;
  }

  /// Clears confirmation so the user can revise without losing draft text.
  void clearConfirmation() {
    if (!_state.isConfirmed) return;
    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.awaitingConfirmation,
        clearConfirmed: true,
        statusMessage: 'Confirmation cleared. Edit or confirm again.',
      ),
    );
  }

  /// Runs permission → capture → OCR → candidate presentation.
  Future<void> captureAndRecognize() async {
    final preservedDraft = _state.draftValue;

    if (!_imageCapture.isSupported || !_textRecognition.isSupported) {
      _emit(
        _state.copyWith(
          phase: EquipmentIdCapturePhase.failed,
          failure: EquipmentIdCaptureFailure.unsupportedPlatform(),
          draftValue: preservedDraft,
          clearConfirmed: true,
          statusMessage:
              EquipmentIdCaptureFailure.unsupportedPlatform().message,
        ),
      );
      return;
    }

    _emit(
      _state.copyWith(
        phase: EquipmentIdCapturePhase.requestingPermission,
        clearFailure: true,
        clearConfirmed: true,
        clearStatusMessage: true,
        draftValue: preservedDraft,
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

    final candidates = _buildCandidates(blocks);
    if (candidates.isEmpty) {
      _fail(
        EquipmentIdCaptureFailure.noTextDetected(),
        preservedDraft,
        image: image,
      );
      return;
    }

    _emit(
      EquipmentIdCaptureState(
        kind: _state.kind,
        phase: EquipmentIdCapturePhase.awaitingConfirmation,
        draftValue: preservedDraft,
        candidates: candidates,
        cameraOcrSupported: _state.cameraOcrSupported,
        lastCapturedImage: image,
        statusMessage:
            'Select a detected candidate, then tap Confirm. Nothing is saved '
            'until you confirm.',
      ),
    );
  }

  List<EquipmentIdCandidate> _buildCandidates(
    List<RecognizedTextBlock> blocks,
  ) {
    if (_state.kind == EquipmentIdCaptureKind.serialNumber) {
      final values = serialNormalizer.candidatesFromRawTexts(
        blocks.map((b) => b.rawText),
      );
      return [
        for (var i = 0; i < values.length; i++)
          EquipmentIdCandidate(
            id: 'serial-$i',
            displayValue: values[i],
            sourceRawText: values[i],
          ),
      ];
    }

    final parsed = hourMeterParser.candidatesFromRawTexts(
      blocks.map((b) => b.rawText),
    );
    return [
      for (var i = 0; i < parsed.length; i++)
        EquipmentIdCandidate(
          id: 'hours-$i',
          displayValue: parsed[i].displayValue,
          hours: parsed[i].hours,
          sourceRawText: parsed[i].sourceRawText,
        ),
    ];
  }

  void _fail(
    EquipmentIdCaptureFailure failure,
    String preservedDraft, {
    CapturedImage? image,
  }) {
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

  Future<void> dispose() async {
    _listeners.clear();
    await _textRecognition.dispose();
  }
}
