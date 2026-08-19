/// Thrown when the on-device inspection schema cannot be safely migrated.
///
/// Raised instead of rebuilding or dropping tables, so a partially applied or
/// unrecognized schema never costs the user saved inspections. [details]
/// carries schema metadata only (table and column names) — never row values.
class LocalDatabaseSchemaException implements Exception {
  const LocalDatabaseSchemaException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() {
    final detail = details?.trim();
    if (detail != null && detail.isNotEmpty) {
      return 'LocalDatabaseSchemaException: $message ($detail)';
    }
    return 'LocalDatabaseSchemaException: $message';
  }
}
