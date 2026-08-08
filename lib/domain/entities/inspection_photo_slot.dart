/// Required Quick Appraisal photo slots (MVP capture set).
///
/// Optional damage/detail photos and walkaround video are out of scope.
enum InspectionPhotoSlot {
  frontLeftOverview('front_left_overview', 'Front-left overview'),
  rearRightOverview('rear_right_overview', 'Rear-right overview'),
  serialDataPlate('serial_data_plate', 'Serial / data plate'),
  hourMeterDashboard('hour_meter_dashboard', 'Hour-meter / dashboard');

  const InspectionPhotoSlot(this.storageValue, this.label);

  final String storageValue;
  final String label;

  /// Ordered required set shown in Quick Appraisal.
  static const List<InspectionPhotoSlot> requiredSlots = [
    InspectionPhotoSlot.frontLeftOverview,
    InspectionPhotoSlot.rearRightOverview,
    InspectionPhotoSlot.serialDataPlate,
    InspectionPhotoSlot.hourMeterDashboard,
  ];

  bool get feedsSerialOcr => this == InspectionPhotoSlot.serialDataPlate;

  bool get feedsHourMeterOcr => this == InspectionPhotoSlot.hourMeterDashboard;

  static InspectionPhotoSlot fromStorage(String value) {
    for (final slot in InspectionPhotoSlot.values) {
      if (slot.storageValue == value) return slot;
    }
    throw FormatException('Unknown inspection photo slot: $value');
  }
}
