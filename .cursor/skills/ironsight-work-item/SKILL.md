---
name: ironsight-work-item
description: >-
  Start or continue an IronSight Work Item from a complete founder-approved
  Cloud Agent assignment: run the Pre-Work-Item Status Gate, freeze that
  assignment, and keep scope immutable. Use when assigning, starting, or
  continuing Work Item / AFK / Cloud Agent work.
---

# IronSight Work Item

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Work Items + Pre-Work-Item Status Gate. Safety: `AGENTS.md`.

Read live sources (do not copy status into this skill):

1. The **complete founder-approved Cloud Agent assignment** in the current prompt/context — must include scope, exclusions, acceptance criteria, safety boundaries, and required verification
2. `AGENTS.md` — safety rules
3. `management/AFK_AGENTS.md` — permanent AFK/Cloud **policy only** (never update it per Work Item)

A descriptive slug or ordinary short task description must **never** substitute for that complete frozen assignment. Slugs name the branch / Draft PR only (`cursor/<work-slug>`).

## Pre-Work-Item Status Gate

Before starting or assigning a Work Item:

1. Working tree clean; stop if dirty (preserve work — never discard).
2. Sync from latest `origin/main` (`git fetch` + branch from `origin/main`).
3. Locate a complete founder-approved assignment in the current prompt/context (all required sections above). An alternative task specification qualifies only when it is founder-approved and contains those same sections. If missing, incomplete, contradictory, or ambiguous — **stop without creating a branch or modifying files**.
4. Check open Draft PRs / active Work Items for file/scope overlap.
5. Open **one separate Draft PR** via `ironsight-draft-pr` using branch `cursor/<work-slug>`. Agents never merge to `main`. Gunnar merges manually.

Do **not** update `management/AFK_AGENTS.md` for assignments. GitHub Issues are not required.

## Rules

- Work only the frozen assignment scope; do not invent work.
- Multiple Work Items only when scopes do not overlap.
- The Draft PR is the unique live work record — repeat frozen scope, exclusions, acceptance criteria, verification results, assumptions, and migration status in the PR body.
- Historical sprints: `management/LEGACY_SPRINT_HISTORY.md` only — do not revive the registry.
- Live PR/CI status belongs to GitHub.
