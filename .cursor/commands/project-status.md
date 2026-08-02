---
description: Read-only project status — branch, open Draft PRs/CI, migrations, blockers, next action.
---

# project-status

Make **no** changes. Follow `AGENTS.md` and `docs/DEVELOPER_WORKFLOW.md`.

1. Report path, current branch, clean/dirty status, and relationship to `origin/main`.
2. Read `management/DASHBOARD.md` only as an occasional founder summary (not live Work Item status). Read `management/AFK_AGENTS.md` for permanent AFK/Cloud **policy only** (not assignments).
3. With `gh` (if authenticated): list open Draft/Ready PRs targeting `main` (these are the live Work Item records) and CI check status. Optionally note open Issues if present, but Issues are not required for work. If `gh` unavailable, say so and point to GitHub.
4. Note any open PRs that touch `supabase/migrations/**` (detect only).
5. Report blockers and the **next recommended action** (do not invent Work Items; next work comes from a founder-approved prompt).
