# Dealership Data-Use Clause — Draft Starting Point

**This is not legal advice and is not a finished contract.** This is a plain-language starting point, written by an AI assistant at the founder's request, intended to be reviewed, revised, and finalized by a qualified attorney before it appears in any real dealership agreement, terms of service, or master services agreement. Do not send this to a customer as-is.

## Why This Exists

Per `docs/00-ironsight-constitution.md` §9 (AI Philosophy) and `docs/15-final-product-specification.md` §10, IronSight AI's long-term value depends on being able to use inspection data — collected honestly, with the dealership's knowledge and agreement — to improve the product and, over time, train AI-assisted inspection (V2), a valuation engine (V3), and market intelligence features (V4). Because trade-in equipment inspected through WIW is often owned by a third party (the dealership's customer) at the moment of inspection, and because consent cannot be obtained retroactively for data already collected, this needs to be addressed in the **first** pilot dealership agreement — not added later.

## Plain-Language Draft

> **Data Use for Product Improvement and AI Development**
>
> 1. **What we collect.** In the course of providing the WIW inspection platform, IronSight AI collects and stores inspection data submitted by Dealership's authorized users, including but not limited to: equipment identification (make, model, year, serial number), photographs and video, hour meter readings, condition assessments, inspection notes, and — where Dealership chooses to provide it — transaction outcome data (trade and sale amounts).
>
> 2. **Dealership's ownership.** Dealership retains ownership of its inspection data. IronSight AI does not sell Dealership's raw, identifiable inspection data to third parties.
>
> 3. **License to IronSight AI.** Dealership grants IronSight AI a non-exclusive, worldwide, royalty-free license to use, reproduce, and analyze inspection data — including in de-identified and/or aggregated form — for the purposes of: (a) operating and improving the WIW platform; (b) developing, training, and validating artificial intelligence and machine learning features, including but not limited to automated damage/condition detection and equipment valuation models; and (c) producing aggregated, de-identified market insights, benchmarks, and analytics that do not identify Dealership or any specific customer without Dealership's separate written consent.
>
> 4. **De-identification for cross-dealership use.** Where inspection data is used in a manner that spans multiple dealerships (for example, aggregated market trend or benchmarking features), IronSight AI will remove or obscure information that would reasonably identify Dealership or its customers before such use, except where Dealership has separately and explicitly agreed to be identified (for example, in a benchmarking report Dealership requests for itself).
>
> 5. **Third-party equipment and customer data.** Dealership represents that it has the necessary rights, consents, or authority under applicable law to submit inspection data — including data relating to equipment owned by Dealership's customers at the time of inspection — to IronSight AI for the purposes described in this clause, consistent with Dealership's own customer agreements and applicable law.
>
> 6. **No sale of personal data.** IronSight AI does not sell personally identifiable customer information to third parties. This clause does not authorize the sale of individually identifiable customer data; it authorizes use of inspection data (including in de-identified/aggregated form) as described above.
>
> 7. **Survival.** This data-use license survives termination of the underlying services agreement with respect to data collected during the term, so that previously collected, properly de-identified data may continue to inform product improvement and model development after Dealership's relationship with IronSight AI ends.

## Open Questions for Counsel

These are flagged, not resolved, here — they require legal judgment, not engineering judgment:

1. Does this need to reference specific privacy law frameworks (e.g., state-level US privacy laws) given the equipment/customer data involved, even though this is B2B equipment data rather than classic consumer PII?
2. Should Dealership have an opt-out right for the AI-training use case specifically (separate from the core product-operation use case, which is presumably required just to run the software at all)?
3. Should there be a defined, named retention/deletion policy referenced here, consistent with `docs/08-security-compliance.md` §5 (30-day soft-delete before permanent purge)?
4. Does this need updating once V4's cross-tenant market intelligence product is actually designed (per `docs/09-multi-tenant-saas-strategy.md` §5), since that section already flags a separate legal/anonymization design pass as a prerequisite for V4 specifically?

## Status

**Draft only, pending attorney review.** Track finalization as an open task alongside the first pilot dealership agreement — see `docs/16-founder-approval-checklist.md` Decision #7.
