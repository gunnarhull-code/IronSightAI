import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.onConfirmed,
    this.onScanRequested,
  });

  final EquipmentIdCaptureController controller;
  final ValueChanged<EquipmentIdCaptureState>? onConfirmed;

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
  late final FocusNode _confirmFocus;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.state.draftValue,
    );
    _manualFocus = FocusNode(debugLabel: 'equipment-id-manual');
    _scanFocus = FocusNode(debugLabel: 'equipment-id-scan');
    _confirmFocus = FocusNode(debugLabel: 'equipment-id-confirm');
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

  void _onControllerState(EquipmentIdCaptureState state) {
    if (!mounted) return;
    if (_textController.text != state.draftValue && !_manualFocus.hasFocus) {
      _textController.value = TextEditingValue(
        text: state.draftValue,
        selection: TextSelection.collapsed(offset: state.draftValue.length),
      );
    }
    setState(() {});
    if (state.isConfirmed) {
      widget.onConfirmed?.call(state);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerState);
    _textController.dispose();
    _manualFocus.dispose();
    _scanFocus.dispose();
    _confirmFocus.dispose();
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
        phase == EquipmentIdCapturePhase.recognizing;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
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
          if (state.candidates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Detected candidates — tap to select, then confirm',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final candidate in state.candidates)
                  Semantics(
                    button: true,
                    selected: state.selectedCandidateId == candidate.id,
                    label:
                        '${EquipmentIdCaptureLabels.candidatePrefix} '
                        '${candidate.displayValue}',
                    child: FilterChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          candidate.displayValue,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      selected: state.selectedCandidateId == candidate.id,
                      onSelected: (_) =>
                          widget.controller.selectCandidate(candidate.id),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            textField: true,
            label: _manualLabel,
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
                helperText: 'Always available — edit anytime',
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.controller.updateManualEntry,
              onFieldSubmitted: (_) {
                if (state.canConfirm) {
                  _confirmFocus.requestFocus();
                  widget.controller.confirm();
                }
              },
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
                          'Confirmed: ${state.confirmed!.value}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Semantics(
              button: true,
              label: EquipmentIdCaptureLabels.confirmButton,
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  focusNode: _confirmFocus,
                  onPressed: state.canConfirm && !_busy
                      ? () => widget.controller.confirm()
                      : null,
                  child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          if (state.isConfirmed) ...[
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: EquipmentIdCaptureLabels.clearConfirmationButton,
              child: TextButton(
                onPressed: widget.controller.clearConfirmation,
                child: const Text('Edit confirmed value'),
              ),
            ),
          ],
        ],
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
