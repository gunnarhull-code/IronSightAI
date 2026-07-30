---
name: ironsight-pre-work-item
description: >-
  Run the IronSight Pre-Work-Item Status Gate before assigning or starting a
  GitHub Issue Work Item. Use when assigning, starting, or scoping a new Work
  Item in IronSightAI.
---

# IronSight Pre-Work-Item Status Gate

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Pre-Work-Item Status Gate. Stop if the Issue scope is ambiguous — do not guess.

Before a new Work Item is started or assigned:

1. Local `main` clean (`git status` nothing to commit).
2. Local `main` matches `origin/main` (`git pull --ff-only origin main` / up to date).
3. A GitHub Issue exists with clear, immutable scope.
4. Check existing active Work Item scopes for file/scope overlap.
5. Update `management/AFK_AGENTS.md` when the work is AFK/Cloud Agent assigned.
6. Never push documentation commits directly to `main`. Agents open Draft PRs and never merge to `main`.

Historical numbered sprints are archived in `management/LEGACY_SPRINT_HISTORY.md`. Do not recreate `sprint_registry.json`.
