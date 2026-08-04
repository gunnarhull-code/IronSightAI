import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/inspection_media.dart';
import '../../../../domain/entities/inspection_photo_slot.dart';

/// Screen-reader labels for required Quick Appraisal photo slots.
abstract final class RequiredPhotoLabels {
  static String slotStatus(
    InspectionPhotoSlot slot, {
    required bool completed,
  }) => '${slot.label} photo ${completed ? 'completed' : 'missing'}';

  static String captureButton(InspectionPhotoSlot slot) =>
      'Capture ${slot.label} photo';

  static String retakeButton(InspectionPhotoSlot slot) =>
      'Retake ${slot.label} photo';

  static String previewButton(InspectionPhotoSlot slot) =>
      'Preview ${slot.label} photo';

  static String previewThumbnail(InspectionPhotoSlot slot) =>
      '${slot.label} photo thumbnail';

  static const String unreadablePreview = 'Photo preview unavailable';
}

/// Four required photo slots with missing/completed state and capture/retake.
class RequiredInspectionPhotosSection extends StatelessWidget {
  const RequiredInspectionPhotosSection({
    super.key,
    required this.mediaBySlot,
    required this.previewBytesBySlot,
    required this.enabled,
    required this.busySlot,
    required this.onCapture,
    required this.onRetake,
    required this.onPreview,
  });

  final Map<InspectionPhotoSlot, InspectionMedia> mediaBySlot;
  final Map<InspectionPhotoSlot, Uint8List> previewBytesBySlot;
  final bool enabled;
  final InspectionPhotoSlot? busySlot;
  final Future<void> Function(InspectionPhotoSlot slot) onCapture;
  final Future<void> Function(InspectionPhotoSlot slot) onRetake;
  final void Function(InspectionPhotoSlot slot) onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Required photos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Capture all four photos on this device. Works offline. '
          'Serial and hour-meter photos are reused for OCR — no second shot.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final slot in InspectionPhotoSlot.requiredSlots) ...[
          _RequiredPhotoSlotCard(
            slot: slot,
            media: mediaBySlot[slot],
            previewBytes: previewBytesBySlot[slot],
            enabled: enabled,
            busy: busySlot == slot,
            onCapture: () => onCapture(slot),
            onRetake: () => onRetake(slot),
            onPreview: () => onPreview(slot),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RequiredPhotoSlotCard extends StatelessWidget {
  const _RequiredPhotoSlotCard({
    required this.slot,
    required this.media,
    required this.previewBytes,
    required this.enabled,
    required this.busy,
    required this.onCapture,
    required this.onRetake,
    required this.onPreview,
  });

  final InspectionPhotoSlot slot;
  final InspectionMedia? media;
  final Uint8List? previewBytes;
  final bool enabled;
  final bool busy;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = media != null;
    final statusColor = complete
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final statusText = complete ? 'Completed' : 'Missing';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(slot.label, style: theme.textTheme.titleSmall),
                ),
                Semantics(
                  container: true,
                  liveRegion: true,
                  // The icon + text are decorative here; the slot label already
                  // announces the state, so they must not merge into it.
                  excludeSemantics: true,
                  label: RequiredPhotoLabels.slotStatus(
                    slot,
                    completed: complete,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        complete ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (previewBytes != null) ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                image: true,
                label: RequiredPhotoLabels.previewThumbnail(slot),
                child: InkWell(
                  onTap: enabled ? onPreview : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      previewBytes!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // A stored photo that cannot be decoded must not take the
                      // workspace down; the slot still reads as Completed.
                      errorBuilder: (context, _, _) => Container(
                        height: 120,
                        alignment: Alignment.center,
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: const Text(
                          RequiredPhotoLabels.unreadablePreview,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!complete)
              Semantics(
                button: true,
                label: RequiredPhotoLabels.captureButton(slot),
                child: FilledButton.icon(
                  onPressed: enabled && !busy ? onCapture : null,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera),
                  label: Text(busy ? 'Capturing…' : 'Capture photo'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: RequiredPhotoLabels.previewButton(slot),
                      child: OutlinedButton.icon(
                        onPressed: enabled && !busy ? onPreview : null,
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Preview'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: RequiredPhotoLabels.retakeButton(slot),
                      child: FilledButton.tonalIcon(
                        onPressed: enabled && !busy ? onRetake : null,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(busy ? 'Saving…' : 'Retake'),
                      ),
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
