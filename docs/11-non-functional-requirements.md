# Non-Functional Requirements

## 1. Performance

| Target | Metric |
|---|---|
| Camera-to-preview latency | < 300ms on reference mid-range Android device |
| OCR result returned | < 2 seconds after capture, on-device, no network |
| Local checklist save | Perceived-instant (< 50ms) — it's a local SQLite write, no network round trip |
| App cold start | < 3 seconds on reference device |
| Report generation (server-side, once online) | < 20 seconds for a typical inspection (target; validate against real media sizes during pilot) |

## 2. Reliability & Offline Guarantees

- **Zero data loss** for any inspection data or media captured while offline, across app restarts, OS-level app kills, and device reboots, as long as the local database file itself isn't lost (e.g., app uninstall) — this is the single hardest reliability requirement in the system and is treated as a release-blocking test case, not a nice-to-have.
- Sync must be **eventually consistent and resumable** — a partially failed sync (e.g., structured data synced, media upload interrupted) must resume cleanly on next connectivity, never require the rep to redo work.
- Local schema migrations must never destructively drop a rep's in-progress inspection data on an app update (see [`06-mobile-app-spec.md`](./06-mobile-app-spec.md) Section 5).

## 3. Scalability (Right-Sized for Stage, Not Over-Built)

V1/pilot targets — deliberately modest, since premature scale engineering would waste the limited solo-founder build budget:

- Tens of companies (dealerships), hundreds of active users, low thousands of inspections/month.
- Supabase's managed Postgres and Storage comfortably handle this scale on a Pro-tier plan with standard indexing (already reflected in the schema's index choices in [`04-data-model.md`](./04-data-model.md)).
- Revisit infrastructure choices (per the trigger conditions in [`10-tech-stack.md`](./10-tech-stack.md)) only once real usage data shows a genuine bottleneck — not speculatively.

## 4. Availability

- Target: match Supabase's platform SLA for the chosen tier; no additional custom high-availability engineering in V1 (e.g., no multi-region failover).
- Because the app is offline-first, a transient Supabase outage does **not** stop a rep from completing an inspection — it only delays sync/report generation. This is a meaningful availability advantage baked into the core architecture, not a separate HA investment.

## 5. Maintainability

- Single Flutter codebase, single Supabase project per environment, no bespoke infrastructure to operate — directly serving the "one founder, AI-assisted, no dedicated ops team" constraint.
- Enforced architectural boundaries (Section 1 of [`06-mobile-app-spec.md`](./06-mobile-app-spec.md)) keep the codebase navigable for both a solo founder returning to code after a break and an AI coding assistant working on an isolated slice of the app.
- All schema changes are version-controlled SQL migrations (Supabase CLI), never manual dashboard edits, so the schema's history is always reconstructable and reviewable.

## 6. Cost

- Target V1 monthly operating cost: **under $50/month** (Supabase Pro tier + Codemagic + Sentry/PostHog free tiers) during pilot phase — validated against the "low operating cost" priority.
- Cost drivers to monitor as usage grows: Storage (video is the largest consumer — Section 1 performance targets and the 720p/capped-bitrate decision in the mobile app spec directly manage this), database compute tier, Edge Function invocations (report generation).

## 7. Device Support Matrix

| Platform | Minimum version | Notes |
|---|---|---|
| iOS | iOS 14+ | Covers effectively all active iPhones as of 2026 |
| Android | Android 8.0 / API 26+ | Deliberately inclusive of older/mid-range devices common among field reps, not just flagship hardware |

Reference test devices: one current iPhone (founder's device) + one mid-range Android device (~2-3 year old hardware) acquired specifically for realistic field-condition testing before each pilot release.

## 8. Accessibility

- Baseline platform accessibility support (Dynamic Type/font scaling, sufficient tap-target sizes, adequate color contrast on condition-rating buttons) — full WCAG-level audit deferred, but not ignored, given large tappable controls are already a UX requirement for field use (gloved hands, bright sunlight) that happens to align well with accessibility best practice.

## 9. Localization

- V1 ships English-only (US construction-equipment industry terminology). Text is not hardcoded inline in a way that would block future localization (i.e., use a standard Flutter localization mechanism from the start, even with a single locale), avoiding a costly retrofit if IronSight AI expands internationally later.
