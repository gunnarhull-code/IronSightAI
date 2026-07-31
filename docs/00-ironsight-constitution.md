# The IronSight Constitution

**Read this before you write a line of code, design a screen, propose a feature, or make an architectural decision.**

This is not a technical specification. Technical specifications change — they get rewritten as we learn, as the market shifts, as the product matures. This document is different. It is the constitution of IronSight AI: the beliefs, priorities, and non-negotiables that every technical specification must answer to, not the other way around.

Every human engineer, every contractor, and every AI coding assistant that ever touches this codebase should read this first. When a technical document and this constitution disagree, this constitution wins, and the technical document should be corrected — not the other way around.

---

## 1. Mission

**To give every heavy equipment sales professional the fastest, most reliable way to inspect, document, and understand the equipment they sell.**

Today, that process is manual, inconsistent, slow, and produces almost nothing of lasting value beyond a single trade decision. We exist to replace guesswork and scattered paperwork with a professional-grade tool built for the environment our customers actually work in — a gravel lot, a customer's job site, an auction yard — not an office.

## 2. Vision

**IronSight AI becomes the trusted operating layer for heavy equipment intelligence.**

We start with inspection because inspection is the smallest problem we can solve completely, and because it is the foundation everything else depends on. We do not stay there. Over time, IronSight AI becomes the system dealerships, lenders, and eventually manufacturers turn to for ground truth on used equipment condition and value — not because we claimed that position, but because we earned it one honest, well-documented inspection at a time.

We are not building a feature. We are building an industry standard.

## 3. Our Core Product Promise

> **IronSight AI enables a sales rep to complete a useful Quick Appraisal in under two minutes using only their phone—even without internet—producing a trustworthy inspection package that makes human trade valuation and pricing easier and faster.**

This is not a marketing tagline. It is the design constraint every other decision is measured against. The MVP experience is **Quick Appraisal only** and must stay under two minutes (timing defined in `docs/15` §0). The MVP does **not** calculate or recommend a dollar value; it produces confirmed inspection evidence humans use for trade decisions. Expandable Detailed Inspection is **Later**, on a preserved shared checklist data model — it must never quietly re-enter the MVP default path. If a proposed feature, screen, or workflow step threatens that speed, the burden of proof is on the feature — not on the promise. If the path cannot meet two minutes, **reduce required work** rather than weaken the promise.

