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

**Status (registry):** `active` (founder-approved parallel batch with Sprint 013). Pull-request evidence stays empty here until both founder merges are reconciled.

## Goal

Build a complete local-first inspection workflow on the Sprint 008 Drift foundation: tenant-scoped offline context, local equipment catalog, inspection list/capture/review/complete UI, and honest local-only status — without remote sync, media, OCR, or AI.

## Immutable scope

- Platform-safe application composition for the existing Drift inspection repository.
- Preserve SQLCipher-compatible encryption on supported mobile platforms.
- Persist tenant-scoped local company/user context needed for offline inspections.
- Prevent cached data from leaking between users or companies.
- Add a tenant-scoped local equipment catalog for inspection selection.
- Refresh equipment from the existing remote repository when connectivity is available.
- Inspection selection and capture must read locally and never wait for the network.
- Handle account/company changes safely.
- Add inspection routes and inject repositories from the composition root.
- Replace dashboard inspection placeholders with functional navigation.
- Enable Start Quick Appraisal.
- Add a company-scoped inspection list.
- Include loading, empty, populated, completed, draft, and recoverable error states.
- Start a draft from locally available equipment.
- Reopen active drafts.
- Address duplicate active drafts with an explicit Resume/Create Another decision or a safer documented rule.
- Render all existing scorecard categories in their established order.
- Provide large Good/Fair/Poor controls suitable for one-handed field use.
- Persist every rating immediately.
- Allow optional Detailed Inspection expansion per category using the existing domain model.
- Detailed inspection must remain optional and must not slow the default Quick Appraisal path.
- Persist detailed responses immediately.
- Add optional overall notes.
- Add a review screen showing equipment, category ratings, detailed responses, notes, and incomplete categories.
- Complete inspections locally and offline through existing lifecycle rules.
- Require confirmation before discarding an incomplete draft.
- Preserve completed/discarded mutation protections.
- Show honest local-only status; never imply synchronization occurred.
- Preserve drafts and completed inspections across app restart.
- Support Brave founder QA where practical without weakening mobile encryption.

## Out of scope

- Supabase inspection tables; SQL migrations; remote inspection synchronization; outbox processing; media upload; PDF/report generation; walkaround video; OCR or camera capture; AI; valuation; billing; team administration; production access; videos.
- Sprint 013 on-device equipment identification capture (serial/hour OCR, camera permissions, reusable capture module).

## Acceptance Criteria

- Local-first inspection list, start/resume draft, quick scorecard, optional detailed expansion, notes, review, complete, and discard confirmation work offline against Drift.
- Presentation/domain code does not import Drift or Supabase; widgets depend on repository/service interfaces.
- Tenant isolation covers local context and equipment cache; account/company switches do not leak cached data.
- Registry keeps Sprints 012 and 013 `active` with empty `pullRequests` until founder merge reconciliation; `nextSprintNumber` = 14.
- `dart format`, `dart run tool/verify_sprint_registry.dart`, `flutter analyze`, and `flutter test` pass.
- Draft PR opened targeting `main`; never merged by the agent.

## Safety Rules

- Do not modify unrelated features.
- Do not refactor auth/company/equipment architecture beyond narrow composition wiring.
- Do not invent additional backlog items.
- Use local Supabase by default.
- Never connect to production.
- Use hosted `agent-sandbox` only when explicitly required.
- Stop if safe offline equipment/company context requires a major architecture rewrite.
- Do not merge to `main`.

---

# Sprint 013 — On-Device Equipment Identification Capture

**Status (registry):** `active` (founder-approved parallel batch with Sprint 012). Pull-request evidence stays empty here until both founder merges are reconciled.

## Goal

Add on-device serial-number and hour-meter capture with OCR candidate confirmation, manual fallback, and reusable camera/OCR failure handling — without implementing Sprint 012 inspection workspace flows.

## Immutable scope

- On-device serial-number OCR.
- On-device hour-meter OCR.
- Candidate confirmation.
- Manual capture fallback.
- Camera/OCR permission and failure states.
- Reusable capture module.

## Out of scope

- Sprint 012 offline inspection workspace / local completion flow.
- Remote inspection sync; SQL migrations for inspections; media upload pipelines beyond capture needs; AI valuation; production access; videos as sprint deliverables beyond capture UX verification when required.

## Acceptance Criteria

- Serial and hour-meter capture support OCR candidates plus manual fallback with honest permission/failure states.
- Capture module is reusable and does not own inspection lifecycle completion rules.
- Registry keeps Sprints 012 and 013 `active` with empty `pullRequests` until founder merge reconciliation; `nextSprintNumber` = 14.
- Draft PR opened targeting `main`; never merged by the agent.

## Safety Rules

- Do not implement Sprint 012 scope.
- Do not modify unrelated features.
- Use local Supabase by default.
- Never connect to production.
- Do not merge to `main`.

---

# Sprint 011 — Sprint Registry and Status-Consistency Guardrails

**Status (registry):** `completed` through **PR #13**. Historical note: when Sprint 011 completed, `nextSprintNumber` was **12**. The founder-approved 012/013 parallel batch later advanced `nextSprintNumber` to **14**.

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
