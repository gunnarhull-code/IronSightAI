---
name: ironsight-work-item
description: >-
  Start or continue an IronSight GitHub Issue Work Item: run the Pre-Work-Item
  Status Gate, read the Issue as the full assignment, and keep scope frozen. Use
  when assigning, starting, or continuing Work Item / AFK / Cloud Agent Issue work.
---

# IronSight Work Item

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Work Items + Pre-Work-Item Status Gate. Safety: `AGENTS.md`.

Read live sources (do not copy status into this skill):

1. The **GitHub Issue** — complete assignment source (identity, frozen scope, status)
2. `AGENTS.md` — safety rules
3. `management/AFK_AGENTS.md` — permanent AFK/Cloud **policy only** (never update it per Work Item)

## Pre-Work-Item Status Gate

Before starting or assigning a Work Item:

1. Working tree clean; stop if dirty (preserve work — never discard).
2. Sync from latest `origin/main` (`git fetch` + branch from `origin/main`).
3. Issue exists with clear, frozen scope — stop if ambiguous.
4. Check open PRs / active Work Items for file/scope overlap.
5. Open a **Draft** PR via `ironsight-draft-pr`. Agents never merge to `main`.

Do **not** update `management/AFK_AGENTS.md` for assignments.

## Rules

- Work only the assigned Issue scope; do not invent work.
- Multiple Work Items only when scopes do not overlap.
- Historical sprints: `management/LEGACY_SPRINT_HISTORY.md` only — do not revive the registry.
- Live PR/CI status belongs to GitHub.
