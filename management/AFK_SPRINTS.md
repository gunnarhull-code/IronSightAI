# # Active AFK Sprint

This file contains the single approved sprint for Cursor Cloud Agents.

Rules:

- Agents may only work on the active sprint.

- Agents may not invent additional work.

- Agents must follow `AGENTS.md`.

- Agents stop after completing the active sprint.

- GitHub draft PRs represent work in progress.

- A merged PR means the sprint is complete.

- No separate sprint status field is required.

- Sprint history is immutable. Do not rename, reuse, replace, reopen, or modify any historical sprint number or completed sprint scope.

---

# Sprint 009 — Engineering Reliability, CI, and Developer Workflow Baseline

## Goal

Establish a dependable engineering-verification baseline so future Draft PRs can be analyzed, tested, manually verified, and reviewed consistently without production access.

## Immutable scope

- Audit and correct stale workflow documentation (including false “no application code” claims).
- Establish one source of truth for local setup and verification (`docs/DEVELOPER_WORKFLOW.md`).
- Add GitHub Actions CI for PRs targeting `main` (controlled Flutter version, safe `.env` from `.env.example`, format check, analyze, test; no production Supabase, deployments, or automatic migrations).
- Review test bootstrap for accidental production/network/path/order coupling; add focused regression coverage only where needed.
- Add/improve the pull-request template with the required sprint verification fields.
- Document Windows + Brave launch, post-merge sync, and the production migration safety gate.
- Add lightweight workflow scripts only when they materially reduce mistakes.

## Out of scope

- Product features; inspection implementation/schema/persistence; equipment CRUD changes; feature database migrations; production deployments; automatic production migrations; store deployment; release automation; architecture rewrites; new state-management systems; broad dependency upgrades; large test-suite rewrites.

## Independence

Sprint 008 (inspection local foundation) is already merged on `main`. Sprint 009 must not modify inspection-domain implementation, inspection persistence, or inspection schema. Including those files via merge from `main` is expected; changing them for Sprint 009 is out of scope.

## Acceptance Criteria

- Developer workflow source of truth is clear and not heavily duplicated.
- CI fails clearly on format, analyze, test, or missing safe test configuration problems.
- PR template captures sprint verification fields.
- Windows/Brave, post-merge sync, and production migration safety gate are documented.
- `flutter analyze` and `flutter test` pass for this sprint’s changes.
- Draft PR opened targeting `main`; never merged by the agent.

## Safety Rules

- Do not modify unrelated features.

- Do not refactor architecture.

- Do not invent additional backlog items.

- Use local Supabase by default.

- Never connect to production.

- Use hosted `agent-sandbox` only when explicitly required.

- Stop if requirements are ambiguous.

- Do not merge to `main`.
