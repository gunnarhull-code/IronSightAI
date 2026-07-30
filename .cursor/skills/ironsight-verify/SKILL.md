---
name: ironsight-verify
description: >-
  Run IronSight standard verification (format, analyze, tests) before reporting
  a task done or opening a Draft PR. Use when verifying, finishing a Work Item,
  or preparing a PR in IronSightAI.
---

# IronSight verify

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Standard verification. Do not invent alternate checks.

From the repo root, run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Or `./scripts/verify.sh` (Git Bash/WSL). On Windows PowerShell, run the commands above directly.

## Expected outcomes

- Format: exit 0 (no files need changes)
- Analyze: no issues (or only an understood missing-`.env` asset warning)
- Tests: all pass

Report exact commands and results. Never claim a check passed unless it ran successfully.

CI on PRs to `main` runs the same checks; it copies `.env.example` only and never applies migrations or touches production. The informational Supabase migration review workflow is separate.
