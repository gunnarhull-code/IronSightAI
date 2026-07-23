# Security & Compliance

**Synced with `docs/15-final-product-specification.md` following the founder approval review** (`docs/16-founder-approval-checklist.md`, Decisions #2 and #4). Two changes from the original version of this document: on-device encryption is adopted from V1 (Section 3), not deferred, and Storage policies are now specified explicitly (Section 2), not left as an implied equivalent to the Postgres policies.

IronSight AI is handling a dealership's business-sensitive data (equipment condition, trade evaluations, potentially customer references) from day one. This is treated as production-grade commercial software, not a prototype, per the standing engineering rules for this project.

## 1. Authentication

- Supabase Auth (GoTrue) issues short-lived JWTs on sign-in; the Flutter app securely persists the refresh token using platform-native secure storage (`flutter_secure_storage` — Keychain on iOS, Keystore-backed on Android), not plain shared preferences.
- Password policy: minimum length + breach-list check (Supabase Auth built-in `HaveIBeenPwned` check enabled).
- Magic-link sign-in supported as a lower-friction alternative for less technical reps.
- Session persists locally so a rep can start the app and begin an inspection while offline, as long as they've signed in at least once on that device (a hard requirement given the offline-first mandate — see FR-4).
- Future (V2+): SSO/SAML for larger dealership groups with existing IT identity systems — noted as a clean extension point since Supabase Auth supports SSO providers, not a redesign.

## 2. Multi-Tenant Isolation (Row Level Security)

This is the core security boundary for the entire system — **not client-side logic, but database-enforced policy.**

Representative policy pattern applied to every tenant-scoped table (`equipment`, `inspections`, `inspection_checklist_responses`, `inspection_media`, `reports`):

```sql
alter table inspections enable row level security;

create policy "company members can select their company's inspections"
  on inspections for select
  using (
    company_id = (select company_id from user_profiles where id = auth.uid())
  );

create policy "reps can insert inspections for their own company"
  on inspections for insert
  with check (
    company_id = (select company_id from user_profiles where id = auth.uid())
    and created_by = auth.uid()
  );

create policy "reps can update their own inspections; managers/admins can update any in their company"
  on inspections for update
  using (
    company_id = (select company_id from user_profiles where id = auth.uid())
    and (
      created_by = auth.uid()
      or (select role from user_profiles where id = auth.uid()) in ('manager', 'admin', 'owner')
    )
  );
```

**Storage policies get the same explicit rigor as the Postgres policies above** — raw inspection video/photos are, if anything, more sensitive than the structured rows describing them. Supabase Storage policies are ordinary Postgres RLS policies on the `storage.objects` table, matched against the `company_id` path segment in the object key (storage layout: [`03-technical-architecture.md`](./03-technical-architecture.md) Section 6, e.g. `inspections/{company_id}/{inspection_id}/...`):

```sql
create policy "company members can read their company's inspection media"
  on storage.objects for select
  using (
    bucket_id = 'inspections'
    and (storage.foldername(name))[1] = (
      select company_id::text from user_profiles where id = auth.uid()
    )
  );

create policy "company members can upload their company's inspection media"
  on storage.objects for insert
  with check (
    bucket_id = 'inspections'
    and (storage.foldername(name))[1] = (
      select company_id::text from user_profiles where id = auth.uid()
    )
  );
```

`storage.foldername(name)` splits the object path into an array of path segments, so `(storage.foldername(name))[1]` is the `{company_id}` segment of the path — the same tenant boundary enforced identically to every Postgres table.

**`equipment_transactions` gets a narrower read policy than most tenant tables**, consistent with it holding sensitive deal-financial data with no rep-facing UI in V1 (`04-data-model.md`, Founder Decision #4):

```sql
create policy "managers and admins can view their company's transaction outcomes"
  on equipment_transactions for select
  using (
    company_id = (select company_id from user_profiles where id = auth.uid())
    and (select role from user_profiles where id = auth.uid()) in ('manager', 'admin', 'owner')
  );
```

Reps have no policy granting them access to this table at all in V1 — not because they're untrusted, but because trade/sale financials aren't part of their workflow, and RLS should only grant what a role actually needs.

**Why this matters architecturally:** because RLS is the actual enforcement point, a bug in the Flutter app (or a modified/rooted client) cannot leak cross-tenant data — the database itself refuses the query. This is significantly more robust than "the app only shows you your own company's data" as a security model.

## 3. Data Encryption

- **In transit**: All Supabase traffic (Postgres, Storage, Auth, Edge Functions) is TLS-enforced by default.
- **At rest**: Supabase-managed Postgres and Storage are encrypted at rest by the provider.
- **On-device**: the local `drift` SQLite database is **encrypted with SQLCipher from Week 1** (Founder Decision #2, approved — reversing the original "defer it" posture of this section). Auth tokens are additionally stored in platform secure storage regardless. This was adopted early specifically because retrofitting encryption onto an app already holding real pilot data in the field would require a live migration of populated, in-use databases — meaningfully harder and riskier than configuring it once at the start.

## 4. PII & Data Sensitivity

V1's data is primarily equipment/business data, not consumer PII, which meaningfully reduces regulatory burden versus a consumer-facing product. Where PII does appear (optional customer reference fields, rep names/emails):

- Minimize collection — only what's needed for the workflow (no unnecessary customer PII fields in V1).
- Access to any given company's data is restricted to that company's users via RLS (Section 2).
- No PII is used in analytics events sent to PostHog — analytics track feature usage (e.g., "inspection completed," "OCR fallback used"), not equipment or customer identifiers.

## 5. Data Ownership & Export

- Each dealership (company) owns its own inspection data. Company admins can request/export their full inspection history (a straightforward Postgres query given `company_id` scoping) — this should be a built-in admin capability by the time of general availability, not just an ad hoc support request, both as good practice and as a trust-building sales point for dealership customers who are (rightly) wary of vendor lock-in.
- Account/company deletion follows a defined retention window (e.g., 30-day soft-delete before permanent purge) rather than instant hard deletion, to protect against accidental deletion.

## 6. Audit Trail

- `updated_at` timestamps and a no-hard-delete policy on inspection data (Section 4 of the data model doc) provide a baseline audit trail.
- `sync_conflict_log` preserves any discarded data from conflict resolution rather than silently dropping it (Section 4.3 of the architecture doc).
- Future (V2+): a dedicated `audit_log` table for admin actions (invites, role changes, deletions) if/when a dealership customer requires it for compliance reasons.

## 7. Secrets Management

- Supabase service-role keys (which bypass RLS) are used **only** inside Edge Functions, never shipped in the mobile app binary. The mobile app uses only the public anon key, which is safe to embed precisely because RLS is the real security boundary (Section 2).
- Environment-specific secrets (dev vs. production Supabase projects) are managed via Codemagic's encrypted environment variables and the Supabase CLI's local `.env` (excluded from source control via `.gitignore`), never committed.

## 8. Compliance Posture (Right-Sized for Stage)

- V1/pilot stage: no formal compliance certification pursued (SOC 2, etc.) — not warranted yet for a pre-revenue pilot with a handful of dealerships.
- **Documented now, revisited at scale**: as IronSight AI signs larger dealership groups (V4/multi-tenant SaaS growth), SOC 2 Type II is a realistic future requirement for enterprise sales. Because this architecture already enforces tenant isolation via RLS, encrypts data in transit/at rest, and avoids unnecessary PII collection, the gap to a future SOC 2 readiness assessment is materially smaller than it would be for a system designed without these principles from day one.

## 9. Incident Response (Lean Baseline)

- Sentry alerts the founder in real time on unhandled exceptions/crashes.
- Supabase project-level audit logging (available on paid tiers) provides a baseline of database/infra-level activity.
- A one-page incident response runbook (who to notify, how to rotate keys, how to communicate to pilot dealerships) should exist before the first paying customer goes live — flagged here as a pre-launch checklist item, not built as a document in this pass since it depends on finalized support/contact channels.
