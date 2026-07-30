---
name: ironsight-afk-agent
description: >-
  Load IronSight AFK/cloud agent rules and read current assigned scope from
  AFK_AGENTS.md and the linked GitHub Issue. Use when starting or continuing an
  AFK agent run, Cloud Agent Work Item, or assigned Issue work.
---

# IronSight AFK / assigned Work Item

Do **not** copy Issue status into this skill. Always read live sources:

1. The assigned GitHub Issue — canonical Work Item identity and scope
2. `management/AFK_AGENTS.md` — human-readable AFK/Cloud Agent scope notes
3. `AGENTS.md` — safety rules

## Rules

- Work only the assigned Issue / Work Item scope.
- Multiple active Work Items allowed only with non-overlapping scopes.
- Do not invent additional work. Stop after the assigned Work Item.
- Historical numbered sprints are archived — never revive the sprint registry.
- Live PR/CI status belongs to GitHub — do not duplicate it as long-lived unchecked tasks in docs.
- Agents open Draft PRs and never merge to `main`. Founder merges.
- Before assigning a **new** Work Item, use the `ironsight-pre-work-item` skill.
