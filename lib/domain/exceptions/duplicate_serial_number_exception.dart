/// Thrown when a serial number is already used by another equipment record
/// in the current user's company.
///
/// Deliberately scoped to the current company only — duplicate checks never
/// look across companies (tenant isolation), matching the same boundary
/// enforced by RLS on `public.equipment`.
class DuplicateSerialNumberException implements Exception {
  const DuplicateSerialNumberException();

  static const String message =
      'This serial number already exists for another piece of equipment.';

  @override
  String toString() => message;
}
