# API Design — Client/Backend Contract

V1 has no hand-built REST backend. The Flutter app talks to Supabase through two channels:

1. **Direct table access via the Supabase client SDK** (PostgREST under the hood), secured entirely by Postgres Row Level Security — used for all standard CRUD on inspections, equipment, checklist responses, and media metadata.
2. **Supabase Edge Functions** for operations that must not run purely as client-side database writes — used for report generation, user invitations, and (in the future) AI inference calls.

This split keeps V1 simple (no backend to deploy/maintain beyond function code) while keeping a clean seam for anything that later needs to move to a custom backend or AWS Lambda.

## 1. Direct Table Access (PostgREST via `supabase_flutter`)

The mobile app uses the typed Supabase Dart client against the tables defined in [`04-data-model.md`](./04-data-model.md). Example operations (illustrative, not final code):

| Operation | Table(s) | Notes |
|---|---|---|
| Create equipment record | `equipment` | Client-generated UUID; RLS auto-scopes to caller's `company_id` |
| Start inspection | `inspections` | Status starts at `draft` |
| Upsert checklist response | `inspection_checklist_responses` | Unique constraint on `(inspection_id, template_item_id)` allows idempotent upsert-on-sync |
| Record media metadata | `inspection_media` | Written after the corresponding file finishes uploading to Storage |
| Fetch checklist templates | `checklist_templates`, `checklist_template_items` | Read-only reference data, cached locally after first fetch |
| List company inspections | `inspections` (+ joins) | RLS restricts reps to their own records, managers/admins to all company records (see [`08-security-compliance.md`](./08-security-compliance.md)) |

**Why this is safe without a custom backend:** RLS policies (not client-side logic) are the actual security boundary — every query is authorized by Postgres itself based on the caller's JWT, so there's no way for a compromised or modified client to read/write another company's data. See [`08-security-compliance.md`](./08-security-compliance.md) for the full policy set.

## 2. Supabase Edge Functions

All functions are Deno/TypeScript, deployed via the Supabase CLI, versioned in the application repo (not edited via dashboard), and invoked from the app via `supabase.functions.invoke(...)`.

### `POST /functions/v1/generate-report`
Generates the final PDF report for a completed inspection. Triggered automatically by the sync engine once all of an inspection's data and media have finished syncing (see [`03-technical-architecture.md`](./03-technical-architecture.md) Section 4.4).

**Request**
```json
{
  "inspection_id": "uuid"
}
```

**Behavior**
1. Verifies the caller's JWT has access to this inspection's `company_id` (defense in depth on top of RLS).
2. Loads inspection, equipment, checklist responses, and media references from Postgres.
3. Loads media files from Storage as needed (e.g., key frames, serial/hour-meter photos).
4. Renders a PDF using a server-side PDF generation library, applying the company's branding (`logo_url`, `report_footer_text`).
5. Uploads the PDF to `inspections/{company_id}/{inspection_id}/reports/`.
6. Inserts a row into `reports`.
7. Updates `inspections.status` to `report_generated`.

**Response**
```json
{
  "report_id": "uuid",
  "storage_path": "inspections/.../reports/report_v1.pdf"
}
```

**Errors**: `403` (not authorized for this inspection), `409` (inspection missing required data — e.g., no serial number captured), `500` (generation failure — inspection remains in `synced` status for retry).

### `POST /functions/v1/invite-user`
Allows a company `owner`/`admin` to invite a new rep or manager.

**Request**
```json
{
  "email": "rep@example.com",
  "full_name": "Jane Rep",
  "role": "rep"
}
```

**Behavior**: Verifies caller role is `owner` or `admin` for their company, calls Supabase Auth admin API to send an invite, pre-creates a `user_profiles` row linked to the invited auth user once they accept.

**Response**
```json
{ "invited": true, "user_id": "uuid" }
```

### `POST /functions/v1/finalize-inspection` (validation gate)
Optional but recommended: rather than letting the client flip `status` to `synced` directly, this function performs server-side validation (e.g., "serial number present," "at least one walkaround segment present," "all required checklist items answered") before allowing status transition — keeping business-rule enforcement server-side rather than trusting client logic, which matters once the report is a customer/lender-facing document.

**Request**
```json
{ "inspection_id": "uuid" }
```

**Response**
```json
{ "valid": true }
```
or
```json
{ "valid": false, "errors": ["Missing serial number", "2 checklist items unanswered"] }
```

## 3. Future Extension Points (Not Built in V1)

These are named now so V2/V3 Edge Functions slot in without redesigning this contract:

- `POST /functions/v1/analyze-media` (V2) — accepts an `inspection_media_id`, runs/queues AI damage-detection inference, writes structured findings to a new `ai_findings` table.
- `POST /functions/v1/estimate-value` (V3) — accepts an `inspection_id`, returns a valuation estimate once the valuation engine exists.
- `GET /functions/v1/market-trends` (V4) — aggregate, cross-tenant read endpoint for the market intelligence product, explicitly requiring a separate data-aggregation/anonymization design pass before it can touch multi-tenant data (see [`09-multi-tenant-saas-strategy.md`](./09-multi-tenant-saas-strategy.md)).

## 4. Realtime (Not Used in V1, Noted for V2)

Supabase Realtime (Postgres change feed) is available but intentionally unused in V1 — there's no multi-user concurrent-editing scenario yet (Section 4.3 of the architecture doc). It becomes relevant in V2+ if managers need a live dashboard of in-progress field inspections.
