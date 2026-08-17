import '../entities/inspection_photo_slot.dart';

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
      'video_frame' || 'videoframe' => AiMediaSourceType.videoFrame,
      _ => throw FormatException('Unknown AI media source type: $rawType'),
    };
    InspectionPhotoSlot? slot;
    final rawSlot = map['slot'] as String?;
    if (rawSlot != null && rawSlot.isNotEmpty) {
      slot = InspectionPhotoSlot.fromStorage(rawSlot);
    }
    final frame = map['frame_index'] ?? map['frameIndex'];
    return AiMediaSource(
      type: type,
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : (type == AiMediaSourceType.photo
                ? (slot?.label ?? 'Inspection photo')
                : 'Walkaround video frame'),
      slot: slot,
      frameIndex: frame is num ? frame.toInt() : null,
    );
  }
}
