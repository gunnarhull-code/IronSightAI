// Read-only CLI: validate management/sprint_registry.json.
// Usage (from repo root): dart run tool/verify_sprint_registry.dart
//
// Does not modify the registry or any documentation.

import 'dart:io';

import 'sprint_registry_validation.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : kDefaultSprintRegistryPath;
  final file = File(path);

  if (!file.existsSync()) {
    stderr.writeln('Sprint registry not found: $path');
    exitCode = 1;
    return;
  }

  final result = validateSprintRegistryJson(file.readAsStringSync());
  if (result.isValid) {
    stdout.writeln('Sprint registry OK: $path');
    exitCode = 0;
    return;
  }

  stderr.writeln('Sprint registry validation failed ($path):');
  for (final error in result.errors) {
    stderr.writeln('  - $error');
  }
  exitCode = 1;
}
