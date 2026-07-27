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

# Sprint 012 — Offline Inspection Workspace and Local Completion Flow

**Status (registry):** `active` (founder-approved parallel batch with Sprint 013). `pullRequests` left empty until both founder merges are reconciled. `nextSprintNumber` = **14**.

## Goal

Deliver a local-first inspection workspace so a rep can compose, score, review, and complete or discard an inspection entirely on-device without remote sync.

## Immutable scope

- Local inspection composition
- Local company/equipment context
- Inspection list
- Draft creation and reopening
- Quick scorecard
- Detailed category expansion
- Notes
- Review
- Local completion/discard

## Out of scope

- On-device serial/hour-meter OCR capture module (Sprint 013)
- Walkaround video
- Photo galleries
- Supabase inspection schema
- Remote sync or uploads
- Reports
- AI/vendor APIs
- Valuation
- Production access
- Videos

## Safety Rules

- Do not modify unrelated features.
- Do not refactor architecture.
- Do not invent additional backlog items.
- Do not mark Sprint 012 or 013 completed in shared registry files from this sprint alone.
- Use local Supabase by default when backend QA is needed.
- Never connect to production.
- Do not merge to `main`.

---

# Sprint 013 — On-Device Equipment Identification Capture

**Status (registry):** `active` (founder-approved parallel batch with Sprint 012). `pullRequests` left empty until both founder merges are reconciled. `nextSprintNumber` = **14**.

## Goal

Build a reusable offline equipment-identification capture module for serial numbers and hour-meter readings, with camera/OCR behind application-owned interfaces, explicit human confirmation, and always-available manual entry.

## Immutable scope

- On-device OCR for equipment serial numbers
- On-device OCR for hour-meter readings
- Camera/image acquisition behind an application-owned platform interface
- OCR processing behind an application-owned abstraction
- Business logic and general widgets must not call camera/OCR packages directly
- Present detected values as selectable candidates
- Never silently accept OCR output
- Require explicit human confirmation
- Always provide manual entry and editing
- Normalize whitespace and obvious formatting noise without changing meaningful serial characters
- Preserve letters, digits, leading zeros, and meaningful separators unless the user edits them
- Parse hour-meter candidates conservatively
- Reject negative hours
- Do not invent digits or automatically correct ambiguous values
- Handle multiple candidates
- Handle no text detected
- Handle permission denied
- Handle permanently denied permission with useful guidance
- Handle unavailable camera
- Handle capture cancellation
- Handle OCR failure
- Preserve manually entered data after failures
- Provide manual-entry fallback on unsupported platforms such as web/Brave
- Keep capture fully offline
- Make the module reusable by inspection and equipment workflows
- Do not integrate it into Sprint 012 screens

## UX requirements

- Camera-first and typing-last
- One-handed operation
- Large tap targets
- Clear selected and confirmed states
- Accessible labels
- Logical keyboard/focus order
- Manual fallback always visible
- No tutorial should be required
- Never imply OCR is authoritative
- Never show false success

## Out of scope

- Inspection list
- Draft creation
- Quick scorecard
- Detailed inspection
- Inspection review/completion
- Walkaround video
- Photo galleries
- Supabase inspection schema
- Remote sync or uploads
- Reports
- AI/vendor APIs
- Valuation
- Automatic unconfirmed saves
- Production access
- Videos

## Safety Rules

- Do not modify unrelated features.
- Do not refactor architecture.
- Do not invent additional backlog items.
- Do not implement or integrate Sprint 012 work.
- Do not mark Sprint 012 or 013 completed in shared registry files from this sprint alone.
- Do not require Supabase for this sprint.
- Never connect to production.
- Do not merge to `main`.

---

# Sprint 011 — Sprint Registry and Status-Consistency Guardrails

**Status (registry):** `completed` through **PR #13**. Historical record retained below.

## Goal

Correct stale operational documentation and establish one machine-readable sprint registry plus automated validation so sprint numbers cannot be silently reused or contradicted again. This sprint must not add product features.

## Immutable scope

- Reconcile verified facts in operational docs (`AFK_SPRINTS.md`, `DASHBOARD.md`, `CHANGELOG.md`, `WINS.md`, and other management files only when a verified contradiction exists).
- Add canonical `management/sprint_registry.json`.
- Add read-only Dart validator `tool/verify_sprint_registry.dart` (+ testable validation library) and focused tests.
- Wire the validator into `.github/workflows/ci.yml` without redesigning CI.
- Document a mandatory Pre-Sprint Status Gate and post-merge sync in `docs/DEVELOPER_WORKFLOW.md` / `AGENTS.md`.
- Narrowly update `.github/PULL_REQUEST_TEMPLATE.md` with registry checklist fields.

## Out of scope

- Inspection list UI; inspection synchronization; Supabase inspection migrations; product features; authentication/company/equipment changes; architecture rewrites; automatic commits after merge; bots that push directly to `main`; automatic merging; production access; publishing `local/status-draft-backup`; reassigning or deleting historical sprint records; videos.

## Verified history preserved by this sprint

- Sprint 003 remains deferred/archived; its number must never be reused.
- Sprint 008 is Inspection Local Foundation (merged through PR #9 lineage).
- Sprint 009 is Engineering Reliability, CI, and Developer Workflow Baseline (merged through PR #7) — never rename it “Inspection List Foundation.”
- Sprint 010 is Node.js 24 / actions/checkout compatibility (merged through PR #12).
- Do not invent or assign product Sprint 012 scope in this PR; after merge, Sprint 012 may be assigned via the Pre-Sprint Status Gate.

## Acceptance Criteria

- `management/sprint_registry.json` validates and records Sprint 011 as `completed` through PR #13 with `nextSprintNumber` = 12 (`mergeCommit` may be absent when unknown at PR time).
- Validator rejects duplicate numbers, unsupported statuses, invalid `nextSprintNumber`, missing/reassigned Sprint 003, Sprint 009/010 identity reassignment, contradictory PR ownership, empty titles, and completed sprints lacking all completion evidence; allows multiple active sprints; accepts PR-number-only completion evidence.
- CI runs the registry validator on PRs to `main`.
- Operational docs no longer instruct anyone to merge already-merged Sprint 009/010 work as unchecked long-lived tasks, and do not require an immediate Sprint 011 reconciliation PR after PR #13 merges.
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
