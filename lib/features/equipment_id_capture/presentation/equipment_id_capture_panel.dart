import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import '../../../domain/equipment_id_capture/equipment_id_candidate.dart';
import '../../../domain/equipment_id_capture/equipment_id_capture_controller.dart';
import '../../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../../domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'equipment_id_capture_labels.dart';

/// Reusable offline equipment-identification capture panel.
///
/// Camera-first, typing-last, with always-visible manual entry. Does not import
/// camera or OCR packages — only the injected [EquipmentIdCaptureController].
///
/// Embedded in Quick Appraisal for serial number and hour-meter confirmation.
class EquipmentIdCapturePanel extends StatefulWidget {
  const EquipmentIdCapturePanel({
    super.key,
    required this.controller,
    this.onPersist,
    this.onScanRequested,
  });

  final EquipmentIdCaptureController controller;

  /// Persists a human-accepted value to the local inspection draft.
  final Future<void> Function(ConfirmedEquipmentIdValue value)? onPersist;

  /// When set, replaces the default camera+OCR scan with a caller-owned flow
  /// (e.g. reuse a required serial/hour photo).
  final Future<void> Function()? onScanRequested;

  @override
  State<EquipmentIdCapturePanel> createState() =>
      _EquipmentIdCapturePanelState();
}

