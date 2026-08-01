---
name: ironsight-work-item
description: >-
  Start or continue an IronSight Work Item from a founder-approved Cloud Agent
  prompt: run the Pre-Work-Item Status Gate, freeze that prompt as the
  assignment, and keep scope immutable. Use when assigning, starting, or
  continuing Work Item / AFK / Cloud Agent work.
---

# IronSight Work Item

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Work Items + Pre-Work-Item Status Gate. Safety: `AGENTS.md`.

Read live sources (do not copy status into this skill):

1. The **founder-approved Cloud Agent prompt** — complete frozen assignment (identity, scope, exclusions, acceptance criteria)
2. `AGENTS.md` — safety rules
3. `management/AFK_AGENTS.md` — permanent AFK/Cloud **policy only** (never update it per Work Item)

## Pre-Work-Item Status Gate

Before starting or assigning a Work Item:

1. Working tree clean; stop if dirty (preserve work — never discard).
2. Sync from latest `origin/main` (`git fetch` + branch from `origin/main`).
3. Frozen assignment exists (founder-approved prompt or equivalent task description) with clear scope — stop if ambiguous.
4. Check open Draft PRs / active Work Items for file/scope overlap.
5. Open **one separate Draft PR** via `ironsight-draft-pr` using branch `cursor/<work-slug>`. Agents never merge to `main`. Gunnar merges manually.

Do **not** update `management/AFK_AGENTS.md` for assignments. GitHub Issues are not required.

## Rules

- Work only the frozen prompt scope; do not invent work.
- Multiple Work Items only when scopes do not overlap.
- The Draft PR is the unique live work record — repeat frozen scope, exclusions, acceptance criteria, verification results, assumptions, and migration status in the PR body.
- Historical sprints: `management/LEGACY_SPRINT_HISTORY.md` only — do not revive the registry.
- Live PR/CI status belongs to GitHub.
