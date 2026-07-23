# IronSight AI — Executive Summary & Product Vision

## Company

**IronSight AI** builds software for the heavy equipment dealership industry, starting with a mobile inspection tool and expanding into AI-assisted valuation and market intelligence.

## First Product: WIW ("What's It Worth")

WIW is a mobile-first, AI-ready heavy equipment inspection platform for equipment dealerships, used equipment managers, and sales representatives.

## The Problem

Heavy equipment salespeople inspect trade-in and used machines manually today:

- They walk around the machine taking scattered photos on their personal phone.
- They write free-form notes with no consistent structure.
- They estimate condition subjectively, with no standardized rubric.
- They manually cross-reference serial numbers, hour meters, and spec sheets.
- The output (if any) is an inconsistent internal document, not a professional deliverable.

This is **slow**, **inconsistent between reps**, **hard to audit**, and **produces no reusable data asset** for the dealership.

## The Solution — V1

A guided, mobile-first inspection workflow that lets a sales rep, in the field, with or without cell signal:

1. Record a structured walk-around video of the machine.
2. Scan the serial number (camera + on-device OCR, with manual fallback).
3. Capture the hour meter reading (photo + OCR/manual entry).
4. Complete a guided, structured inspection checklist (condition ratings + photos + notes per system: engine, hydraulics, undercarriage, cab, structure, cosmetics, attachments).
5. Generate a professional, shareable, branded inspection report (PDF).

**V1 is explicitly NOT a pricing or valuation engine.** V1's entire mission is to make the *inspection and documentation* step fast, consistent, and professional. Value and price estimation is a deliberately deferred capability (V3) that depends on having a large, structured corpus of consistent inspection data — which V1 exists to generate.

## Guiding Architecture Principles

These principles apply to every technical decision in this documentation set:

1. **Mobile-first.** The field experience (phone in a rep's hand, on a lot, possibly offline) is the primary product surface. Any future web/admin surface is secondary.
2. **Offline-first.** Equipment yards, rural dealership lots, and auction sites frequently have poor or no connectivity. Inspection creation must never block on a network connection.
3. **AI-ready by design, not AI-built-now.** V1 does not build damage detection or valuation, but every data structure (media, checklist responses, metadata) is designed so V2/V3 AI features can consume it without re-architecture or a data migration project.
4. **Multi-tenant SaaS from day one**, even though V1 will only run for a small number of pilot dealerships. Retrofitting tenancy into a single-tenant schema later is expensive and risky; designing for it now costs almost nothing extra.
5. **Lean operations.** One founder, AI-assisted development, no dedicated ops/SRE team. Favor managed services, convention over configuration, and boring, well-documented technology over cutting-edge complexity.
6. **Commercial-grade, not a prototype.** Production-quality code, real auth, real tenant isolation, real security — even in the MVP — because this software will hold a paying dealership's business data from day one.

## Target Customers

- Heavy equipment dealerships (independent and multi-location)
- Used equipment managers
- Equipment sales representatives

## Equipment Coverage (V1)

Caterpillar, Bobcat, John Deere, Komatsu, Doosan, Kubota, Case, Volvo, Takeuchi, and an extensible "Other" category covering additional construction equipment makes. See [`12-equipment-taxonomy.md`](./12-equipment-taxonomy.md) for the extensible data model behind this.

## Roadmap at a Glance

| Version | Theme | Depends on |
|---|---|---|
| **V1** | Fastest, easiest structured inspection workflow (this build) | — |
| **V2** | AI inspection assistance (auto-flag damage in photos/video, smart checklist suggestions, voice-to-text notes) | V1's structured media + checklist data |
| **V3** | Equipment valuation engine (condition-adjusted value estimates) | V1 data corpus + V2 damage signals + market comp ingestion |
| **V4** | Market intelligence platform (cross-dealer trends, benchmarking, subscription analytics tier) | V3 valuation engine + aggregated multi-tenant data |

Full detail: [`13-roadmap.md`](./13-roadmap.md).

## V1 Success Metrics

- Time to complete a full inspection: target **under 15 minutes** for an experienced rep (vs. 30-60+ minutes of unstructured manual work today).
- 100% of inspections produce a complete, shareable PDF report with zero missing required fields.
- Inspections created offline sync successfully with **zero data loss** once connectivity returns.
- At least one pilot dealership using WIW for real trade-in evaluations within the 8–12 week MVP window.

## Document Index

| Doc | Purpose |
|---|---|
| [`02-product-requirements.md`](./02-product-requirements.md) | V1 PRD — personas, user stories, functional requirements, scope boundaries |
| [`03-technical-architecture.md`](./03-technical-architecture.md) | System architecture, offline sync design, AI-ready data pipeline |
| [`04-data-model.md`](./04-data-model.md) | Postgres schema, multi-tenant RLS design, ER diagram |
| [`05-api-design.md`](./05-api-design.md) | Client/backend contract (Supabase + Edge Functions) |
| [`06-mobile-app-spec.md`](./06-mobile-app-spec.md) | Flutter app architecture, camera/video/OCR modules, offline engine |
| [`07-inspection-workflow.md`](./07-inspection-workflow.md) | Step-by-step UX flow for the guided inspection |
| [`08-security-compliance.md`](./08-security-compliance.md) | Auth, tenant isolation, encryption, data ownership |
| [`09-multi-tenant-saas-strategy.md`](./09-multi-tenant-saas-strategy.md) | Tenancy model, roles, billing readiness |
| [`10-tech-stack.md`](./10-tech-stack.md) | Concrete stack decision + justification |
| [`11-non-functional-requirements.md`](./11-non-functional-requirements.md) | Performance, reliability, cost, device support targets |
| [`12-equipment-taxonomy.md`](./12-equipment-taxonomy.md) | Make/model/category data model |
| [`13-roadmap.md`](./13-roadmap.md) | Week-by-week V1 plan + V2-V4 detail |
| [`14-pre-development-review.md`](./14-pre-development-review.md) | CTO pre-development review — conflicts, gaps, risks |
| [`15-final-product-specification.md`](./15-final-product-specification.md) | **Single source of truth** — consolidated, contradiction-resolved final spec |

See also [`00-ironsight-constitution.md`](./00-ironsight-constitution.md) — the company's founding principles, read before this document.
