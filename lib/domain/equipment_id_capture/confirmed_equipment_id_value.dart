import 'equipment_id_capture_kind.dart';
import 'equipment_id_capture_method.dart';

/// A human-confirmed identification value ready for a calling workflow.
class ConfirmedEquipmentIdValue {
  const ConfirmedEquipmentIdValue({
    required this.kind,
    required this.value,
    required this.method,
    this.hours,
  });

  final EquipmentIdCaptureKind kind;

  /// Display / storage string after normalization (serial) or canonical
  /// numeric formatting (hours).
  final String value;

  final EquipmentIdCaptureMethod method;

  /// Parsed hours when [kind] is [EquipmentIdCaptureKind.hourMeter].
  final double? hours;
}
