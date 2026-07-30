---
name: ironsight-migration-safety
description: >-
  IronSight production migration safety gate: review SQL, dry-run, never auto-apply
  or reset production. Use when creating/editing supabase/migrations, discussing
  production schema, or dry-running db push.
---

# IronSight migration safety

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Production migration safety gate. Also follow `.cursor/rules/supabase.mdc` when editing `supabase/**`.

- Production migrations are **never automatic**.
- CI must not apply migrations or connect to production Supabase.
- Default to local Supabase; never `supabase db reset` against production.

Before any production schema apply:

1. PR with the migration is approved; manual testing complete.
2. Review SQL under `supabase/migrations/`.
3. Dry-run against the intended project:

```bash
npx.cmd supabase db push --dry-run
```

(macOS/Linux: `npx supabase db push --dry-run` after linking the correct project.)

4. Apply only after dry-run review — never casually.
5. In task report: migration filename(s), local vs `agent-sandbox`, remind founder to review/apply production manually.
