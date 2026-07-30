---
description: Fast-forward local main to origin/main. Stops if dirty. Never resets or discards.
---

# sync-main

Follow `docs/DEVELOPER_WORKFLOW.md` → Post-merge synchronization.

1. Confirm this IronSightAI repo path.
2. If `git status` is dirty, **stop** and report. Do not stash, reset, discard, or commit.
3. `git switch main`
4. `git fetch origin`
5. `git pull --ff-only origin main` — if diverged, **stop** and report local-only vs remote-only commits. Do not merge, rebase, or reset unless the user explicitly instructs.
6. Report: full path, branch, `git log -1 --oneline`, whether `HEAD` equals `origin/main`, and `git status`.
