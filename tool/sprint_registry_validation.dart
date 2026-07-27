// Sprint registry parsing and validation (stdlib only).
// Kept separate from CLI exit behavior so flutter tests can exercise it.

import 'dart:convert';

/// Status values allowed in management/sprint_registry.json.
const Set<String> kAllowedSprintStatuses = {
  'planned',
  'active',
  'blocked',
  'deferred',
  'completed',
  'cancelled',
};

/// Default path to the canonical registry (repo-relative).
const String kDefaultSprintRegistryPath = 'management/sprint_registry.json';

/// Result of validating a sprint registry document.
class SprintRegistryValidationResult {
  const SprintRegistryValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// Parse [jsonText] as JSON and validate sprint-registry invariants.
///
/// Returns a result with actionable error messages. Never modifies files.
SprintRegistryValidationResult validateSprintRegistryJson(String jsonText) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException catch (e) {
    return SprintRegistryValidationResult(['Invalid JSON: ${e.message}']);
  }

  if (decoded is! Map) {
    return const SprintRegistryValidationResult([
      'Registry root must be a JSON object.',
    ]);
  }

  return validateSprintRegistryMap(Map<String, dynamic>.from(decoded));
}

/// Validate an already-decoded registry map.
SprintRegistryValidationResult validateSprintRegistryMap(
  Map<String, dynamic> root,
) {
  final errors = <String>[];

  if (!root.containsKey('schemaVersion')) {
    errors.add('Missing required top-level field: schemaVersion.');
  } else if (root['schemaVersion'] is! int) {
    errors.add('schemaVersion must be an integer.');
  }

  if (!root.containsKey('nextSprintNumber')) {
    errors.add('Missing required top-level field: nextSprintNumber.');
  } else if (root['nextSprintNumber'] is! int) {
    errors.add('nextSprintNumber must be an integer.');
  }

  if (!root.containsKey('sprints')) {
    errors.add('Missing required top-level field: sprints.');
    return SprintRegistryValidationResult(errors);
  }

  final sprintsRaw = root['sprints'];
  if (sprintsRaw is! List) {
    errors.add('sprints must be a JSON array.');
    return SprintRegistryValidationResult(errors);
  }

  final nextSprintNumber = root['nextSprintNumber'];
  final seenNumbers = <int>{};
  final prOwners = <int, int>{};
  SprintRecord? sprint003;
  SprintRecord? sprint009;
  SprintRecord? sprint010;
  var maxSprintNumber = 0;

  for (var i = 0; i < sprintsRaw.length; i++) {
    final item = sprintsRaw[i];
    if (item is! Map) {
      errors.add('sprints[$i] must be a JSON object.');
      continue;
    }

    final record = _parseSprintRecord(
      Map<String, dynamic>.from(item),
      index: i,
      errors: errors,
    );
    if (record == null) {
      continue;
    }

    if (!seenNumbers.add(record.number)) {
      errors.add(
        'Duplicate sprint number ${record.number}. '
        'Each sprint number must be unique.',
      );
    }

    if (record.number > maxSprintNumber) {
      maxSprintNumber = record.number;
    }

    if (record.number == 3) {
      sprint003 = record;
    } else if (record.number == 9) {
      sprint009 = record;
    } else if (record.number == 10) {
      sprint010 = record;
    }

    if (record.status == 'completed') {
      final hasPrs = record.pullRequests.isNotEmpty;
      final hasMerge =
          record.mergeCommit != null && record.mergeCommit!.trim().isNotEmpty;
      if (!hasPrs && !hasMerge) {
        errors.add(
          'Sprint ${record.number} is completed but missing completion '
          'evidence (pullRequests and/or mergeCommit).',
        );
      }
    }

    for (final pr in record.pullRequests) {
      final previousOwner = prOwners[pr];
      if (previousOwner != null && previousOwner != record.number) {
        errors.add(
          'Pull request #$pr is assigned to contradictory sprint records '
          '(Sprint $previousOwner and Sprint ${record.number}).',
        );
      } else {
        prOwners[pr] = record.number;
      }
    }
  }

  if (nextSprintNumber is int) {
    if (nextSprintNumber <= maxSprintNumber) {
      errors.add(
        'nextSprintNumber ($nextSprintNumber) must be greater than every '
        'recorded sprint number (max recorded: $maxSprintNumber).',
      );
    }
  }

  if (sprint003 == null) {
    errors.add(
      'Sprint 003 is missing. It must remain present as a deferred/archived '
      'historical identity and must never be reused.',
    );
  } else {
    _validateSprint003Identity(sprint003, errors);
  }

  if (sprint009 != null) {
    _validateSprint009Identity(sprint009, errors);
  }

  if (sprint010 != null) {
    _validateSprint010Identity(sprint010, errors);
  }

  return SprintRegistryValidationResult(errors);
}

class SprintRecord {
  const SprintRecord({
    required this.number,
    required this.title,
    required this.status,
    required this.pullRequests,
    required this.mergeCommit,
  });

  final int number;
  final String title;
  final String status;
  final List<int> pullRequests;
  final String? mergeCommit;
}