class _EquipmentIdCapturePanelState extends State<EquipmentIdCapturePanel> {
  late final TextEditingController _textController;
  late final FocusNode _manualFocus;
  late final FocusNode _scanFocus;
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.state.draftValue,
    );
    _manualFocus = FocusNode(debugLabel: 'equipment-id-manual');
    _scanFocus = FocusNode(debugLabel: 'equipment-id-scan');
    _manualFocus.addListener(_onManualFocusChange);
    widget.controller.addListener(_onControllerState);
  }

  @override
  void didUpdateWidget(covariant EquipmentIdCapturePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerState);
      widget.controller.addListener(_onControllerState);
      _textController.text = widget.controller.state.draftValue;
    }
  }

  void _onManualFocusChange() {
    if (!_manualFocus.hasFocus && mounted) {
      _commitManual();
    }
  }

  void _onControllerState(EquipmentIdCaptureState state) {
    if (!mounted) return;
    if (_textController.text != state.draftValue && !_manualFocus.hasFocus) {
      _textController.value = TextEditingValue(
        text: state.draftValue,
        selection: TextSelection.collapsed(offset: state.draftValue.length),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _manualFocus.removeListener(_onManualFocusChange);
    widget.controller.removeListener(_onControllerState);
    _textController.dispose();
    _manualFocus.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  String get _title {
    return widget.controller.state.kind == EquipmentIdCaptureKind.serialNumber
        ? 'Serial number'
        : 'Hour meter';
  }

  String get _scanLabel {
    return widget.controller.state.kind == EquipmentIdCaptureKind.serialNumber
        ? EquipmentIdCaptureLabels.serialScanButton
        : EquipmentIdCaptureLabels.hourScanButton;
  }

  String get _manualLabel {
    return widget.controller.state.kind == EquipmentIdCaptureKind.serialNumber
        ? EquipmentIdCaptureLabels.serialManualField
        : EquipmentIdCaptureLabels.hourManualField;
  }

  bool get _busy {
    final phase = widget.controller.state.phase;
    return phase == EquipmentIdCapturePhase.requestingPermission ||
        phase == EquipmentIdCapturePhase.capturing ||
        phase == EquipmentIdCapturePhase.recognizing ||
        _committing;
  }

  Future<void> _commitCandidate(String candidateId) async {
    if (_committing) return;
    _committing = true;
    setState(() {});
    try {
      if (!widget.controller.selectCandidate(candidateId)) return;
      await _persistCurrent();
    } finally {
      if (mounted) {
        _committing = false;
        setState(() {});
      } else {
        _committing = false;
      }
    }
  }

  Future<void> _commitManual() async {
    if (_committing) return;
    _committing = true;
    setState(() {});
    try {
      if (!widget.controller.completeManualEntry()) return;
      await _persistCurrent();
    } finally {
      if (mounted) {
        _committing = false;
        setState(() {});
      } else {
        _committing = false;
      }
    }
  }

  Future<void> _persistCurrent() async {
    final confirmed = widget.controller.state.confirmed;
    if (confirmed == null) return;
    if (widget.controller.isAlreadySaved) {
      widget.controller.markSaved();
      return;
    }
    final persist = widget.onPersist;
    if (persist == null) {
      widget.controller.markSaved();
      return;
    }
    try {
      await persist(confirmed);
      if (!mounted) return;
      widget.controller.markSaved();
    } catch (error) {
      if (!mounted) return;
      widget.controller.revertToLastSaved(
        EquipmentIdCaptureFailure.persistenceFailure(error.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final theme = Theme.of(context);
    final recommended = state.candidates.where((c) => c.isRecommended).toList();
    final alternatives = state.candidates
        .where((c) => !c.isRecommended)
        .toList();

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: _title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            EquipmentIdCaptureLabels.manualFallbackHint,
            style: theme.textTheme.bodyMedium,
          ),
          if (!state.cameraOcrSupported) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    EquipmentIdCaptureLabels.unsupportedPlatformBanner,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: _scanLabel,
            excludeSemantics: true,
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                focusNode: _scanFocus,
                onPressed: _busy || !state.cameraOcrSupported
                    ? null
                    : () {
                        final custom = widget.onScanRequested;
                        if (custom != null) {
                          custom();
                        } else {
                          widget.controller.captureAndRecognize();
                        }
                      },
                icon: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera, size: 28),
                label: Text(
                  state.cameraOcrSupported
                      ? (widget.onScanRequested != null
                            ? 'Scan required photo'
                            : 'Scan with camera')
                      : 'Scan unavailable',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          if (recommended.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Recommended', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final candidate in recommended)
              _CandidateButton(
                candidate: candidate,
                selected: state.selectedCandidateId == candidate.id,
                recommended: true,
                enabled: !_busy,
                onTap: () => _commitCandidate(candidate.id),
              ),
          ],
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label: EquipmentIdCaptureLabels.otherPossibilities,
              child: ExpansionTile(
                title: const Text(EquipmentIdCaptureLabels.otherPossibilities),
                children: [
                  for (final candidate in alternatives)
                    _CandidateButton(
                      candidate: candidate,
                      selected: state.selectedCandidateId == candidate.id,
                      recommended: false,
                      enabled: !_busy,
                      onTap: () => _commitCandidate(candidate.id),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            textField: true,
            label: _manualLabel,
            excludeSemantics: true,
            child: TextFormField(
              controller: _textController,
              focusNode: _manualFocus,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              keyboardType: state.kind == EquipmentIdCaptureKind.hourMeter
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.visiblePassword,
              autofillHints: const [],
              inputFormatters: state.kind == EquipmentIdCaptureKind.hourMeter
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                  : null,
              decoration: InputDecoration(
                labelText: _manualLabel,
                helperText: 'Always available — saves when you finish editing',
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.controller.updateManualEntry,
              onFieldSubmitted: (_) => _commitManual(),
            ),
          ),
          const SizedBox(height: 12),
          if (state.failure != null) _FailureBanner(failure: state.failure!),
          if (state.statusMessage != null && state.failure == null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                state.statusMessage!,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (state.isConfirmed)
            Semantics(
              liveRegion: true,
              label:
                  '${EquipmentIdCaptureLabels.savedStatePrefix} '
                  '${state.confirmed!.value}',
              excludeSemantics: true,
              child: Material(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saved: ${state.confirmed!.value}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateButton extends StatelessWidget {
  const _CandidateButton({
    required this.candidate,
    required this.selected,
    required this.recommended,
    required this.enabled,
    required this.onTap,
  });

  final EquipmentIdCandidate candidate;
  final bool selected;
  final bool recommended;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prefix = recommended
        ? EquipmentIdCaptureLabels.recommendedPrefix
        : EquipmentIdCaptureLabels.alternativePrefix;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$prefix ${candidate.displayValue}',
        excludeSemantics: true,
        child: recommended
            ? FilledButton.tonal(
                onPressed: enabled ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    candidate.displayValue,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: enabled ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    candidate.displayValue,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failure});

  final EquipmentIdCaptureFailure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        label: EquipmentIdCaptureLabels.saveError,
        excludeSemantics: true,
        child: Material(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure.message,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                if (failure.guidance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    failure.guidance!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
