---
description: Start a Work Item from origin/main using a descriptive slug or task description and open a Draft PR. Never merge.
---

# start-work-item

Argument: descriptive work slug and/or task description (`$ARGUMENTS`).

Examples: `equipment-list-filter`, `docs-only: clarify offline sync notes`.

1. Load and follow the `ironsight-work-item` skill (Pre-Work-Item gate + frozen prompt scope).
2. Treat the founder-approved Cloud Agent prompt (or the provided task description) as the **complete frozen assignment**. Stop if missing or ambiguous. A GitHub Issue is not required.
3. Derive a lowercase descriptive slug for the branch: `cursor/<work-slug>` (from `$ARGUMENTS` when it is already a slug, otherwise from a short slug of the task).
4. Check open Draft PRs for overlapping files/scope; stop and report conflicts.
5. Ensure a clean tree; create the feature branch from latest `origin/main` (not diverged local `main`).
6. Implement only the frozen scope (or stop after branch+Draft scaffolding if the user asked only to start).
7. Run `ironsight-verify`, then `ironsight-draft-pr` (one Draft PR targeting `main`; repeat frozen scope, exclusions, acceptance criteria, verification, assumptions, migration status in the PR body).
8. Do **not** update `management/AFK_AGENTS.md` (permanent policy only).
9. Never merge, never push to `main`. Gunnar merges manually.
