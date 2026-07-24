import 'manufacturer_catalog.dart';

/// Earliest allowed equipment year in V1.
const int minEquipmentYear = 1950;

/// Latest allowed equipment year in V1 — one year ahead of today, to cover
/// next-model-year equipment sold ahead of the calendar year.
int maxEquipmentYear() => DateTime.now().year + 1;

/// Editable equipment fields, shared by create and update flows.
///
/// Kept separate from [Equipment] because it never carries [Equipment.id],
/// [Equipment.companyId], or timestamps — those are assigned by the data
/// layer, not entered through the form.
class EquipmentDetails {
  const EquipmentDetails({
    required this.assetName,
    required this.manufacturer,
    required this.model,
    this.serialNumber,
    this.year,
    this.hours,
    this.location,
    this.notes,
  });

  final String assetName;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final int? year;
  final double? hours;
  final String? location;
  final String? notes;

  /// Validates and normalizes raw input before it reaches the repository.
  ///
  /// Centralizing this here (rather than in the widgets or scattered across
  /// use cases) keeps business rules out of the presentation layer and keeps
  /// create/update validation identical. The presentation layer duplicates
  /// the *bounds constants* (not the logic) for immediate inline field
  /// feedback — this factory remains the single source of truth actually
  /// enforced before anything reaches the repository.
  factory EquipmentDetails.validated({
    required String assetName,
    required String manufacturer,
    required String model,
    String? serialNumber,
    int? year,
    double? hours,
    String? location,
    String? notes,
  }) {
    final trimmedAssetName = assetName.trim();
    final trimmedManufacturer = manufacturer.trim();
    final trimmedModel = model.trim();

    if (trimmedAssetName.isEmpty) {
      throw ArgumentError('Asset name is required');
    }
    if (trimmedManufacturer.isEmpty) {
      throw ArgumentError('Select a manufacturer');
    }
    if (!manufacturerCatalog.contains(trimmedManufacturer)) {
      throw ArgumentError('Select a manufacturer from the list');
    }
    if (trimmedModel.isEmpty) {
      throw ArgumentError('Model is required');
    }
    if (year != null) {
      if (year < minEquipmentYear) {
        throw ArgumentError('Year must be $minEquipmentYear or later');
      }
      final latestYear = maxEquipmentYear();
      if (year > latestYear) {
        throw ArgumentError('Year cannot be later than $latestYear');
      }
    }
    if (hours != null && hours < 0) {
      throw ArgumentError('Hours cannot be negative');
    }

    String? normalize(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return EquipmentDetails(
      assetName: trimmedAssetName,
      manufacturer: trimmedManufacturer,
      model: trimmedModel,
      serialNumber: normalize(serialNumber),
      year: year,
      hours: hours,
      location: normalize(location),
      notes: normalize(notes),
    );
  }
}
