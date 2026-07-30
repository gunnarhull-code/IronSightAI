---
name: ironsight-verify
description: >-
  Run IronSight standard verification (format, analyze, tests) before reporting
  a task done or opening a Draft PR. Use when verifying, finishing a Work Item,
  or preparing a PR in IronSightAI.
---

# IronSight verify

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Standard verification.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Or `./scripts/verify.sh` (Git Bash/WSL). On Windows PowerShell, run the commands above.

Report exact results. Never claim a check passed unless it ran successfully. CI copies `.env.example` only; never applies migrations or touches production.
