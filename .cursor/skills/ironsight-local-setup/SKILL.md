---
name: ironsight-local-setup
description: >-
  First-time IronSight local setup: Flutter deps, .env, and local Supabase.
  Use when setting up the repo, missing .env, or starting local Supabase for app QA.
---

# IronSight local setup

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → First-time local setup / Toolchain.

1. Repo root; `flutter pub get`.
2. `cp .env.example .env` (required — declared Flutter asset). `.env.example` is local demo values only. Never put production credentials in `.env` or commit `.env`.
3. For app launch / backend manual QA only:
   - Docker running
   - `supabase start` from repo root
   - API `http://127.0.0.1:54321` · Studio `http://127.0.0.1:54323` · DB `127.0.0.1:54322`
   - Local reset: `supabase db reset` (**local only**)
4. Unit/widget tests need `.env` but do **not** need Supabase running (in-repo fakes).

Default environment is local Supabase. Never connect to production. Hosted `agent-sandbox` only when explicitly required.
