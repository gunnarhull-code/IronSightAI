---
name: ironsight-migration-safety
description: >-
  IronSight production migration safety gate: review SQL, dry-run, never auto-apply
  or reset production. Use when creating/editing supabase/migrations, discussing
  production schema, or dry-running db push.
---

# IronSight migration safety

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Production migration safety gate. Also `.cursor/rules/supabase.mdc` for `supabase/**`.

- Migrations are never automatic; CI must not apply them or connect to production.
- Default local Supabase; never `supabase db reset` against production.
- Before any production apply: approved PR + manual test → review SQL → `npx.cmd supabase db push --dry-run` → apply only after review.
- Report migration filenames, local vs `agent-sandbox`, and remind the founder to apply production manually.
