import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/sprint_registry_validation.dart';

Map<String, dynamic> _validRegistry({
  int nextSprintNumber = 12,
  List<Map<String, dynamic>>? sprints,
}) {
  return {
    'schemaVersion': 1,
    'nextSprintNumber': nextSprintNumber,
    'sprints':
        sprints ??
        [
          {
            'number': 3,
            'title': 'Deferred / archived (number reserved — do not reuse)',
            'status': 'deferred',
            'pullRequests': <int>[],
          },
          {
            'number': 9,
            'title':
                'Engineering Reliability, CI, and Developer Workflow Baseline',
            'status': 'completed',
            'pullRequests': [7],
            'mergeCommit': 'ed759143c340afe2cc0eba833b3455ff1e256f38',
          },
          {
            'number': 10,
            'title': 'Node.js 24 / actions/checkout compatibility',
            'status': 'completed',
            'pullRequests': [12],
            'mergeCommit': '784d820324651c99e3a1621c3879c6aab584081b',
          },
          {
            'number': 11,
            'title': 'Sprint Registry and Status-Consistency Guardrails',
            'status': 'active',
            'pullRequests': <int>[],
          },
        ],
  };
}

void main() {
  test('canonical management/sprint_registry.json validates', () {
    final file = File(kDefaultSprintRegistryPath);
    expect(file.existsSync(), isTrue);
    final result = validateSprintRegistryJson(file.readAsStringSync());
    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    expect(result.isValid, isTrue);
  });

  test('valid registry is accepted', () {
    final result = validateSprintRegistryMap(_validRegistry());
    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
  });

  test('duplicate sprint number fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 3,
          'title': 'Duplicate identity attempt',
          'status': 'planned',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('Duplicate sprint number 3')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('invalid status fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'shipped',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('unsupported')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('invalid nextSprintNumber fails', () {
    final result = validateSprintRegistryMap(
      _validRegistry(nextSprintNumber: 11),
    );
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('nextSprintNumber')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('missing Sprint 003 fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('Sprint 003 is missing')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('attempted Sprint 009 reassignment fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title': 'Inspection List Foundation',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('Sprint 009')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('attempted Sprint 010 reassignment fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Unrelated product feature sprint',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('Sprint 010')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('duplicate contradictory PR assignment fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 8,
          'title': 'Inspection Local Foundation',
          'status': 'completed',
          'pullRequests': [9],
          'mergeCommit': '2f9f654347ac864005feaf4058a2f518555f3c9a',
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [9],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any(
        (e) => e.contains('Pull request #9') && e.contains('contradictory'),
      ),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('multiple active sprints are accepted', () {
    final registry = _validRegistry(
      nextSprintNumber: 13,
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
        {
          'number': 11,
          'title': 'Sprint Registry and Status-Consistency Guardrails',
          'status': 'active',
          'pullRequests': <int>[],
        },
        {
          'number': 12,
          'title': 'Parallel active sprint (fixture)',
          'status': 'active',
          'pullRequests': <int>[],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
  });

  test('invalid JSON fails with clear message', () {
    final result = validateSprintRegistryJson('{not-json');
    expect(result.isValid, isFalse);
    expect(result.errors.first, contains('Invalid JSON'));
  });

  test('completed sprint without completion evidence fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': 'Deferred / archived (number reserved — do not reuse)',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': <int>[],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('missing completion evidence')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('whitespace-only title fails', () {
    final registry = _validRegistry(
      sprints: [
        {
          'number': 3,
          'title': '   ',
          'status': 'deferred',
          'pullRequests': <int>[],
        },
        {
          'number': 9,
          'title':
              'Engineering Reliability, CI, and Developer Workflow Baseline',
          'status': 'completed',
          'pullRequests': [7],
        },
        {
          'number': 10,
          'title': 'Node.js 24 / actions/checkout compatibility',
          'status': 'completed',
          'pullRequests': [12],
        },
      ],
    );

    final result = validateSprintRegistryMap(registry);
    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.contains('whitespace-only')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });

  test('fixture JSON round-trip validates the same rules', () {
    // Controlled invalid fixture kept in-memory / temp — never alters the
    // real management/sprint_registry.json.
    final invalid = _validRegistry(nextSprintNumber: 1);
    final encoded = jsonEncode(invalid);
    final dir = Directory.systemTemp.createTempSync('sprint_registry_fix');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    final fixture = File('${dir.path}/invalid_next.json')
      ..writeAsStringSync(encoded);

    final result = validateSprintRegistryJson(fixture.readAsStringSync());
    expect(result.isValid, isFalse);
    expect(result.errors.any((e) => e.contains('nextSprintNumber')), isTrue);
  });
}
