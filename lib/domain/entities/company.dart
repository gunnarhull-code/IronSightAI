/// Tenant root entity for a dealership company.
///
/// [updatedAt] is maintained by the database. Future tenant-scoped entities
/// (equipment, inspections, regions) hang off [id] via `company_id`.
const Object _unsetRegion = Object();

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.region,
  });

  final String id;
  final String name;
  final String? region;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company copyWith({
    String? id,
    String? name,
    Object? region = _unsetRegion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      region: identical(region, _unsetRegion) ? this.region : region as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as String,
      name: map['name'] as String,
      region: map['region'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
