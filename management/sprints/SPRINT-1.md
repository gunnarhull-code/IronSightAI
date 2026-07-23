# Sprint 1 Implementation Plan — Foundation

**Status**: Planning deliverable only. No application code has been written. This plan defines exactly what will be built during Sprint 1 and how — it does not redesign the product, revisit architecture, or propose new features. Every decision below traces to already-approved documentation.

**Source documents** (per the founder's instruction, these are the sources of truth for this plan): `docs/00-ironsight-constitution.md`, `docs/04-data-model.md`, `docs/07-inspection-workflow.md`, `docs/08-security-compliance.md`, `docs/13-roadmap.md`, `docs/15-final-product-specification.md`, `management/DASHBOARD.md`, `management/DECISIONS.md`. Where additional concrete detail was needed (e.g., the exact Flutter folder structure), it was pulled from other already-approved documents (`docs/06-mobile-app-spec.md`, `docs/03-technical-architecture.md`, `docs/10-tech-stack.md`) rather than invented — nothing here is a new architectural decision.

**Maps to**: `docs/13-roadmap.md`, "Weeks 1–2: Foundation." This document is the detailed engineering breakdown of that section; `docs/13-roadmap.md` remains the authoritative strategic roadmap and is not duplicated here — this document exists one level below it, for execution.

---

# Sprint Goal

Stand up the complete technical foundation for WIW V1 so that every subsequent sprint builds features on top of a working, secure, correctly-modeled system rather than infrastructure. By the end of Sprint 1: the Flutter app is scaffolded with the approved layered architecture, both Supabase projects exist, the full V1 schema is implemented with Row Level Security verified end to end, the local database is SQLCipher-encrypted from day one, and a signed-in user can see a real (empty) inspection list sourced from a genuine Supabase query — proving the entire client-to-backend pipeline works before any capture feature is built on top of it.

This is exactly the exit criterion already defined in `docs/13-roadmap.md`: *"a signed-in user can see an (empty) list of their company's inspections, and RLS has been manually verified to block cross-company access."*

---

# Deliverables

By the end of Sprint 1, the following will exist and be verified working:

1. Flutter project scaffolded with the approved layered architecture (`data` / `domain` / `features`, import boundaries enforced).
2. Riverpod wired as the app's state management / dependency injection mechanism.
3. Two Supabase projects provisioned (dev, production) per `docs/03-technical-architecture.md` §7.
4. The complete V1 Postgres schema from `docs/04-data-model.md` implemented as versioned migrations — every table, including the `completion_status`/`sync_status`/`report_status` split, the `checklist_template_items.parent_item_id` hierarchy, snapshot columns, `inspection_media.timestamp_markers`, `reports.shared_at`/`shared_via`, `equipment_transactions`, and `companies.region`.
5. Row Level Security policies implemented on every tenant-scoped Postgres table and on Storage (`storage.objects`), per `docs/08-security-compliance.md` §2 — including the narrower `equipment_transactions` policy.
6. RLS **manually verified** with a two-tenant test — not assumed.
7. Local `drift` database schema mirroring the server schema, encrypted with SQLCipher from the first migration (Founder Decision #2).
8. Secure on-device token storage (Keychain/Keystore) for the auth session.
9. Working authentication flow: email/password and magic-link sign-in, session persistence across app restarts.
10. Company/role context loaded and available app-wide after sign-in.
11. A navigation shell distinguishing signed-out vs. signed-in state.
12. A repository layer for `equipment` and `inspections` (read-only for this sprint) establishing the pattern every later feature follows.
13. A basic inspection list screen showing a correctly empty list, sourced from a real Supabase query.
14. Sentry error monitoring integrated.
15. A minimal CI pipeline (analyze + test + build on every push).

---

# Scope

## In Scope
- Flutter project setup and the layered architecture skeleton.
- Supabase project provisioning (dev + prod) and client integration.
- The full V1 schema (all tables) and RLS policies (Postgres + Storage), matching `docs/04` and `docs/08` exactly.
- SQLCipher-encrypted local database schema (structure only — no sync processing logic yet).
- The local `outbox` table structure (per `docs/04` §3) — created, not yet processed.
- Authentication (sign-in, session persistence, secure token storage, company/role context).
- A navigation shell and a read-only, empty-state inspection list screen.
- Sentry integration and a minimal build-only CI pipeline.

## Out of Scope
Everything below is explicitly deferred to a later sprint, per `docs/13-roadmap.md`'s own week boundaries — none of it is needed to satisfy Sprint 1's exit criterion, and building it now would be scope creep against the sprint goal:

- Camera/video capture, the continuous walkaround module, OCR for serial/hour-meter (`docs/13` Weeks 3–5).
- The Quick Condition Scorecard and Detailed Inspection UI, and the checklist rendering logic (`docs/13` Weeks 5–7).
- Sync engine processing logic (outbox draining, media upload queue, conflict resolution) — the table exists this sprint, but nothing reads or writes to it yet (`docs/13` Weeks 5–7).
- Report generation, the `generate-report` Edge Function, PDF rendering, native share sheet integration (`docs/13` Weeks 8–9).
- Company admin (invite-user), inspection list filters/search, pilot dealership onboarding (`docs/13` Weeks 10–12).
- Any V2/V3/V4 feature (AI assistance, valuation, market intelligence) — explicitly out of scope for all of V1, not just this sprint.
- Full Codemagic CI/CD automation and PostHog analytics — deliberately sequenced later per `docs/15-final-product-specification.md` §15.
- Any in-app UI for `equipment_transactions` — schema-only for all of V1 per Founder Decision #4.
- Per-inspection GPS — deferred per Founder Decision #5; only `companies.region` is in scope.

---

# Task Breakdown

Tasks are ordered by dependency, not by estimated calendar time. A task should not begin until its dependencies are complete.

### Task 1 — Git repository and base project scaffold
- **Purpose**: Establish version control before any other work begins.
- **Dependencies**: None.
- **Complexity**: Small.
- **Expected outcome**: Repository confirmed/initialized; `.gitignore` configured for Flutter/Dart build artifacts and secrets (`.env`, API keys); existing `docs/` and `management/` content preserved untouched.

### Task 2 — Flutter project initialization
- **Purpose**: Create the runnable Flutter app skeleton everything else is built on.
- **Dependencies**: Task 1.
- **Complexity**: Small.
- **Expected outcome**: `flutter create` scaffold in place; app builds and runs (default screen) on at least one iOS and one Android target.

### Task 3 — Project architecture and folder structure
- **Purpose**: Establish the layered architecture mandated by `docs/15-final-product-specification.md` §15 ("only the data layer touches `drift` or the Supabase SDK; domain/UI layers depend on repository interfaces only") using the structure already specified in `docs/06-mobile-app-spec.md` §1 — this is existing, approved detail, not a new decision.
- **Dependencies**: Task 2.
- **Complexity**: Medium.
- **Expected outcome**: `lib/` structured into `app/`, `core/`, `data/` (local, remote, repositories, sync), `domain/` (entities, use_cases), `features/`, `shared_widgets/`; the import-boundary rule is documented in-repo (e.g., a README note or lint rule) so it's enforceable from the first feature built on top of it.

### Task 4 — State management / dependency injection setup
- **Purpose**: Wire up Riverpod as the app-wide state/DI mechanism per `docs/15` §14's technology stack decision.
- **Dependencies**: Task 3.
- **Complexity**: Small.
- **Expected outcome**: `ProviderScope` wraps the app; one trivial provider proves the pattern end to end.

### Task 5 — Supabase project provisioning (dev + prod)
- **Purpose**: Stand up the two separate Supabase projects required by `docs/03-technical-architecture.md` §7, so development never touches production data or keys.
- **Dependencies**: None (can proceed in parallel with Tasks 1–4).
- **Complexity**: Small.
- **Expected outcome**: Two Supabase projects exist; anon keys/URLs captured in environment configuration, never committed to source control (`docs/08-security-compliance.md` §7).

### Task 6 — Supabase client integration
- **Purpose**: Connect the Flutter app to the dev Supabase project.
- **Dependencies**: Task 4, Task 5.
- **Complexity**: Small.
- **Expected outcome**: `supabase_flutter` initialized; a trivial round-trip call succeeds from within the running app.

### Task 7 — Full V1 schema migration
- **Purpose**: Implement the entire approved data model as a single, versioned, reproducible migration set. Every later Sprint 1 task (RLS, auth context, the inspection list) depends on the schema being complete and correct from the start — this is the highest-leverage, highest-risk task in the sprint.
- **Dependencies**: Task 5.
- **Complexity**: Large.
- **Expected outcome**: One ordered set of versioned SQL migrations creates every table in `docs/04-data-model.md`: `companies` (with `region`), `user_profiles`, `equipment_categories`, `equipment_makes`, `equipment`, `inspections` (with the three-way status split), `checklist_templates`/`checklist_template_items` (with `parent_item_id`), `inspection_checklist_responses` (with snapshot columns), `inspection_media` (with `timestamp_markers`), `reports` (with `shared_at`/`shared_via`), `sync_conflict_log`, `equipment_transactions`. Migration set runs cleanly against a brand-new database, and every table/column is verified against `docs/04` line by line — not assumed correct.

### Task 8 — Row Level Security policies (Postgres tables)
- **Purpose**: Enforce the multi-tenant isolation boundary at the database layer, per `docs/08-security-compliance.md` §2 and the Constitution §10/§13 — a hard prerequisite before any real user data can safely exist in the system.
- **Dependencies**: Task 7.
- **Complexity**: Medium.
- **Expected outcome**: RLS enabled and policies applied to every tenant-scoped table exactly as specified in `docs/08` §2, including the narrower `equipment_transactions` read policy (managers/admins/owners only, no rep access).

### Task 9 — Row Level Security policies (Storage)
- **Purpose**: Enforce the same tenant boundary on Supabase Storage objects, per `docs/08` §2's explicit `storage.objects` policies — media must not be less protected than structured data.
- **Dependencies**: Task 7.
- **Complexity**: Small.
- **Expected outcome**: `inspections` Storage bucket created; select/insert policies applied matching the `{company_id}/{inspection_id}/...` path convention from `docs/03-technical-architecture.md` §6.

### Task 10 — RLS manual verification (two-tenant test)
- **Purpose**: Prove, not assume, that RLS actually blocks cross-company access — this is `docs/13-roadmap.md`'s explicit, named exit criterion for this phase.
- **Dependencies**: Task 8, Task 9.
- **Complexity**: Medium.
- **Expected outcome**: Two test companies and two test users created; manually verified that User A cannot read or write User B's company's rows or Storage objects, via direct query and via the app once auth exists (re-verified again after Task 18).

### Task 11 — Local `drift` database schema
- **Purpose**: Create the on-device SQLite schema mirroring the server schema, per `docs/04` §3, establishing the offline-first foundation even though full sync processing logic is a later sprint.
- **Dependencies**: Task 3, Task 7.
- **Complexity**: Medium.
- **Expected outcome**: `drift` tables defined mirroring every server table, plus the `sync_status`/`local_updated_at` bookkeeping columns and the `outbox` table structure (table exists; a processor that drains it is Sprint 3 per `docs/13` Weeks 5–7).

### Task 12 — SQLCipher encryption for the local database
- **Purpose**: Adopt on-device encryption from the very first migration, per Founder Decision #2 (`docs/00` §13, `docs/08` §3, `docs/15` §11) — deliberately not deferred, because retrofitting it onto a populated database later is materially harder.
- **Dependencies**: Task 11.
- **Complexity**: Medium.
- **Expected outcome**: The `drift` database opens through a SQLCipher-encrypted connection; verified that the raw `.db` file on disk is not plaintext-readable/queryable without the key, on both iOS and Android.

### Task 13 — Secure token storage
- **Purpose**: Store the Supabase session/refresh token in platform-native secure storage, per `docs/08` §1 — not shared preferences.
- **Dependencies**: Task 6.
- **Complexity**: Small.
- **Expected outcome**: `flutter_secure_storage` (or equivalent) integrated; token persistence verified across app restarts.

### Task 14 — Authentication flow
- **Purpose**: Implement sign-in and session handling, satisfying `docs/15` §7 (session usable offline after first sign-in) and `docs/08` §1 (password/magic-link, breach-list check).
- **Dependencies**: Task 6, Task 13.
- **Complexity**: Medium.
- **Expected outcome**: A rep can sign in via email/password or magic link; the session persists across app restarts and remains usable with connectivity off after the first successful sign-in.

### Task 15 — Company/role context loading
- **Purpose**: After sign-in, load the user's `user_profiles` row (`company_id`, `role`) so the rest of the app — and every RLS-aware query — has correct tenant/role context, per `docs/15` §6.
- **Dependencies**: Task 14, Task 8.
- **Complexity**: Small.
- **Expected outcome**: A signed-in session exposes `company_id` and `role` app-wide via a Riverpod provider; verified against the two test companies from Task 10.

### Task 16 — Navigation shell
- **Purpose**: Establish top-level navigation (sign-in → inspection list) so screens have a consistent place to live.
- **Dependencies**: Task 14.
- **Complexity**: Small.
- **Expected outcome**: Unauthenticated users see sign-in; authenticated users see the inspection list; route guarding works correctly in both directions.

### Task 17 — Repository layer (equipment + inspections, read-only)
- **Purpose**: Implement the repository abstraction for the two entities needed by the inspection list screen, establishing the exact pattern every later feature will follow, per `docs/15` §15's layering rule.
- **Dependencies**: Task 6, Task 11.
- **Complexity**: Medium.
- **Expected outcome**: `EquipmentRepository` and `InspectionRepository` interfaces plus Supabase-backed implementations exist; the domain/UI layers never import `supabase_flutter` or `drift` directly (spot-checked against Task 3's enforced boundary).

### Task 18 — Basic inspection list screen (empty state)
- **Purpose**: Prove the full client-to-Supabase pipeline end to end — the explicit Sprint 1 exit criterion.
- **Dependencies**: Task 15, Task 16, Task 17.
- **Complexity**: Medium.
- **Expected outcome**: A signed-in user sees a correctly empty list of their company's inspections, sourced from a real Supabase query through the repository layer — no mock or stub data.

### Task 19 — Sentry integration
- **Purpose**: Get crash/error visibility as early as possible, per `docs/15` §15's tool-sequencing principle ("Sentry as soon as there's a build to crash-report on").
- **Dependencies**: Task 2.
- **Complexity**: Small.
- **Expected outcome**: Sentry SDK integrated; a deliberately triggered test exception is confirmed visible in the Sentry dashboard.

### Task 20 — Minimal CI (build-only)
- **Purpose**: Ensure the app builds reproducibly from a clean checkout — full Codemagic distribution automation is explicitly deferred per `docs/15` §15.
- **Dependencies**: Task 2.
- **Complexity**: Small.
- **Expected outcome**: A CI job runs `flutter analyze`, `flutter test`, and a build on every push; the pipeline is green.

---

# Recommended Build Order

1. Git repository & base project scaffold (Task 1)
2. Flutter project initialization (Task 2)
3. Project architecture & folder structure (Task 3)
4. Dependency injection / Riverpod setup (Task 4)
5. Sentry integration (Task 19) — cheap to add now while the app is still trivial
6. Minimal CI (Task 20) — establish the safety net before real complexity arrives
7. Supabase project provisioning, dev + prod (Task 5)
8. Supabase client integration (Task 6)
9. Full V1 schema migration (Task 7) — the largest, highest-risk task; do not rush it
10. Row Level Security — Postgres tables (Task 8)
11. Row Level Security — Storage (Task 9)
12. RLS manual verification, two-tenant test (Task 10) — hard gate before proceeding
13. Local `drift` schema (Task 11)
14. SQLCipher encryption (Task 12)
15. Secure token storage (Task 13)
16. Authentication flow (Task 14)
17. Company/role context loading (Task 15)
18. Navigation shell (Task 16)
19. Repository layer — equipment + inspections (Task 17)
20. Basic inspection list screen (Task 18) — sprint exit criterion met here
21. Re-run the two-tenant RLS verification (Task 10) through the actual app UI, not just direct queries, as a final confirmation

---

# Git Milestones

Recommended commit points — each should be a clean, reviewable, independently buildable state:

1. `chore: flutter project scaffold`
2. `chore: layered architecture folder structure + import boundary notes`
3. `feat: riverpod provider scope wired`
4. `chore: sentry integration`
5. `ci: minimal analyze/test/build pipeline`
6. `chore: supabase dev/prod project config (env-based, no secrets committed)`
7. `feat: supabase client integration`
8. `feat: full V1 schema migration`
9. `feat: row level security policies (postgres tables)`
10. `feat: row level security policies (storage)`
11. `test: two-tenant RLS verification documented`
12. `feat: local drift schema (device mirror + outbox table)`
13. `feat: sqlcipher encryption for local database`
14. `feat: secure token storage`
15. `feat: authentication flow (sign-in, session persistence)`
16. `feat: company/role context provider`
17. `feat: navigation shell`
18. `feat: equipment + inspection repository layer`
19. `feat: inspection list screen (empty state) — sprint 1 exit criterion`
20. `test: re-verify RLS through app UI; sprint 1 sign-off`

---

# Testing Plan

| Deliverable | Unit tests | Widget/UI tests | Integration tests |
|---|---|---|---|
| Schema migration | — | — | Run migration against a clean ephemeral database; assert every table/column/constraint from `docs/04` exists as specified. |
| RLS policies (Postgres + Storage) | — | — | Two-tenant test harness (Task 10): User A cannot read/write User B's rows or Storage objects, via direct query. Codify as an automated integration test if feasible within the sprint; otherwise documented manual test repeated before sign-off. |
| Local `drift` schema + SQLCipher | Open encrypted DB, write/read a row, confirm success; confirm opening with the wrong/no key fails. | — | — |
| Repository layer | Mock the Supabase client; verify repository methods construct correct queries and map results correctly. Per `docs/15` §15 this is one of the two highest-priority test areas in the whole app (alongside sync logic, which is Sprint 3). | — | — |
| Authentication flow | — | Sign-in screen renders, validates input, surfaces errors correctly. | Full sign-in round trip against the dev Supabase project with a seeded test user; session persists across simulated app restart. |
| Company/role context | Given a signed-in session, the provider exposes `company_id`/`role` matching the seeded `user_profiles` row. | — | — |
| Navigation shell | — | Unauthenticated route access correctly redirects to sign-in; authenticated access reaches the inspection list. | — |
| Inspection list screen | — | Empty state renders correctly. | Signed in as Test Company A's user, the list shows zero rows even when Test Company B has inspections — this doubles as an RLS regression test at the UI layer, not just the database layer. |

---

# Definition of Done

Sprint 1 is complete only when **every** item below is checked:

- [ ] A fresh clone of the repository, followed by `flutter pub get` and one build command, runs the app successfully.
- [ ] The schema migration set runs cleanly against a brand-new Supabase project from zero.
- [ ] Every table and column from `docs/04-data-model.md` exists exactly as specified — verified by direct inspection, not assumed.
- [ ] Row Level Security is enabled on every tenant-scoped table and on the Storage bucket.
- [ ] The two-tenant test proves cross-tenant access is blocked, both via direct query and through the running app.
- [ ] The local `drift` database is SQLCipher-encrypted; the raw file is confirmed not plaintext-readable on both iOS and Android.
- [ ] A rep can sign in (email/password or magic link), and the session persists across an app restart.
- [ ] After sign-in, `company_id` and `role` are correctly loaded and available app-wide.
- [ ] The inspection list screen shows a correctly empty list backed by a real Supabase query — no mock or stub data.
- [ ] No domain or UI code imports `drift` or `supabase_flutter` directly (spot-checked against the enforced layering rule from Task 3).
- [ ] Sentry captures a deliberately triggered test error.
- [ ] CI runs analyze, test, and build on every push, and is green.
- [ ] `management/DASHBOARD.md` is updated to reflect Sprint 1 completion; `management/DECISIONS.md` is updated if any new implementation-level decision was made along the way; `management/CHANGELOG.md` records the sprint's completion.

---

# Risks

Risks specific to Sprint 1 (not the full project risk list, which was previously tracked in a since-removed standalone register and is now folded into `management/DASHBOARD.md`'s "Active Risks" section where still relevant):

1. **RLS misconfiguration.** A single missing or incorrect policy could silently leak cross-tenant data, and the entire multi-tenant security model depends on getting this right in Sprint 1.
   - *Mitigation*: Task 10's two-tenant verification is a hard gate, not an optional nicety — Sprint 1 is not done without it, and it is re-run through the app UI (not just direct queries) before sign-off.
2. **SQLCipher integration complexity.** Encrypted SQLite in Flutter has platform-specific build and key-management quirks on iOS vs. Android.
   - *Mitigation*: Task 12 is budgeted as Medium complexity, not Small; test on a real iOS device and a real Android device early, not only a simulator/emulator.
3. **Schema drift between the local `drift` schema and the Postgres schema.** If Task 11 doesn't perfectly mirror Task 7, later sync work (Sprint 3) inherits silent, hard-to-diagnose bugs.
   - *Mitigation*: Build the local schema directly from `docs/04`, not from memory of the Postgres migration; do a explicit field-by-field cross-check between the two schemas at the end of Sprint 1.
4. **Underestimating the full-schema task.** Task 7 covers eleven tables with several non-trivial approved refinements (status split, `parent_item_id` hierarchy, snapshot columns, `equipment_transactions`) in one sprint — a mistake here compounds into every later sprint.
   - *Mitigation*: Treat Task 7 as the sprint's critical path; review it against `docs/04` line by line before starting RLS work on top of it, rather than moving forward on an assumption it's correct.
5. **Solo-founder execution risk.** No second engineer is available to catch mistakes in real time.
   - *Mitigation*: This plan's Definition of Done is deliberately checklist-based and verification-heavy (proof, not confidence) specifically to compensate for the lack of a second reviewer — consistent with the Constitution's "the app never lies about its own state" principle applied to the development process itself.

---

# Deliverables for Sprint 2 (Preview Only — Not Planned in Detail Here)

Per `docs/13-roadmap.md`, "Weeks 3–5: Core Capture Workflow":

- Equipment selection screen, taxonomy seed data, and the non-blocking duplicate-serial-number check.
- Continuous guided walkaround video capture module, including the single-tap "Restart Walkaround" action and timestamp markers.
- Serial number scan: on-device OCR with candidate-chip confirmation and manual fallback.
- Hour meter capture: same OCR-plus-confirmation pattern.
- The write-side of the local repository layer and outbox scaffolding, built alongside these capture screens rather than after (per `docs/13`'s explicit note that retrofitting offline-first onto an online-first app is far more expensive than building it in from the start).

Sprint 2 will be planned in its own detailed document once Sprint 1's Definition of Done is fully satisfied.
