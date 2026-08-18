import 'package:flutter/material.dart';

import '../../../domain/ai/ai_media_review_controller.dart';
import '../../../domain/ai/ai_media_review_failure.dart';
import '../../../domain/ai/ai_media_review_state.dart';
import '../../../domain/ai/ai_service.dart';
import '../../../domain/ai/ai_suggestion.dart';
import '../../../domain/ai/ai_suggestion_applier.dart';
import '../../../domain/ai/walkaround_video_capture_port.dart';
import '../../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../../domain/equipment_id_capture/image_capture_port.dart';
import '../../../domain/repositories/local_inspection_media_repository.dart';
import '../../../domain/repositories/local_inspection_repository.dart';
import 'ai_media_review_labels.dart';

/// Human-review screen for optional AI identity and visible-condition suggestions.
class AiMediaReviewScreen extends StatefulWidget {
  const AiMediaReviewScreen({
    super.key,
    required this.companyId,
    required this.inspectionId,
    required this.userId,
    required this.aiService,
    required this.inspections,
    required this.inspectionMedia,
    this.videoCapture,
    this.controller,
  });

  final String companyId;
  final String inspectionId;
  final String userId;
  final AIService aiService;
  final LocalInspectionRepository inspections;
  final LocalInspectionMediaRepository inspectionMedia;
  final WalkaroundVideoCapturePort? videoCapture;
  final AiMediaReviewController? controller;

  @override
  State<AiMediaReviewScreen> createState() => _AiMediaReviewScreenState();
}

class _AiMediaReviewScreenState extends State<AiMediaReviewScreen> {
  late final AiMediaReviewController _controller;
  late final bool _ownsController;
  final Map<String, TextEditingController> _editors = {};

  @override
  void initState() {
    super.initState();
    final existing = widget.controller;
    if (existing != null) {
      _controller = existing;
      _ownsController = false;
    } else {
      _controller = AiMediaReviewController(
        companyId: widget.companyId,
        inspectionId: widget.inspectionId,
        userId: widget.userId,
        aiService: widget.aiService,
        inspections: widget.inspections,
        inspectionMedia: widget.inspectionMedia,
        videoCapture: widget.videoCapture,
      );
      _ownsController = true;
    }
    _controller.addListener(_onController);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    if (_ownsController) {
      _controller.dispose();
    }
    for (final editor in _editors.values) {
      editor.dispose();
    }
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  TextEditingController _editorFor(AiSuggestion suggestion) {
    return _editors.putIfAbsent(
      suggestion.id,
      () => TextEditingController(text: suggestion.displayValue),
    );
  }

  Future<void> _recordVideo() async {
    try {
      await _controller.recordWalkaroundVideo();
    } on EquipmentIdCaptureException catch (error) {
      if (error.failure.kind ==
          EquipmentIdCaptureFailureKind.captureCancelled) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.failure.message)));
    }
  }

  Future<void> _apply(
    AiSuggestion suggestion, {
    bool replaceExisting = false,
  }) async {
    final edited = _editorFor(suggestion).text;
    final outcome = await _controller.applySuggestion(
      suggestion.id,
      replaceExisting: replaceExisting,
      editedValue: edited,
    );
    if (!mounted) return;
    if (outcome.status == AiApplyStatus.needsReplaceConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AiMediaReviewLabels.replaceConfirmTitle),
          content: const Text(AiMediaReviewLabels.replaceConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AiMediaReviewLabels.keepExisting),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AiMediaReviewLabels.replaceExisting),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _apply(suggestion, replaceExisting: true);
      }
      return;
    }
    if (outcome.status == AiApplyStatus.rejected && outcome.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(outcome.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text(AiMediaReviewLabels.screenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label:
                state.statusAnnouncement ??
                AiMediaReviewLabels.suggestionsDisclaimer,
            child: const SizedBox(width: 8, height: 8),
          ),
          Text(
            AiMediaReviewLabels.optionalBadge,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AiMediaReviewLabels.suggestionsDisclaimer,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AiMediaReviewLabels.frameBasedExplanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _MediaSummary(
            state: state,
            videoSupported: _controller.videoCapture.isSupported,
          ),
          const SizedBox(height: 12),
          if (_controller.videoCapture.isSupported)
            OutlinedButton.icon(
              onPressed: state.isBusy ? null : _recordVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text(AiMediaReviewLabels.recordVideoButton),
            ),
          if (state.hasWalkaroundVideo) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: state.isBusy ? null : _controller.clearWalkaroundVideo,
              child: const Text(AiMediaReviewLabels.removeVideoButton),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            AiMediaReviewLabels.consentTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AiMediaReviewLabels.consentBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (state.isBusy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              label: AiMediaReviewLabels.loadingAnnouncement,
              child: Text(
                AiMediaReviewLabels.loadingAnnouncement,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _controller.cancelAnalysis,
              child: const Text(AiMediaReviewLabels.cancelButton),
            ),
          ] else ...[
            FilledButton(
              onPressed: state.canAnalyze
                  ? _controller.analyzeMediaOnline
                  : null,
              child: const Text(AiMediaReviewLabels.analyzeButton),
            ),
            if (state.phase == AiMediaReviewPhase.offline ||
                state.phase == AiMediaReviewPhase.providerFailure ||
                state.phase == AiMediaReviewPhase.cancelled) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: state.canAnalyze
                    ? _controller.analyzeMediaOnline
                    : null,
                child: const Text(AiMediaReviewLabels.retryButton),
              ),
            ],
          ],
          if (state.failure != null) ...[
            const SizedBox(height: 12),
            _FailureBanner(failure: state.failure!),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AiMediaReviewLabels.continueWithoutAi),
          ),
          if (state.hasResults) ...[
            const SizedBox(height: 24),
            Text('Suggestions for review', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.result!.disclaimer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final suggestion in state.result!.suggestions)
              _SuggestionCard(
                suggestion: suggestion,
                editor: _editorFor(suggestion),
                enabled: !state.isBusy && suggestion.isPending,
                onApply: () => _apply(suggestion),
                onDismiss: () => _controller.dismissSuggestion(suggestion.id),
                onEdited: (value) =>
                    _controller.editSuggestion(suggestion.id, value),
              ),
          ],
        ],
      ),
    );
  }
}

