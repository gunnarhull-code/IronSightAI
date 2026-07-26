/// A single piece of equipment owned by a company.
///
/// [companyId] is set by the data layer from the authenticated user's
/// company membership — it is never supplied by the UI. Photos, inspections,
/// maintenance history, and categorization are deliberately out of scope for
/// this entity; they will reference [id] as separate tenant-scoped tables
/// once built.
class Equipment {
  const Equipment({
    required this.id,
    required this.companyId,
    required this.assetName,
    required this.manufacturer,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.serialNumber,
    this.year,
    this.hours,
    this.location,
    this.notes,
    this.createdBy,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
  });

  final String id;
  final String companyId;
  final String assetName;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final int? year;
  final double? hours;
  final String? location;
  final String? notes;
  final String? createdBy;
  final String? createdByName;
  final String? updatedBy;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      assetName: map['asset_name'] as String,
      manufacturer: map['manufacturer'] as String,
      model: map['model'] as String,
      serialNumber: map['serial_number'] as String?,
      year: map['year'] as int?,
      hours: (map['hours'] as num?)?.toDouble(),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      createdByName: map['created_by_name'] as String?,
      updatedBy: map['updated_by'] as String?,
      updatedByName: map['updated_by_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
