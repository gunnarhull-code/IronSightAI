# Active AFK Sprints

This file describes approved sprint work for Cursor Cloud Agents.

Rules:

- Agents may only work on assigned active sprint scopes recorded in [`management/sprint_registry.json`](./sprint_registry.json).
- Multiple sprints may be active simultaneously when they have unique numbers and independent, non-overlapping scopes.
- Agents may not invent additional work.
- Agents must follow `AGENTS.md`.
- Agents stop after completing their assigned sprint.
- GitHub draft PRs represent work in progress. **Live PR and CI status belongs to GitHub** and must not be duplicated here as a long-lived unchecked task.
- A merged PR means the sprint deliverable landed on `main` only after the founder merges it.
- Agents never merge to `main`. The founder performs every merge.
- Sprint history is immutable. Do not rename, reuse, replace, reopen, or modify any historical sprint number or completed sprint scope.
- Canonical machine-readable sprint numbers and lifecycle state live only in `management/sprint_registry.json`. Validate with `dart run tool/verify_sprint_registry.dart`.

---

# Sprint 011 — Sprint Registry and Status-Consistency Guardrails

## Goal

Correct stale operational documentation and establish one machine-readable sprint registry plus automated validation so sprint numbers cannot be silently reused or contradicted again. This sprint must not add product features.

## Immutable scope

- Reconcile verified facts in operational docs (`AFK_SPRINTS.md`, `DASHBOARD.md`, `CHANGELOG.md`, `WINS.md`, and other management files only when a verified contradiction exists).
- Add canonical `management/sprint_registry.json`.
- Add read-only Dart validator `tool/verify_sprint_registry.dart` (+ testable validation library) and focused tests.
- Wire the validator into `.github/workflows/ci.yml` without redesigning CI.
- Document a mandatory Pre-Sprint Status Gate and post-merge reconciliation in `docs/DEVELOPER_WORKFLOW.md` / `AGENTS.md`.
- Narrowly update `.github/PULL_REQUEST_TEMPLATE.md` with registry checklist fields.

## Out of scope

- Inspection list UI; inspection synchronization; Supabase inspection migrations; product features; authentication/company/equipment changes; architecture rewrites; automatic commits after merge; bots that push directly to `main`; automatic merging; production access; publishing `local/status-draft-backup`; reassigning or deleting historical sprint records; videos.

## Verified history preserved by this sprint

- Sprint 003 remains deferred/archived; its number must never be reused.
- Sprint 008 is Inspection Local Foundation (merged through PR #9 lineage).
- Sprint 009 is Engineering Reliability, CI, and Developer Workflow Baseline (merged through PR #7) — never rename it “Inspection List Foundation.”
- Sprint 010 is Node.js 24 / actions/checkout compatibility (merged through PR #12).
- Do not assign a product sprint after Sprint 011 in this PR.

## Acceptance Criteria

- `management/sprint_registry.json` validates and records Sprint 011 as `active` with `nextSprintNumber` = 12.
- Validator rejects duplicate numbers, unsupported statuses, invalid `nextSprintNumber`, missing/reassigned Sprint 003, Sprint 009/010 identity reassignment, contradictory PR ownership, and empty titles; allows multiple active sprints.
- CI runs the registry validator on PRs to `main`.
- Operational docs no longer instruct anyone to merge already-merged Sprint 009/010 work as unchecked long-lived tasks.
- `dart format`, `dart run tool/verify_sprint_registry.dart`, `flutter analyze`, and `flutter test` pass.
- Draft PR opened targeting `main`; never merged by the agent.

## Safety Rules

- Do not modify unrelated features.
- Do not refactor architecture.
- Do not invent additional backlog items.
- Use local Supabase by default.
- Never connect to production.
- Use hosted `agent-sandbox` only when explicitly required.
- Stop if requirements are ambiguous or verified sprint history cannot be determined.
- Do not merge to `main`.
