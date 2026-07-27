// Regression coverage for safe test / CI bootstrap configuration.
//
// Unit and widget tests do not call production Supabase, but Flutter still
// requires a root `.env` asset (see pubspec.yaml). CI and local verify scripts
// create that file from the committed `.env.example`. This test fails clearly
// if that safe template disappears or points at a hosted project.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('.env.example provides safe local Supabase defaults for CI/tests', () {
    final file = File('.env.example');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Required safe test configuration (.env.example) is unavailable.',
    );

    final content = file.readAsStringSync();
    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'));

    final values = <String, String>{};
    for (final line in lines) {
      final separator = line.indexOf('=');
      expect(separator, greaterThan(0), reason: 'Invalid env line: $line');
      values[line.substring(0, separator)] = line.substring(separator + 1);
    }

    expect(values['SUPABASE_URL'], 'http://127.0.0.1:54321');
    expect(values.containsKey('SUPABASE_ANON_KEY'), isTrue);
    expect(values['SUPABASE_ANON_KEY'], isNotEmpty);

    final url = values['SUPABASE_URL']!;
    expect(url.contains('supabase.co'), isFalse);
    expect(url.startsWith('http://127.0.0.1:'), isTrue);
  });
}
