# Backlog

**Purpose**: capture ideas and features intentionally deferred from the MVP, so they're preserved rather than lost or forgotten — and so they don't quietly creep back into the current sprint. Everything here has already been deliberately excluded from V1 for a stated reason (see the linked source document for each item). Being in this backlog is not a promise anything will be built — it's a promise nothing good gets lost.

**Maintenance rule**: when a new idea comes up during development that isn't in scope right now, it goes here, not into the current work. When re-prioritizing, move items between priority tiers rather than deleting them. When an item is actually picked up, move it out of this file and into the appropriate place in [`docs/13-roadmap.md`](../docs/13-roadmap.md) (the single strategic roadmap), and note the move in [`CHANGELOG.md`](./CHANGELOG.md).

---

## High Priority

*Items likely to be picked up soon after pilot validation — either because pilot feedback is expected to demand them quickly, or because they unlock the next phase.*

- **In-app transaction-entry UI** for `equipment_transactions` — currently schema-only with manual/database entry (Founder Decision #4). Revisit once pilot usage shows who should realistically enter trade/sale outcomes and how it fits dealership workflow. *(`docs/15-final-product-specification.md` §9)*
- **Branded, tracked email delivery** ("Send via IronSight AI") — V1 uses the native share sheet only. Revisit if pilot dealerships specifically want delivery/open tracking. *(`docs/15-final-product-specification.md` §13, Founder Decision #6)*
- **True push notifications** (FCM/APNs + server-triggered webhook) for report-ready status — V1 uses in-app/foregrounded status only. *(`docs/15-final-product-specification.md` §12)*
- **DMS/CRM integration** — reduce redundant data entry with a dealership's existing systems. Named as a V2 candidate. *(`docs/13-roadmap.md`)*
- **Self-serve sign-up/onboarding flow** — V1 dealerships are hand-onboarded. Revisit when the business is ready to sell beyond a small set of pilot relationships. *(`docs/09-multi-tenant-saas-strategy.md` §3)*

## Medium Priority

*Real, planned capabilities that don't have urgency yet — worth tracking, not worth pulling forward.*

- **Per-inspection GPS capture** — V1 captures `region` at the company level only. Revisit if V3 planning or a specific multi-region dealership shows the coarser approximation isn't sufficient. *(`docs/15-final-product-specification.md` §9, Founder Decision #5)*
- **Voice-to-text inspection notes** — reduces typing in the field. Named V2 candidate. *(`docs/13-roadmap.md`)*
- **AI-assisted damage/wear flagging** on walkaround video and photos — always human-confirmed, never autonomous. The core of V2. *(`docs/00-ironsight-constitution.md` §9, `docs/13-roadmap.md` "V2 — AI Inspection Assistance")*
- **Billing / Stripe integration** — architecturally ready (`companies.is_active` as a kill-switch), not built. Revisit once a pricing model (per-seat, per-inspection, flat) is chosen post-pilot. *(`docs/09-multi-tenant-saas-strategy.md` §4)*
- **SSO/SAML enterprise auth** — Supabase Auth supports this as a clean extension point. Revisit when selling to a larger dealership group with existing IT identity systems. *(`docs/08-security-compliance.md` §1)*
- **Expanded Detailed Inspection content** — V1 ships a reasonable default set of Detailed sub-items per category; expect to expand/refine based on real pilot feedback about what dealerships actually want documented. *(`docs/15-final-product-specification.md` §5)*

## Low Priority

*Correctly out of scope for the foreseeable future — worth naming so no one re-litigates them from scratch, not worth actively planning.*

- **Full WCAG accessibility audit** and additional locales beyond English — baseline support only for now. *(`docs/11-non-functional-requirements.md` §8-9)*
- **Checklist template versioning system** — considered and dropped in favor of the simpler snapshot-on-write pattern; revisit only if a genuine multi-version content need emerges. *(`docs/14-pre-development-review.md` §3.1, `docs/15-final-product-specification.md` §9)*
- **Dedicated/siloed tenant deployment** for a large enterprise dealership group — the standard multi-tenant pooled model works today; revisit only if a specific enterprise contract requires data residency or isolation beyond it. *(`docs/09-multi-tenant-saas-strategy.md` §1)*
- **Formal compliance certification** (SOC 2 Type II, etc.) — not warranted for a pre-revenue pilot; revisit when enterprise dealership groups make it a sales requirement. *(`docs/08-security-compliance.md` §8)*
- **Media retention/cost optimization strategy** beyond "never auto-delete original media" — revisit once storage cost becomes material at real scale. *(`docs/14-pre-development-review.md` §5.5)*
- **Minimum supported app-version enforcement** — trivial engineering task, not a product decision; pick up opportunistically during any auth/sync work, no need to schedule it deliberately. *(`docs/14-pre-development-review.md` §2.7)*
- **Cross-tenant market intelligence aggregation** — the core of V4; explicitly requires its own legal/anonymization design pass before any engineering starts, and shouldn't be scoped in detail until V3 (Valuation Engine) is well underway. *(`docs/09-multi-tenant-saas-strategy.md` §5, `docs/13-roadmap.md` "V4 — Market Intelligence Platform")*
