import '../entities/inspection_photo_slot.dart';
import 'walkaround_video.dart';

enum AiMediaSourceType { photo, videoFrame }

/// Which photo or extracted video frame supports a suggestion.
class AiMediaSource {
  const AiMediaSource({
    required this.type,
    required this.label,
    this.slot,
    this.frameIndex,
  });

  final AiMediaSourceType type;
  final String label;
  final InspectionPhotoSlot? slot;
  final int? frameIndex;

  String get spokenLabel {
    if (type == AiMediaSourceType.videoFrame) {
      final index = frameIndex;
      if (index != null) {
        return 'Walkaround video frame ${index + 1}';
      }
      return 'Walkaround video frame';
    }
    return slot?.label ?? label;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type == AiMediaSourceType.photo ? 'photo' : 'video_frame',
      'label': label,
      if (slot != null) 'slot': slot!.storageValue,
      if (frameIndex != null) 'frame_index': frameIndex,
    };
  }

  factory AiMediaSource.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] as String? ?? '').toLowerCase();
    final type = switch (rawType) {
      'photo' => AiMediaSourceType.photo,
      'video_frame' => AiMediaSourceType.videoFrame,
      _ => throw FormatException('Unknown AI media source type: $rawType'),
    };
    InspectionPhotoSlot? slot;
    final rawSlot = map['slot'];
    if (rawSlot is String && rawSlot.isNotEmpty) {
      slot = InspectionPhotoSlot.fromStorage(rawSlot);
    } else if (rawSlot != null) {
      throw FormatException('Invalid AI media source slot');
    }
    final frame = map['frame_index'] ?? map['frameIndex'];
    final frameIndex = switch (frame) {
      null => null,
      int value => value,
      num value when value == value.roundToDouble() => value.toInt(),
      _ => throw FormatException('video_frame source requires frame_index'),
    };
    if (type == AiMediaSourceType.photo) {
      if (slot == null) {
        throw FormatException('photo source requires a supported slot');
      }
      if (frameIndex != null) {
        throw FormatException('photo source must not include frame_index');
      }
      return AiMediaSource(
        type: type,
        label: (map['label'] as String?)?.trim().isNotEmpty == true
            ? (map['label'] as String).trim()
            : slot.label,
        slot: slot,
      );
    }
    if (frameIndex == null ||
        frameIndex < 0 ||
        frameIndex >= WalkaroundVideo.maxFrameCount) {
      throw FormatException(
        'video_frame source requires a bounded frame_index',
      );
    }
    if (slot != null) {
      throw FormatException('video_frame source must not include slot');
    }
    return AiMediaSource(
      type: type,
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : 'Walkaround video frame ${frameIndex + 1}',
      frameIndex: frameIndex,
    );
  }
}
