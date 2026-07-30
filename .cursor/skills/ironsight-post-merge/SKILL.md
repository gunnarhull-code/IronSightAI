---
name: ironsight-post-merge
description: >-
  Sync local main after a founder merges a PR. Use after a merge to main,
  post-merge sync, or before assigning the next Work Item.
---

# IronSight post-merge sync

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Post-merge synchronization.

```bash
git checkout main
git pull --ff-only origin main
git status
```

Expected `git status`:

```text
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

Open a follow-up Draft PR only if docs still contradict verified history after merge.

If the working tree is dirty: stop, review status, preserve work. Never discard changes without explicit permission. Never push documentation commits directly to `main`. Agents never merge.
