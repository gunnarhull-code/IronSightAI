/// How a guided Quick Appraisal draft obtained its equipment identity.
enum InspectionMachineSource {
  /// Draft collects identity first; Equipment is created only at completion.
  newMachine,

  /// Draft is linked to an existing company-scoped local Equipment record.
  existingEquipment;

  String get storageValue => switch (this) {
    InspectionMachineSource.newMachine => 'new_machine',
    InspectionMachineSource.existingEquipment => 'existing_equipment',
  };

  String get displayLabel => switch (this) {
    InspectionMachineSource.newMachine => 'New machine',
    InspectionMachineSource.existingEquipment => 'Existing equipment',
  };

  static InspectionMachineSource fromStorage(String value) {
    return switch (value) {
      'new_machine' => InspectionMachineSource.newMachine,
      'existing_equipment' => InspectionMachineSource.existingEquipment,
      _ => throw FormatException('Unknown inspection machine source: $value'),
    };
  }
}