class _MediaSummary extends StatelessWidget {
  const _MediaSummary({required this.state, required this.videoSupported});

  final AiMediaReviewViewState state;
  final bool videoSupported;

  @override
  Widget build(BuildContext context) {
    final videoText = state.hasWalkaroundVideo
        ? '${state.videoFrameCount} extracted walkaround frames '
              '(${state.videoDuration?.inSeconds ?? 0}s video stays on device)'
        : videoSupported
        ? 'No walkaround video (optional)'
        : 'Walkaround video not available on this device';
    return Semantics(
      label:
          '${state.photoCount} inspection photos. $videoText. '
          'Ready to analyze: ${state.canAnalyze ? 'yes' : 'no'}.',
      child: Text(
        '${state.photoCount} inspection photos · $videoText',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failure});

  final AiMediaReviewFailure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: failure.spokenMessage,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(failure.kind),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(failure.message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleFor(AiMediaReviewFailureKind kind) {
    return switch (kind) {
      AiMediaReviewFailureKind.offline => 'Offline / unavailable',
      AiMediaReviewFailureKind.timeout => 'AI timed out',
      AiMediaReviewFailureKind.cancelled => 'Cancelled',
      AiMediaReviewFailureKind.providerFailure => 'Provider failure',
      AiMediaReviewFailureKind.malformedResponse => 'Unreadable AI response',
      AiMediaReviewFailureKind.noMedia => 'Photos needed',
      AiMediaReviewFailureKind.videoTooLong => 'Video too long',
      AiMediaReviewFailureKind.videoFramesMissing => 'Frames missing',
    };
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.editor,
    required this.enabled,
    required this.onApply,
    required this.onDismiss,
    required this.onEdited,
  });

  final AiSuggestion suggestion;
  final TextEditingController editor;
  final bool enabled;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final ValueChanged<String> onEdited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (suggestion.decision) {
      AiSuggestionDecision.pending => 'Pending review',
      AiSuggestionDecision.applied => 'Applied',
      AiSuggestionDecision.dismissed => 'Dismissed',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${suggestion.kind.displayLabel} · $status',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(suggestion.disclaimer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Semantics(
              label:
                  '${AiMediaReviewLabels.confidencePrefix} '
                  '${suggestion.confidence.displayLabel}',
              child: Text(
                '${AiMediaReviewLabels.confidencePrefix}: '
                '${suggestion.confidence.displayLabel}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              label:
                  '${AiMediaReviewLabels.sourcePrefix} '
                  '${suggestion.source.spokenLabel}',
              child: Text(
                '${AiMediaReviewLabels.sourcePrefix}: '
                '${suggestion.source.spokenLabel}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (suggestion.uncertainty != null) ...[
              const SizedBox(height: 4),
              Text(
                'Uncertainty: ${suggestion.uncertainty}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (suggestion.hasAmbiguousSerialCharacters) ...[
              const SizedBox(height: 4),
              const Text(AiMediaReviewLabels.ambiguityNote),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: editor,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Suggested value',
                hintText: suggestion.hasDisplayValue
                    ? null
                    : 'Unreadable — not invented',
              ),
              onChanged: onEdited,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  button: true,
                  label:
                      '${AiMediaReviewLabels.applyButton} ${suggestion.kind.displayLabel}',
                  child: FilledButton(
                    onPressed: enabled ? onApply : null,
                    child: const Text(AiMediaReviewLabels.applyButton),
                  ),
                ),
                Semantics(
                  button: true,
                  label:
                      '${AiMediaReviewLabels.editButton} ${suggestion.kind.displayLabel}',
                  child: OutlinedButton(
                    onPressed: enabled ? () => onEdited(editor.text) : null,
                    child: const Text(AiMediaReviewLabels.editButton),
                  ),
                ),
                Semantics(
                  button: true,
                  label:
                      '${AiMediaReviewLabels.dismissButton} ${suggestion.kind.displayLabel}',
                  child: TextButton(
                    onPressed: enabled ? onDismiss : null,
                    child: const Text(AiMediaReviewLabels.dismissButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
