---
description: Start a Work Item from origin/main using a descriptive slug to name the branch/Draft PR. Never merge.
---

# start-work-item

Argument: descriptive work slug only (`$ARGUMENTS`), used to name the branch and Draft PR work record.

Example: `equipment-list-filter` → branch `cursor/equipment-list-filter`.

A slug or ordinary short task description is **never** the frozen assignment.

1. Load and follow the `ironsight-work-item` skill (Pre-Work-Item gate + complete frozen assignment).
2. Locate the **complete founder-approved assignment** in the current prompt/context. It must include scope, exclusions, acceptance criteria, safety boundaries, and required verification. A GitHub Issue is not required.
3. An alternative task specification qualifies **only** when it is founder-approved and contains all of those required assignment sections. Stop without creating a branch or modifying files if the assignment is missing, incomplete, contradictory, or ambiguous.
4. Use `$ARGUMENTS` only as the lowercase descriptive slug for branch `cursor/<work-slug>` (and the Draft PR work-record name). Do not treat the slug as scope.
5. Check open Draft PRs for overlapping files/scope; stop and report conflicts.
6. Ensure a clean tree; create the feature branch from latest `origin/main` (not diverged local `main`).
7. Implement only the frozen assignment scope (or stop after branch+Draft scaffolding if the user asked only to start).
8. Run `ironsight-verify`, then `ironsight-draft-pr` (one Draft PR targeting `main`; repeat frozen scope, exclusions, acceptance criteria, verification, assumptions, migration status in the PR body).
9. Do **not** update `management/AFK_AGENTS.md` (permanent policy only).
10. Never merge, never push to `main`. Gunnar merges manually.
