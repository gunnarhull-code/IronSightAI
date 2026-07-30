---
description: Launch IronSight locally on Windows with Brave. Local Supabase only; never production.
---

# run-local

Canonical: `docs/DEVELOPER_WORKFLOW.md` → First-time setup + Windows/Brave launch.

1. Confirm path is `C:\Users\Ashle\Documents\IronSightAI` (or this repo’s Windows root). Stop if wrong.
2. If `.env` is missing, copy from `.env.example` only. Never use production secrets.
3. Check Docker / local Supabase (`supabase status` or start local stack if needed for app QA). Never connect to production or `agent-sandbox` unless explicitly required.
4. `flutter clean` then `flutter pub get`.
5. `$env:CHROME_EXECUTABLE="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"` (adjust if Brave path differs).
6. `flutter run -d chrome`.
7. On Cloud/Linux instead: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` (first load may be blank 15–30s).
