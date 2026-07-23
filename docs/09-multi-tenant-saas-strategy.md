# Multi-Tenant SaaS Strategy

Per the standing architecture principle "multi-tenant SaaS from day one," V1 is built on a real multi-tenant foundation even though it will initially run for a small number of hand-onboarded pilot dealerships, not as a self-serve product. This document defines the tenancy model and what's deliberately deferred until the business is ready to sell self-serve.

## 1. Tenancy Model

- **Tenant = Company (dealership).** Every user belongs to exactly one company in V1 (`user_profiles.company_id`). All business data (`equipment`, `inspections`, media, reports) is scoped to a company via `company_id` and enforced by Postgres RLS (see [`08-security-compliance.md`](./08-security-compliance.md)).
- **Shared infrastructure, isolated data** ("pool" model, not "silo" model) — all tenants share the same Supabase project/database, isolated logically via RLS rather than physically via separate databases per customer. This is the standard, cost-effective SaaS pattern at this stage and scales to hundreds of dealership tenants without infrastructure changes.
- **Future consideration**: a large enterprise dealership group could eventually warrant a dedicated (siloed) deployment for data-residency or contractual reasons — the schema design doesn't prevent this later (a company's data is already cleanly delineated by `company_id`, making a future export-to-dedicated-instance migration straightforward), but it is explicitly not built now.

## 2. Role Model (V1)

| Role | Capabilities |
|---|---|
| `owner` | Everything `admin` can do; only role that can be transferred/removed by another owner. First user created for a company is automatically `owner`. |
| `admin` | Invite/manage users, view all company inspections, manage company settings (logo, report footer) |
| `manager` | View all company inspections (not just their own), cannot manage users/settings |
| `rep` | Create/edit their own inspections only |

This maps directly to the RLS policies in [`08-security-compliance.md`](./08-security-compliance.md) and to FR-2/FR-3/FR-25 in the PRD. It is intentionally simple for V1 — no custom permission sets, no per-feature toggles. Extend only when a real pilot customer need justifies it.

## 3. Onboarding Model (V1 vs. Future Self-Serve)

- **V1**: Hand-onboarded. The founder (or an `invite-user` Edge Function call run manually) creates the company record and first `owner` user for each pilot dealership. No public sign-up flow yet — this is deliberate, since V1's goal is validating the workflow with a small number of design-partner dealerships, not acquiring volume.
- **Documented future path (not built now)**: a self-serve sign-up flow (create company → become owner → invite team) is a straightforward additive feature on top of the existing schema — no data model changes required, since `companies` and `user_profiles` already support it structurally.

## 4. Billing Readiness (Architectural Only — Not Built in V1)

No payment processing exists in V1. To avoid a costly retrofit later, the schema and architecture avoid decisions that would make billing hard to add:

- `companies.is_active` already exists as a simple kill-switch mechanism (usable manually today, wireable to a future subscription-status webhook later).
- Natural future integration point: a `subscriptions` table (Stripe customer/subscription IDs keyed by `company_id`) plus a Stripe webhook handled by a new Edge Function — additive, no changes to existing tables required.
- Per-tenant usage that might inform future pricing (inspections/month, active reps, storage consumed) is already derivable from existing tables (`inspections`, `user_profiles`, `inspection_media`) without new instrumentation — worth confirming during V2/V3 planning once a pricing model is chosen (e.g., per-seat vs. per-inspection vs. flat dealership tier).

## 5. Cross-Tenant Data (Future V4 Consideration)

V4 (Market Intelligence Platform) is the first feature that intentionally needs **aggregated, cross-tenant** data (e.g., "average condition ratings for 5-year-old Cat excavators across the network"). This is called out explicitly because it is architecturally different from everything else in this document, which assumes strict per-tenant isolation:

- Cross-tenant aggregation must go through a dedicated, carefully reviewed aggregation/anonymization layer (e.g., a scheduled job producing de-identified rollups into separate analytics tables), **never** a relaxation of the per-tenant RLS policies on primary operational tables.
- This also has direct legal/contractual implications (dealership data-use agreements must explicitly permit aggregated/anonymized use) that need product and legal input well before V4 is built — flagged here as a dependency, not solved in this document.

## 6. What's Explicitly Deferred

- Self-serve sign-up and onboarding flow.
- Per-tenant custom branding beyond logo + footer text (e.g., custom report templates, custom checklist sections per dealership) — noted as a plausible V2 differentiator once real pilot feedback identifies demand.
- Usage-based billing and Stripe integration.
- Enterprise features: SSO, dedicated/siloed deployment, custom SLAs, data residency options.
