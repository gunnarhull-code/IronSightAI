# WIW V1 — Product Requirements Document (PRD)

## 1. Purpose

Define exactly what ships in V1: the fastest, easiest structured equipment inspection workflow, mobile-first, offline-capable, producing a professional report. This document is the contract for scope — anything not listed here is out of scope for V1 by default.

## 2. Personas

### Primary: Equipment Sales Representative ("the Rep")
Walks the lot or drives to a customer site to evaluate trade-in or consignment equipment. Needs speed above all else — every extra minute per inspection is a minute not spent selling. Often on a phone with mediocre signal. Not necessarily technical; the app must require zero training beyond a guided flow.

### Secondary: Used Equipment Manager ("the Manager")
Reviews inspections completed by reps, may complete inspections themselves, wants consistency across reps so trade-in decisions are comparable and defensible. Cares about report quality/professionalism when equipment info goes to a customer or lender.

### Tertiary (light V1 touch, full build in V2+/multi-tenant work): Dealership Admin
Sets up company account, invites/manages reps, may eventually configure report branding. V1 needs *just enough* admin capability to onboard a pilot dealership (invite users, see company inspections) — a full admin console is not a V1 deliverable.

## 3. Problem Statement

See [`01-executive-summary.md`](./01-executive-summary.md#the-problem). In PRD terms: reps have no structured, repeatable, offline-safe way to capture a complete equipment inspection and turn it into a professional deliverable in under 15 minutes.

## 4. V1 Goals

1. A rep can complete an entire inspection — video, serial, hour meter, guided checklist, report — from a single phone, start to finish, without needing connectivity at any point during capture.
2. Every inspection produces a consistent, professional PDF report suitable for internal use or handing to a customer/lender.
3. Data captured is structured (not free text dumps) so it is directly usable by V2 AI features and V3 valuation without re-collection.
4. Onboarding a new dealership (company) and its reps takes minutes, not IT tickets.

## 5. Non-Goals (Explicitly Out of Scope for V1)

- **No pricing or valuation output of any kind.** No suggested trade value, no comps, no market data. This is the single most important scope boundary in this document — do not let it creep in.
- No AI-based damage detection, image classification, or computer vision analysis of photos/video (V2).
- No voice-to-text note capture (V2 candidate).
- No customer-facing portal or e-signature workflow.
- No integrated payments/billing (V1 pilot dealerships are hand-onboarded, not self-serve/paid yet — billing readiness is architectural only, see [`09-multi-tenant-saas-strategy.md`](./09-multi-tenant-saas-strategy.md)).
- No desktop/web inspection experience (web, if any, is read-only report viewing at most).
- No integration with dealership DMS (Dealer Management System) or CRM. Noted as a strong V2/V3 candidate.
- No offline capability for anything other than the mobile inspection app (no offline web).

## 6. Functional Requirements

Each requirement below maps to a step in [`07-inspection-workflow.md`](./07-inspection-workflow.md).

### 6.1 Authentication & Company Context
- FR-1: A user signs in with email/password (Supabase Auth). Magic-link sign-in supported as a lower-friction alternative.
- FR-2: Every user belongs to exactly one company (dealership) in V1. (Multi-company membership is a documented future extension, not built now.)
- FR-3: A company admin can invite a new rep by email; the invited user sets a password on first login.
- FR-4: Session persists across app restarts; a signed-in rep can start an inspection while offline (cached auth session).

### 6.2 Equipment Identification
- FR-5: The rep selects equipment **category** (e.g., Excavator, Skid Steer, Wheel Loader — see [`12-equipment-taxonomy.md`](./12-equipment-taxonomy.md)) and **make** from a curated list (Caterpillar, Bobcat, John Deere, Komatsu, Doosan, Kubota, Case, Volvo, Takeuchi, Other).
- FR-6: Model is free-text entry with autocomplete suggestions where we have a known list for that make; always allows free entry (equipment coverage must never block on our taxonomy being incomplete).
- FR-7: Year, and an optional customer/stock reference number, may be entered.

### 6.3 Walk-Around Video
- FR-8: The app guides the rep through a structured walk-around video capture with on-screen prompts (e.g., "Front," "Left Side," "Rear," "Right Side," "Engine Bay," "Undercarriage/Tires," "Cab Interior") rather than one unguided continuous recording.
- FR-9: Video is saved locally immediately upon capture; no upload is required to proceed to the next step.
- FR-10: The rep can re-record any individual segment before finalizing.

### 6.4 Serial Number Capture
- FR-11: The rep points the camera at the serial number plate; on-device OCR (ML Kit) attempts to read it automatically, fully offline.
- FR-12: If OCR fails or is low-confidence, the rep can manually type the serial number. A photo of the plate is always retained as supporting evidence regardless of OCR success.
- FR-13: The captured serial number and its source photo are permanently attached to the inspection record.

### 6.5 Hour Meter Capture
- FR-14: The rep photographs the hour meter; OCR attempts automatic reading (offline) with manual override always available.
- FR-15: Hour meter photo is retained as supporting evidence.

### 6.6 Guided Inspection Checklist
- FR-16: The checklist is organized into fixed **sections** (e.g., Engine, Hydraulics, Undercarriage/Tires/Tracks, Cab & Controls, Attachments, Structural, Cosmetic/Paint).
- FR-17: Each checklist item captures: a condition rating (fixed scale, e.g., Good / Fair / Poor / N/A), an optional photo, and an optional free-text note.
- FR-18: The checklist structure is data-driven (stored in the database, not hardcoded in the app) so sections/items can be adjusted per equipment category without an app release.
- FR-19: The rep can save partial progress and resume the same inspection later (including after closing the app or losing connectivity).

### 6.7 Review & Report Generation
- FR-20: Before finalizing, the rep sees a summary review screen showing all captured data with the ability to jump back and edit any section.
- FR-21: On finalize, a professional PDF report is generated containing: equipment identification, serial number + photo, hour meter reading + photo, walk-around video reference (or key frames if video isn't embeddable in the PDF), full checklist results organized by section, rep name, dealership name/logo, and timestamp.
- FR-22: The report can be shared directly from the phone (share sheet: email, text, AirDrop, etc.) and is also stored in-app for later retrieval.
- FR-23: Report generation must succeed even if the phone regains connectivity only intermittently — generation should not require a large, fragile single network round trip (see [`03-technical-architecture.md`](./03-technical-architecture.md) for the sync-then-generate design).

### 6.8 Inspection Management
- FR-24: A rep can see a list of their own inspections (draft, pending sync, completed) with status indicators.
- FR-25: A manager/admin can see all inspections for their company (not just their own).
- FR-26: Inspections can be searched/filtered by equipment make, category, serial number, date, and rep.

### 6.9 Offline Behavior
- FR-27: Every capability in sections 6.2–6.7 must function with zero network connectivity. Only sign-in (first time on a device) and final report cloud-backup require connectivity.
- FR-28: When connectivity returns, all pending local changes and media sync to the cloud automatically, without requiring the rep to take any manual action.
- FR-29: The rep always has clear, honest visibility into sync status (e.g., "3 inspections pending upload") — never a false "all synced" state.

## 7. Key User Stories & Acceptance Criteria

**US-1:** *As a rep, I want to complete a full inspection with no cell signal, so that I'm not blocked at a rural job site.*
- AC: Airplane mode can be enabled for the entire duration of sections 6.2–6.7 with no errors, blocking spinners, or lost data.
- AC: Turning connectivity back on triggers automatic background sync within a reasonable interval without user action.

**US-2:** *As a rep, I want the serial number and hour meter read automatically when possible, so I don't have to type them.*
- AC: OCR attempt happens automatically on camera focus/capture; manual entry is always one tap away and never blocked.

**US-3:** *As a manager, I want every inspection to look the same regardless of which rep did it, so reports are comparable and defensible.*
- AC: The checklist structure and report template are identical for every rep in the company for a given equipment category.

**US-4:** *As a dealership admin, I want to invite my reps and see their inspections, so I can start using this with my team quickly.*
- AC: Admin can send an invite by email; invited rep can sign in and immediately see only their own company's data (verified against RLS, see [`08-security-compliance.md`](./08-security-compliance.md)).

## 8. Success Metrics (V1)

- Median time-to-complete-inspection ≤ 15 minutes.
- ≥ 95% of inspections started are completed (not abandoned) within the same visit.
- 0 reported data-loss incidents from offline usage during pilot.
- At least 1 pilot dealership actively using WIW for real trade-in evaluations by end of the 8–12 week MVP window.
- Qualitative: pilot reps prefer WIW to their prior manual process (measured via a short structured interview, not in-app survey, for V1).

## 9. Open Questions to Validate With Pilot Dealerships

These are intentionally left open for real-world validation rather than guessed at up front:

- Exact checklist section/item list per equipment category (V1 ships with a sensible default derived from industry-standard inspection forms; expect to iterate after the first pilot).
- Whether reps prefer a single continuous walk-around video with guided on-screen prompts, or discrete short clips per angle (V1 architecture supports either; UX will be validated early and can change without a data model change).
- Report layout/branding expectations from dealerships (logo placement, disclaimers, etc.).
