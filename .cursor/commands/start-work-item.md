---
description: Start a GitHub Issue Work Item from origin/main and open a Draft PR. Never merge.
---

# start-work-item

Argument: GitHub Issue number (`$ARGUMENTS`).

1. Load and follow the `ironsight-work-item` skill (Pre-Work-Item gate + frozen Issue scope).
2. Fetch the Issue with `gh`; treat it as the **complete assignment source** (identity, frozen scope, status). Stop if missing or ambiguous.
3. Check open PRs for overlapping files/scope; stop and report conflicts.
4. Ensure a clean tree; create a feature branch from latest `origin/main` (not diverged local `main`).
5. Implement only the Issue scope (or stop after branch+Draft scaffolding if the user asked only to start).
6. Run `ironsight-verify`, then `ironsight-draft-pr` (Draft targeting `main`, Issue linked).
7. Do **not** update `management/AFK_AGENTS.md` (permanent policy only).
8. Never merge, never push to `main`.
