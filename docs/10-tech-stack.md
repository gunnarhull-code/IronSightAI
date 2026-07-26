# Tech Stack Decision Record

This document is the single source of truth for V1 technology choices and the reasoning behind them. Update it (don't fork it) as decisions evolve — it should always reflect "what we actually build with," not aspirational stacks.

## Decision Summary

| Layer | Choice | Alternative considered |
|---|---|---|
| Mobile app | **Flutter (Dart)** | React Native, native iOS/Android |
| Backend platform | **Supabase** (managed Postgres + Auth + Storage + Edge Functions + Realtime) | Firebase, custom AWS stack, custom Node/Nest backend |
| Local/offline database | **SQLite via `drift`** | Hive, Isar, sqflite raw |
| State management | **Riverpod** | Bloc, Provider, GetX |
| On-device OCR | **Google ML Kit Text Recognition** (on-device) | Cloud Vision API, Tesseract |
| Media capture | **Flutter `camera` plugin** + custom capture UI | `image_picker` only (rejected — insufficient control for guided walkaround) |
| PDF report generation | **Supabase Edge Function (Deno) using a server-side PDF library**, with a client-side fallback renderer | Fully client-side PDF generation |
| CI/CD | **GitHub Actions** for PR verification (format/analyze/test); **Codemagic** planned for Flutter store CI/CD later | Homegrown deploy scripts; Fastlane-only |
| Error monitoring | **Sentry** (free tier) | Firebase Crashlytics |
| Product analytics | **PostHog** (self-serve, generous free tier) | Mixpanel, Amplitude |
| Source control / issue tracking | **GitHub** (private repo) | GitLab |

## Why Flutter

The app's core value proposition lives entirely in the camera/media/OCR pipeline, and it must run identically well on iOS and Android for a mixed fleet of dealership-owned and personal phones, on a solo-founder budget.

- **Single codebase** — critical when one person (using AI coding assistance) owns the whole mobile app. Two native codebases would roughly double surface area for a team of one.
- **Camera/video maturity** — the `camera` plugin gives frame-level control needed for a *guided* walkaround capture (prompting the user through front/side/rear/engine bay/undercarriage shots) rather than a generic "record a video" button.
- **On-device ML Kit support** is first-class via `google_mlkit_text_recognition`, which runs **fully offline** — this is a direct enabler of the offline-first requirement (serial number and hour-meter OCR must work with zero connectivity).
- **Performance** — compiled to native ARM code, so video/camera-heavy screens stay smooth on the mid-range Android devices common in the field (not everyone carries a flagship iPhone on a job site).
- **Long-term maintainability** — a single Dart codebase with strong typing is easier for AI coding tools to reason about and modify safely than two divergent native codebases.

**Trade-off accepted:** Flutter has a smaller talent pool than React Native if IronSight AI eventually hires engineers. Mitigated by strict architectural conventions (see [`06-mobile-app-spec.md`](./06-mobile-app-spec.md)) that keep the codebase approachable to a new hire or contractor.

## Why Supabase for V1 (with an explicit AWS migration path)

Given **one founder, AI-assisted development, no dedicated ops team**, the top priority is minimizing infrastructure surface area while still building on a foundation that scales and migrates cleanly.

Supabase gives us, out of the box, with near-zero setup:

- **Postgres** — a real relational database (not a proprietary NoSQL store), which matters because the future valuation/market-intelligence products (V3/V4) will need real relational querying, joins, and eventually a data warehouse export. Postgres is also what most competent contract engineers already know.
- **Auth** — email/password + magic link out of the box, JWT-based, integrates directly with Postgres Row Level Security (RLS) for multi-tenant isolation (see [`09-multi-tenant-saas-strategy.md`](./09-multi-tenant-saas-strategy.md)).
- **Storage** — S3-compatible object storage for inspection photos/videos, with per-bucket access policies enforceable via the same RLS model.
- **Edge Functions** — Deno/TypeScript serverless functions for logic that must not run on the client (report generation, invite emails, future AI inference calls).
- **Auto-generated REST & Realtime APIs** (via PostgREST) — the Flutter app can talk to the database directly and securely (RLS-enforced) without us hand-writing and maintaining a full custom backend for V1.
- **Cost** — Free tier covers the pilot phase; Pro tier ($25/mo as of writing) comfortably covers V1 production usage. This is an operating-cost rounding error compared to running self-managed AWS infrastructure at this stage.

**Why this doesn't box us in:** Supabase is "just Postgres + S3-compatible storage + open tooling underneath."

- The database is standard Postgres — a `pg_dump`/`pg_restore` migrates it to AWS RDS or Aurora with no schema rewrite.
- Storage is S3-compatible — objects can be synced or re-pointed to real AWS S3.
- Edge Functions are just TypeScript/Deno — logic ports to AWS Lambda with moderate, not total, rewrite effort.
- Auth can be replaced with AWS Cognito or a self-hosted GoTrue (the same open-source auth server Supabase itself runs) if needed.

We are explicitly **not** using any Supabase feature that has no external equivalent (e.g., avoid deep coupling to proprietary extensions beyond standard Postgres/PostGIS-style extensions). This is documented as an architectural constraint in [`03-technical-architecture.md`](./03-technical-architecture.md).

**Trigger conditions for migrating off Supabase to AWS** (documented now so it's a deliberate decision later, not a scramble):
- Sustained cost at Supabase's pricing tiers exceeds equivalent self-managed AWS cost by a wide margin at scale, **or**
- We need infrastructure control Supabase doesn't expose (e.g., custom VPC peering with an enterprise dealership's IT systems, dedicated GPU inference infrastructure for V2/V3 AI models), **or**
- We need multi-region active-active deployment for enterprise SLA commitments.

## Why SQLite (`drift`) for the Local/Offline Layer

The offline-first requirement means the phone's local database is the **source of truth during an inspection**, not a cache. `drift` gives us:

- A real relational local schema (mirrors the Postgres schema structurally), type-safe generated Dart query code, and reactive streams that plug cleanly into Riverpod.
- Mature migration tooling for local schema changes as the app evolves.

## Why Riverpod

Compile-time-safe, testable, and works well with AI-assisted development because dependencies are explicit and discoverable (no hidden `BuildContext`-based lookups the way some `Provider` patterns encourage). It's the most common recommendation for new, maintainable Flutter apps as of 2026.

## What We Are Deliberately NOT Building in V1

- No custom backend server (Node/NestJS/FastAPI, etc.) — Supabase + Edge Functions cover V1's needs.
- No Kubernetes, containers, or self-managed infrastructure of any kind.
- No custom-trained AI/ML models (V2+).
- No native iOS/Android platform channels beyond what Flutter plugins already provide, unless a specific plugin gap forces it.
- No offline-capable web app — the offline requirement applies to the mobile app only; a future web admin console (V2+/V4) can assume connectivity.
