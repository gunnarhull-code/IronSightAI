/// Detects OCR-ambiguous characters in serial values without rewriting them.
///
/// Never substitutes O/0, I/1, S/5, B/8, or similar. Serials may legitimately
/// contain letters — this only flags human review.
abstract final class AmbiguousSerialCharacters {
  /// Characters that OCR commonly confuses with a digit or letter twin.
  static final RegExp ambiguousChar = RegExp(r'[O0I1lLS5B8]');

  static const String reviewLabel = 'Check ambiguous characters.';

  /// True when [value] contains at least one commonly confused character.
  static bool hasAmbiguousCharacters(String value) {
    return ambiguousChar.hasMatch(value);
  }

  /// Returns [value] unchanged — never invents or substitutes characters.
  static String preserveAsRead(String value) => value;
}