SprintRecord? _parseSprintRecord(
  Map<String, dynamic> map, {
  required int index,
  required List<String> errors,
}) {
  final prefix = 'sprints[$index]';
  var ok = true;

  final numberRaw = map['number'];
  int? number;
  if (numberRaw is! int) {
    errors.add('$prefix.number must be a positive integer.');
    ok = false;
  } else if (numberRaw <= 0) {
    errors.add('$prefix.number must be a positive integer (got $numberRaw).');
    ok = false;
  } else {
    number = numberRaw;
  }

  final titleRaw = map['title'];
  String? title;
  if (titleRaw is! String) {
    errors.add('$prefix.title must be a non-empty string.');
    ok = false;
  } else if (titleRaw.trim().isEmpty) {
    errors.add(
      '$prefix.title must not be empty or whitespace-only '
      '(sprint ${number ?? '?'}).',
    );
    ok = false;
  } else {
    title = titleRaw;
  }

  final statusRaw = map['status'];
  String? status;
  if (statusRaw is! String) {
    errors.add('$prefix.status must be a string.');
    ok = false;
  } else if (!kAllowedSprintStatuses.contains(statusRaw)) {
    errors.add(
      '$prefix.status "$statusRaw" is unsupported. '
      'Allowed: ${kAllowedSprintStatuses.join(', ')}.',
    );
    ok = false;
  } else {
    status = statusRaw;
  }

  final prs = <int>[];
  final prsRaw = map['pullRequests'];
  if (prsRaw == null) {
    // Optional; treat missing as empty.
  } else if (prsRaw is! List) {
    errors.add('$prefix.pullRequests must be an array of positive integers.');
    ok = false;
  } else {
    for (var j = 0; j < prsRaw.length; j++) {
      final pr = prsRaw[j];
      if (pr is! int || pr <= 0) {
        errors.add('$prefix.pullRequests[$j] must be a positive integer.');
        ok = false;
      } else {
        prs.add(pr);
      }
    }
  }

  String? mergeCommit;
  final mergeRaw = map['mergeCommit'];
  if (mergeRaw != null) {
    if (mergeRaw is! String) {
      errors.add('$prefix.mergeCommit must be a string when present.');
      ok = false;
    } else {
      mergeCommit = mergeRaw;
    }
  }

  // Optional fields validated only for type when present.
  if (map.containsKey('notes') &&
      map['notes'] != null &&
      map['notes'] is! String) {
    errors.add('$prefix.notes must be a string when present.');
    ok = false;
  }
  if (map.containsKey('replacesOrResumes') &&
      map['replacesOrResumes'] != null &&
      map['replacesOrResumes'] is! int) {
    errors.add(
      '$prefix.replacesOrResumes must be an integer or null when present.',
    );
    ok = false;
  }

  if (!ok || number == null || title == null || status == null) {
    return null;
  }

  return SprintRecord(
    number: number,
    title: title,
    status: status,
    pullRequests: prs,
    mergeCommit: mergeCommit,
  );
}

void _validateSprint003Identity(SprintRecord sprint, List<String> errors) {
  if (sprint.status != 'deferred') {
    errors.add(
      'Sprint 003 was reassigned from its verified deferred historical '
      'identity (status must remain "deferred", got "${sprint.status}").',
    );
  }

  final titleLower = sprint.title.toLowerCase();
  const forbiddenFragments = <String>[
    'inspection list foundation',
    'engineering reliability',
    'node.js 24',
  ];
  for (final fragment in forbiddenFragments) {
    if (titleLower.contains(fragment)) {
      errors.add(
        'Sprint 003 was reassigned from its verified deferred historical '
        'identity (title must not claim unrelated product/engineering scope: '
        '"${sprint.title}").',
      );
      break;
    }
  }
}

void _validateSprint009Identity(SprintRecord sprint, List<String> errors) {
  final titleLower = sprint.title.toLowerCase();
  final looksLikeReliability =
      titleLower.contains('engineering reliability') ||
      (titleLower.contains('reliability') && titleLower.contains('ci')) ||
      (titleLower.contains('developer workflow') && titleLower.contains('ci'));
  final looksLikeInspectionList = titleLower.contains(
    'inspection list foundation',
  );

  if (!looksLikeReliability || looksLikeInspectionList) {
    errors.add(
      'Sprint 009 must remain "Engineering Reliability, CI, and Developer '
      'Workflow Baseline" (or equivalent Engineering Reliability/CI title). '
      'Got: "${sprint.title}".',
    );
  }
}

void _validateSprint010Identity(SprintRecord sprint, List<String> errors) {
  final titleLower = sprint.title.toLowerCase();
  final hasNode24 =
      titleLower.contains('node.js 24') || titleLower.contains('nodejs 24');
  final hasCheckout = titleLower.contains('checkout');

  if (!hasNode24 || !hasCheckout) {
    errors.add(
      'Sprint 010 must remain the Node.js 24 / actions/checkout compatibility '
      'sprint. Got: "${sprint.title}".',
    );
  }
}