**Historical note:** an earlier approved wording used “just a few minutes” while retaining optional Detailed Inspection depth in V1 (Founder Decision #1). Work Item #18 restores the under-two-minute Quick Appraisal measuring stick and moves Detailed Inspection to Later — see `docs/15-final-product-specification.md` §0 / §19.

## 4. Product Philosophy

We build for a problem that is real, painful, and happens every single day — not a problem that is interesting to build software for. A good product decision at IronSight AI is judged by one question: **did this make a real inspection, performed by a real person, on a real machine, faster or more trustworthy?**

We measure product success by whether reps actually use the tool in the field, under real conditions — heat, rain, gloves, poor signal, a customer standing three feet away waiting — not by a feature checklist or a demo that only has to work once, indoors, with perfect Wi-Fi.

Every screen in this product must earn its place. If we cannot explain, in one sentence, why a screen exists and what it costs the rep in time, it does not belong in the product.

## 5. Field-First Design Principles

We build for people who work in the field, not in an office. This is the single most important lens we design and build through, and it is easy to forget if you are staring at a laptop in an air-conditioned room. Field-first means:

- The phone may be the only device the rep has, held in one hand, while the other hand is on the equipment, a clipboard, or a customer's handshake.
- Connectivity is not guaranteed. Rural lots, metal buildings, auction yards, and basements of dealerships routinely have no signal. **Offline is not an edge case we handle gracefully — it is the default condition we design for.**
- Sunlight glare, gloves, dust, and noise are normal operating conditions, not exceptional ones. Tap targets, contrast, and audio/visual feedback must work under these conditions, not just in a clean design mockup.
- The rep is not thinking about our app. They are thinking about the machine, the customer, and the next thing on their schedule. The app must never demand the rep's full attention for longer than the task strictly requires.

If a design decision would be reasonable for a desk-bound office worker but unreasonable for someone walking around a 40,000-pound machine in the rain, we reject the office-worker assumption every time.

## 6. Simplicity Over Complexity

Speed, reliability, and simplicity are more important than feature count. A dealership does not choose IronSight AI because we have the most features — they choose us because the features we have work every single time, in every condition, without training.

- **Every unnecessary tap, screen, or workflow step should be questioned — not eventually, immediately.** The default assumption for any new step is that it doesn't need to exist. Prove otherwise before adding it.
- We prefer one thing done extremely well over five things done adequately. A checklist with 8 fast, reliable categories beats a checklist with 40 thorough, slow ones — not because thoroughness has no value, but because a form nobody finishes has zero value.
- Convention over configuration. We would rather make a good default decision for the rep than hand them a settings screen.
- Complexity is a cost that compounds. A simple system a solo founder and an AI assistant can hold entirely in their head is worth more, at this stage of the company, than a sophisticated system that requires a team to operate safely.

## 7. Customer-First Decision Making

Every decision — product, technical, or business — is evaluated against one question: **does this help the dealership and the rep win business faster and with more confidence?**

Not: is this technically interesting? Not: is this what a "real SaaS company" would build? Not: what did a competitor ship last quarter? Our customers are busy professionals whose livelihood depends on turning inventory quickly and accurately. If a decision doesn't visibly serve that goal, it doesn't matter how elegant the underlying engineering is.

When a customer's real-world feedback conflicts with our own assumptions about what they need, the customer's lived experience wins, and our assumption gets revised — not defended.

## 8. Data Philosophy

Every piece of data we ask a rep to capture must justify its own existence. We do not collect data "because it might be useful someday" — every field in this product either serves the current workflow, or serves a **named, specific** future capability (a future version, a future feature) that we can point to. Speculative data collection with no identified consumer is a cost with no benefit, and we do not pay it.

At the same time, we recognize that some data can only ever be captured once, at the moment it happens, and can never be reconstructed retroactively. A serial number not scanned today cannot be scanned a year from now. A trade-in price not recorded at the moment of the deal is lost forever. Where a small amount of extra discipline today preserves an option we will certainly want later, we take it — deliberately, not by accident, and never at the cost of the speed of the default Quick Appraisal experience.

### Our Long-Term Strategic Advantage

IronSight AI is not just building an inspection application.

**We are building the industry's most trusted heavy equipment inspection dataset.**

Every inspection, every photo, every video, every confirmed serial number, every hour meter reading, every condition assessment, every repair estimate, and eventually every trade and sale contributes to a continuously improving body of knowledge about the real-world condition and value of heavy equipment.

Our long-term competitive advantage is not the software itself. Software can be copied. A well-designed screen can be cloned in a weekend by a competitor with enough funding. **What cannot be copied is a large, structured, trustworthy dataset built from thousands of real inspections performed by real professionals under real field conditions.** That dataset is what will power future AI valuation, market intelligence, benchmarking, predictive maintenance insights, and products we haven't imagined yet.

The application is how we collect high-quality data. The data is the company.

### The IronSight Data Flywheel

This is how the platform compounds in value over time, and why data quality is never a secondary concern:

```
        Professional Inspection
                 ↓
         Higher Quality Data
                 ↓
          Better AI Models
                 ↓
        More Accurate Insights
                 ↓
          More Customer Trust
                 ↓
           More Inspections
                 ↓
          Better Data  (cycle repeats, compounding)
```

Every principle in this constitution — field-first design, simplicity, the core promise, our security posture, our AI philosophy — exists in service of keeping this flywheel spinning. A faster, more reliable inspection tool means more inspections get done. More inspections done well means more high-quality, structured data. More data means better future AI models. Better models mean more accurate insights, which earns more customer trust, which drives more inspections. **This flywheel is the actual business.** The app is the mechanism that turns it.

## 9. AI Philosophy

AI is central to our long-term vision and may assist the MVP capture-and-review workflow as an **optional, advisory** aid — both halves of that sentence are deliberate.

- **AI assists people. AI never silently replaces professional judgment.** A rep's read on a machine, a manager's experience with a certain make, a dealership's institutional knowledge of their local market — these are not obstacles for AI to route around. They are exactly what AI should augment. Any AI feature that surfaces a suggestion, a flagged concern, or an estimate must always be presented as a suggestion a human confirms, never as a silent, unreviewable fact.
- **On-device OCR** assists serial-number and hour-meter capture. Optional photo recognition/autofill may use cloud AI when connected, only through a **backend provider-agnostic `AIService`** — Flutter/domain code never calls a vendor directly.
- **Walkaround video** may be captured as evidence; it is not AI-analyzed in the MVP.
- **AI is optional in the MVP and never blocks the inspection.** If AI or a provider is unavailable, the rep continues manually. Connectivity outages never prevent completing an offline inspection package.
- **AI never silently overwrites data and is never final authority.** Humans review, correct, and explicitly confirm final information before it becomes part of the permanent record.
- **Confirm, don't assume — always.** Wherever the product uses automation to make a rep's job faster (OCR; cloud photo suggestions), the automation's output is always presented to a human for confirmation before it becomes part of the permanent record. Speed comes from reducing effort, never from removing human accountability.
- **Vendor selection is not a frozen product-spec decision** — it is a later benchmark Work Item.
- **AI is a means to better data and better decisions — never an excuse to lower our standards for accuracy or trust.** A dealership will forgive a slow feature. They will not forgive being told an incorrect condition or value with false confidence.

**Historical note:** an earlier version of this section stated AI was “absent from our current product” and that Version 1 built zero AI features. Work Item #18 supersedes that for live MVP scope while retaining the assistive, human-confirmed principles above — see `docs/15-final-product-specification.md` §0 / §10.

## 10. Engineering Principles

- **Production-quality code, even in the MVP.** This software holds a paying dealership's business data from the very first pilot. "It's just an MVP" is never an excuse for cutting corners on data integrity, security, or reliability — those are exactly the things a real business is trusting us with.
- **Boring, well-understood technology beats novel, exciting technology.** We choose managed services and mature tools over custom infrastructure and cutting-edge frameworks, because our scarcest resource is founder/engineering attention, not compute or cleverness.
- **Offline-first is architecture, not an afterthought.** Given Section 5, this is not optional. The system is designed from the ground up so the field experience never depends on a network connection, and connectivity is treated as an intermittent convenience the system reconciles with, not a requirement it waits on.
- **Multi-tenant security is foundational, not a later migration.** We build for many dealerships sharing one system safely from the very first customer, because retrofitting real tenant isolation into a system built without it is one of the most dangerous and expensive mistakes a company at our stage can make.
- **The database is the source of truth for correctness; the client is the source of truth for speed.** Business rules and security boundaries live and are enforced on the server/database, never trusted from the client alone — but the client is architected so the rep never has to wait on the server to keep working.
- **Every schema change is a deliberate, versioned decision** — never a manual edit made under time pressure. Our data outlives any individual feature, release, or even founder; it is treated with the care that implies.

## 11. User Experience Principles

- **One-handed, glove-friendly, sunlight-legible.** Every interactive element is designed assuming the rep's other hand is occupied and their eyes are squinting at a screen outdoors.
- **Camera-first, typing-last.** Wherever a camera and on-device intelligence can replace typing (serial numbers, hour meters), it does — with a fast, honest confirmation step, never blind trust.
- **The app never lies about its own state.** If data hasn't synced, the app says so, clearly, always. A false "all synced" or "all good" message is one of the few mistakes in this product that can genuinely damage a customer's business (and their trust in us) — we treat honest status as a non-negotiable, not a nice-to-have.
- **Every workflow is resumable.** A rep can be interrupted at any moment — a customer walks up, the phone rings, the battery dies — and picking back up must never mean starting over or losing work.
- **The rep should never need training.** If a feature requires an onboarding tutorial to be usable in the field, the feature is not finished — it needs to be simplified, not documented.

## 12. Performance Standards

Speed is a feature, not an implementation detail, and it is measured from the rep's perspective, not a server's.

- Local actions (tapping a rating, saving a note, moving to the next screen) must feel instant — because they are local, and nothing about our architecture should make a local action feel like it's waiting on a network.
- The network is never a hard dependency for any step of the core inspection flow. If a spinner appears during inspection capture, that is a defect to fix, not a normal loading state to accept.
- We hold ourselves to **under two minutes** for Quick Appraisal as a real, testable target — measured from **Start Quick Appraisal** to confirm-complete, excluding login, first-time company onboarding, sync, and sharing (`docs/15` §0). We test it on real mid-range phones under realistic field conditions. If the path cannot meet two minutes, **reduce required work** rather than weaken the promise. Detailed Inspection is Later and is not part of the MVP timing budget.

## 13. Security & Trust

Trust is the actual currency of this business, arguably more than the software itself. A dealership is handing us their inventory data, their team's activity, and — over time — some of their most commercially sensitive information (trade values, condition assessments, customer interactions). We treat that trust as something to be earned continuously, not assumed.

- **A dealership's data belongs to that dealership**, always exportable, never held hostage, never seen by another dealership under any circumstance.
- **Tenant isolation is enforced at the data layer, not the application layer.** We do not rely on "the app only shows you your own data" as a security model — we rely on the database itself refusing unauthorized access, so that even a bug or a compromised client cannot leak one customer's data to another.
- **We collect the minimum data necessary**, and we are deliberate and transparent about anything beyond that minimum, especially where it touches a third party (a customer whose equipment is being traded in) rather than the dealership itself.
- **Security decisions are made assuming this company succeeds.** We build the tenant isolation, encryption, and audit posture appropriate for a company that will eventually serve hundreds of dealerships and be evaluated by their compliance teams — not just the handful of pilot customers in front of us today.

## 14. Version 1 Philosophy

**Version 1 is an inspection platform. It is not a valuation platform.** This sentence is short on purpose — it is the single most important scope boundary in the entire company, and it is the one most likely to be eroded by well-intentioned feature requests over time.

We resist adding pricing, valuation, or "estimated value" of any kind to V1, no matter how reasonable a single request sounds in isolation, because:

1. A valuation is only as trustworthy as the data underneath it, and V1's entire job is to build that data foundation.
2. Every hour spent on valuation logic in V1 is an hour not spent making the inspection itself faster, more reliable, and more widely adopted — which is the actual leverage point for the whole flywheel.
3. A dealership that trusts our inspection tool today because it is honest, fast, and does exactly what it says — nothing more — is far more likely to trust our valuation product tomorrow, when it's actually ready to be trusted.

Version 1 succeeds if reps use it every time, on every machine, because it is faster and more reliable than what they did before. It does not need to do anything else to be a success.

### Build for the Company We Intend to Become

Every architectural decision balances two objectives at once, and we do not let either one silently win by default:

1. **Deliver an exceptional MVP that solves today's customer problem** — a fast, reliable, trustworthy inspection tool that a rep genuinely prefers to their old process.
2. **Build a foundation that can evolve into the industry's leading heavy equipment intelligence platform** — without requiring a rebuild to get there.

We will **not** over-engineer Version 1 for hypothetical future needs. Multi-region infrastructure, configurable enterprise permission systems, and speculative data fields with no named consumer are examples of complexity we explicitly reject today, because they cost real time now for a benefit that may never materialize in the form we imagine.

We will **also not** make short-term decisions that permanently foreclose the company's long-term vision. A data field that can never be captured retroactively, a tenancy model that assumes only one company will ever use the system, an architecture that has no path to AI integration — these are the kinds of decisions we get right the first time, specifically because getting them wrong is expensive or impossible to fix later.

The test for any decision is not "is this simple" or "is this future-proof" in isolation — it is: **does this keep both objectives alive at once?** If a proposal only serves one of the two, it needs more work before it's ready.

## 15. Future Product Vision

Our roadmap is not a list of features — it is a sequence of trust-building milestones, each one only justified once the one before it has proven itself with real customers and real data. Live product sequencing is **MVP → V2 → Later** per `docs/15-final-product-specification.md` §0 / §16:

- **MVP (Quick Appraisal only):** earn the right to be in a rep's pocket every day by enabling a useful under-two-minute offline Quick Appraisal, with on-device OCR and optional cloud photo assist that humans always confirm. No dollar valuation; no Detailed Inspection UI; walkaround video is evidence only.
- **V2 (professional PDF share):** server-side PDF, local cache/download, reviewed native email/share draft.
- **Later:** Detailed Inspection on the preserved checklist model; summary-image renderer; company/manager portal; live collaboration or chat; manager review and approval; automated email workflows; historical equipment information; recon costs and additions; actual pricing/valuation recommendations; AI vendor benchmarking.

**Historical labels (V1 zero-AI inspection → V2 AI assistance → V3 valuation → V4 market intelligence)** remain in older docs as record; they must not override the live MVP / V2 / Later sequencing above.

## 16. Future AI Valuation Philosophy

When we do build valuation, it will be built on evidence, not guesswork, and it will be built to be trusted, not just to be impressive.

- **Valuation estimates are always explainable in terms a rep can repeat to a customer.** A number with no visible reasoning behind it is not a product a dealership can stand behind, and we will not ship one.
- **Valuation is assistive, not authoritative, for as long as it needs to be.** It starts as an estimate a manager reviews and adjusts with their own judgment and local market knowledge, exactly as our AI philosophy (Section 9) requires — a suggestion a human confirms, not a silent final answer.
- **Valuation earns trust the same way the inspection product did: incrementally, transparently, and only as fast as the data underneath it actually supports.** We will resist the temptation to ship valuation before the underlying inspection and outcome data genuinely justifies confidence in it.
- **The valuation engine's credibility is inherited from the inspection platform's credibility.** This is precisely why Section 14 exists — every shortcut we might be tempted to take in V1 is a debt that comes due, with interest, when we try to build valuation on top of it.

## 17. Development Principles

How we actually build, day to day, at IronSight AI:

- **Explain major decisions before implementing them.** Architecture and product trade-offs are discussed and understood before code is written, not discovered afterward in a diff.
- **Do not remove existing functionality without permission.** The person or agent making a change does not get to unilaterally decide something the founder relied on is no longer needed.
- **Prefer simple, scalable solutions over clever ones.** If a simpler design serves the same customer need, it is the correct design, even if a more sophisticated one is more interesting to build.
- **Comment and document complex logic.** Anything non-obvious — sync/conflict handling, RLS policies, OCR confidence heuristics — is explained in place, so the next person (human or AI) doesn't have to reverse-engineer intent from code alone.
- **Ask when requirements are unclear.** Guessing and building the wrong thing costs more than asking a clarifying question ever does. Silence is not an efficient default when the answer materially changes the outcome.
- **Review existing code and context before major changes, and explain the impact before making them.** We do not touch what we do not yet understand.
- **Keep security in mind by default, not as a separate review step bolted on at the end.**

## 18. Founder Principles

These describe how the founder operates, and what every collaborator — human or AI — should expect and match:

- **Bias toward real-world validation over internal theorizing.** A pilot dealership's actual experience with the product outranks any amount of internal speculation about what they might want.
- **A willingness to say no.** Most feature ideas — including good ones — are not for right now. Saying no to a reasonable idea in service of the current promise (Section 3) and current version's philosophy (Section 14) is a sign of discipline, not a missed opportunity.
- **AI coding assistants are a force multiplier, not a replacement for judgment.** They are expected to move fast and handle real engineering complexity — and also expected to stop and ask, explain trade-offs, and flag risk exactly as a trusted senior engineer would, per Section 17.
- **Long-term thinking without long-term excuses.** The company's ultimate ambition (Section 2, the Data Flywheel) is real and is allowed to influence today's decisions — but it is never used as an excuse to over-build, delay, or avoid shipping something customers need right now.
- **The founder's explicit decisions are the highest authority in this project.** Where this document, a technical spec, or an AI assistant's own judgment conflicts with an explicit founder decision, the founder's decision governs, and the documentation should be updated to reflect it — not worked around.

## 19. Final Decision Framework

When facing any non-trivial product, design, or technical decision, run it through these questions, in order. If a decision fails an earlier question, it doesn't matter how well it answers a later one.

1. **Does this serve the core promise?** (Section 3) — Does it keep Quick Appraisal under two minutes offline (per `docs/15` §0 timing), or does it cost time in the MVP path without a proportional gain in trust or data quality?
2. **Does this serve the rep, in the field, today** — not a hypothetical future user, not an internal stakeholder, not a competitor's feature list?
3. **Does this compromise trust or security** in any way — tenant isolation, data ownership, honesty about system state, or the line between AI assistance and human judgment?
4. **Does this needlessly foreclose a named future capability** (V2 professional PDF share; Later Detailed Inspection / portal / collaboration / valuation) for no benefit to today's customer — or, conversely, does it over-build for a future need that isn't real yet?
5. **Is this the simplest solution that fully answers questions 1–4?** If a simpler version exists that still passes, it is the correct version.

If a decision cannot clearly pass questions 1 through 3, it does not ship, regardless of how it scores on 4 or 5. Questions 4 and 5 exist to keep us honest about the balance in Section 14 — they do not override the customer, the promise, or trust.

---

## Non-Negotiable Principles (Read This Before Every Session)

Every future AI coding assistant, contractor, or engineer should treat the following as fixed unless the founder explicitly changes them in writing:

1. We are building software for people who work in the field, not in an office.
2. Every unnecessary tap, screen, or workflow should be questioned before it is added.
3. Speed, reliability, and simplicity are more important than feature count.
4. AI assists people. AI never silently replaces professional judgment.
5. Every inspection should improve both the customer's experience and the quality of our data.
6. Version 1 is an inspection platform, not a valuation platform — full stop.
7. We build only what creates customer value today, while laying a foundation that does not need to be rebuilt tomorrow.
8. The database enforces security and tenant isolation — never the client alone.
9. The app never lies about its own state (sync status, data completeness, or confidence in an AI-derived result).
10. When in doubt, ask the founder. Do not guess on anything that would be expensive or impossible to undo.

**We are not building an app. We are building the industry's most trusted heavy equipment inspection dataset, one honest, fast, professional inspection at a time.**
