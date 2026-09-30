# Codex independent review, round 2: Phase B, Part B (revision 2)

**Date:** 2026-09-30 · **Reviewer:** Codex CLI 0.159.2 (read-only) · **Verdict:** not yet approved; 12/21 resolved, 9 partial, 6 new.

---

**Verdict: no.** Revision 2 is substantially stronger, but three original critical findings remain partially resolved: the health-storage boundary, recovery of health-derived progress, and deletion during concurrent sync. Several new consistency defects also need correction.

I reviewed the requested files and project context without modifying anything. Decisions **48–50 are constraints**, not findings. “Resolved” below means adequate at the architecture-foundation level, not proven by implementation.

File references: [16 — Architecture](</Users/mathis/AI Projects/Life Gamified/docs/master-plan/16-system-architecture.md>), [17 — Data model](</Users/mathis/AI Projects/Life Gamified/docs/master-plan/17-data-model.md>), [20 — Security](</Users/mathis/AI Projects/Life Gamified/docs/master-plan/20-security-privacy.md>), [22 — Workflow](</Users/mathis/AI Projects/Life Gamified/docs/master-plan/22-build-workflow.md>).

**A. Disposition of all 21 round-1 findings**

| # | Round-1 finding | Status | Justification |
|---|---|---|---|
| 1 | Health-data boundary | **Partially resolved** | Separate storage and conservative text classification help, but non-Body plans are still declared P despite containing text; projections use backed-up storage; exports lack consistent H2 filtering (16 B.5; 17 B.1/B.8/B.9). |
| 2 | Record-only reconstruction | **Partially resolved** | Immutable assessments exist, but phone-only recovery cannot identify lost Actions from unavailable samples; the Depth floor’s storage classification and recoverability remain unspecified (16 B.3/B.5; 17 B.3). |
| 3 | Deletion resurrection | **Partially resolved** | Durable intent and generations help, but checking generation before uploading is not atomic with the upload; deleting and recreating `Meta` also leaves an unsafe coordination gap (16 B.8–B.9). |
| 4 | App Attest versus anonymity | **Resolved** | Decision 48 authorizes the necessary pseudonymous state, now explicitly described with registration, counters and retention; the separate privacy-label error is listed below (16 B.7). |
| 5 | Relay reads prompts; missing consent | **Resolved** | Decision 49 removes frontier AI and personal prompts from the MVP Relay; future transient processing and explicit consent are acknowledged (16 B.4; 20 B.1/B.3). |
| 6 | Missing sync policy | **Resolved** | Transactional outbox, engine-state persistence, immutable conflicts, mutable-record policies, tombstones and account isolation are now explicit; deletion correctness remains finding 3 (16 B.8). |
| 7 | Late arrivals and time-dependent Vitality | **Resolved** | Explicit `asOf`, ingestion revisions, replay ordering, invalidation and refresh triggers address the original defect (16 B.3). |
| 8 | Permanent grants and Depth | **Partially resolved** | Entitlement identity and ownership/presentation separation are fixed; recoverable Depth floors remain unresolved, and the MVP Transformation policy still depends on deferred chapter 10 (16 B.3; 17 B.11). |
| 9 | Occurrence identity and corrections | **Partially resolved** | Keys and an explicit offline-swap limitation help, but plan revisions change occurrence identity, duplicate samples can still earn self-reported growth, and correction chains lack cycle/undo precedence rules (17 B.4/B.7). |
| 10 | Historical plan meaning | **Resolved** | Immutable plan revisions, versioned Action references and transactional revision/event creation address the original mutable-plan problem (17 B.3/B.8). |
| 11 | HealthKit evidence and write recovery | **Partially resolved** | Self-written samples stay self-reported and writes gain operation IDs; however, “external source + user-entered flag absent” still does not establish trusted sensor provenance (16 B.6). |
| 12 | Unsafe import contract | **Partially resolved** | Validation, bounds and merge rules exist, but exported tombstones and retired-generation history are unspecified, and atomic merge across the two stores has no defined recovery protocol (17 B.9). |
| 13 | Unavailable AI fallback | **Resolved** | Runtime checks, a non-generative baseline, queue expiry/cancellation and a chapter-07 task contract cover the MVP under decision 49 (16 B.4). |
| 14 | Safety and trustworthy sources | **Resolved** | Supplied-source validation, deterministic safety checks, fixed referrals and chapter-07 approval/evaluation gates establish the necessary foundation (16 B.4). |
| 15 | Ritual count meaning and late arrivals | **Resolved** | Installation-based meaning, server-derived de-duplication, atomic counting, acceptance deadline and consistent retention are specified (16 B.7; 20 B.2). |
| 16 | Scaling and AI spending | **Resolved** | A bounded MVP load and future sharding path are defined; paid AI spending is outside the MVP under decision 49 (16 B.7). |
| 17 | Missing failure tests and waiver authority | **Resolved** | Scenario gates and Mathis’s waiver authority now exist; the newly introduced environment restriction needs correction below (22 B.2–B.4). |
| 18 | Lived-day boundaries | **Partially resolved** | Civil-time calculation and stored settings help, but an adjustable 02:30 boundary makes the lived day advance, reverse, then advance during a repeated DST hour (17 B.6). |
| 19 | Ineffective privacy checks | **Resolved** | Runtime destination checks, adapter tests and prohibition of personal logging replace reliance on URL lint and redaction (20 B.3). |
| 20 | Contradictory module map | **Resolved** | Six targets and explicit orchestration provide the missing persistence, transport and projection dependencies for the MVP (16 B.2). |
| 21 | Unsupported platform claims | **Resolved** | Part B corrects PCC eligibility, uses runtime model capabilities, withdraws the unverified CloudKit throughput figure and removes the overstated SwiftData restriction (16 B.12; 17 B.1). |

For finding 21, Apple currently documents both PCC eligibility conditions and runtime context/token APIs. These corrections are supported by [Apple’s PCC requirements](https://developer.apple.com/private-cloud-compute/) and [Foundation Models documentation presented at WWDC26](https://developer.apple.com/videos/play/wwdc2026/241/).

The **three remaining critical defects** deserve explicit failure examples:

- **Health boundary:** A non-Body plan can contain health information in its instructions, yet 17 B.8 labels it P. A projection containing health-derived pillar values goes into `record.sqlite`, which receives ordinary backups. Classifying free text as H2 also does not enforce the separate prohibition against storing measurements embedded in that text. Define classification propagation through references, projections, queues, temporary files and exports; resolve contradictory field rules.
- **Recovery:** After losing the old phone, both a phone-only completion and its unavailable HealthKit sample may be gone. There is no surviving target entry to mark `unknown`. Keeping its Depth floor local loses the floor too; syncing that floor may reveal health-derived information. Decision 50 requires a concrete, permitted recovery representation and reconstruction algorithm. Calling the missing evidence “unknown” does not supply either. **Apple’s acceptance of such a representation remains uncertain.**
- **Deletion:** Device B fetches generation G; device A deletes G and creates H; B then uploads its already-prepared G records into the reused zones. The preflight check passed. Keep durable retirement metadata, bind records and queues to generations, and specify a write-fencing or generation-isolation protocol that handles this interleaving. Its CloudKit atomicity assumptions need verification.

**B. New issues introduced by revision 2**

**Critical:** No separate new critical finding; the critical blockers above are continuations of round 1.

**Important**

1. **Duplicate detection ignores a field that controls replay.**  
   **File/section:** 17 B.2 and B.7; 16 B.3/B.8.  
   **Problem:** The canonical hash excludes `recordedAt`, but correction precedence and duplicate-grant selection use it. Two copies of the same correction can therefore compare equal while selecting different winners on different devices.  
   **Why it matters:** Sync can report agreement while devices calculate different histories.  
   **Concrete fix:** Include every replay-relevant immutable field in the hash. Store local receipt times separately. Test identical IDs with differing `recordedAt` values.

2. **Import changes the immutable object it is supposed to merge.**  
   **File/section:** 17 B.2, B.5 and B.9.  
   **Problem:** Import sets `Evidence.imported = true` inside the hashed entry payload. A restored entry then differs from its original CloudKit copy under the same ID.  
   **Why it matters:** An ordinary export/import/sync round trip can quarantine valid history. Comparing before changing the flag merely postpones the conflict.  
   **Concrete fix:** Keep import trust/provenance in separate metadata or an explicit assessment record. Preserve original entry bytes and IDs, and define how independently trusted evidence combines with imported evidence.

3. **The new export layout can omit health history or bypass its opt-in.**  
   **File/section:** 17 B.1 and B.9; 16 B.5.  
   **Problem:** `entries.jsonl` contains only P entries, while `health-local.jsonl` is sourced only from the phone-only store. In `.allowed` mode, H2 entries live in `record.sqlite` and have no specified export destination. Conversely, `memory.jsonl` and `plan-revisions.jsonl` have no explicit H2 filter.  
   **Why it matters:** A backup may silently omit health-related history, or include sensitive working data without the promised opt-in.  
   **Concrete fix:** Define an export matrix by data class and mode, independent of physical storage. Specify H2 inclusion, omitted references and tombstones explicitly. Require round-trip tests for both modes and both opt-in choices.

4. **The proposed privacy label confuses pseudonymity with lack of linkage.**  
   **File/section:** 20 B.2 and B.4.  
   **Problem:** Persistent device registrations are classified “Anonymous,” and the checklist expects “Device ID, Not Linked to You,” despite retaining linkage between a device and its Ritual participation.  
   **Why it matters:** Knowing no name does not establish Apple’s “not linked” classification: Apple explicitly includes identity through a device. The declaration could misrepresent the implemented collection. [Apple’s privacy-label guidance](https://developer.apple.com/app-store/app-privacy-details/).  
   **Concrete fix:** Classify registration and participation linkage as pseudonymous; reserve anonymous for aggregates. Determine the label from the actual retained relationships, including participation data. **Final classification needs confirmation; “Not Linked” is not established by this design.** This implements decision 48’s honesty requirement.

5. **The testing restriction excludes the environment used by TestFlight.**  
   **File/section:** 22 B.2, items 5 and 7.  
   **Problem:** Platform checks require CloudKit development and “Never production,” while acceptance uses TestFlight. Apple documents that TestFlight cannot use CloudKit’s development environment. [Apple’s CloudKit testing guidance](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/TestingYourApp/TestingYourApp.html).  
   **Why it matters:** Development-only checks cannot validate the distribution path, deployed schema or production entitlements.  
   **Concrete fix:** Distinguish production *environment* from real-user *data*. Use an isolated test app/container with its production schema for TestFlight integration tests, alongside development tests and Relay staging. Apple also specifies production App Attest behavior for TestFlight. [App Attest environments](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.devicecheck.appattest-environment).

**Minor**

6. **The network allowlist has no explicit content-catalog route.**  
   **File/section:** 20 B.3 rule 2; 16 B.10.  
   **Problem:** The allowlist permits Apple services and the Relay domain; the catalog is served from an unspecified CDN.  
   **Why it matters:** A separately hosted catalog will be blocked, or an implementing agent must invent an exception.  
   **Concrete fix:** Specify either a catalog route on the Relay domain or an explicit approved catalog origin, retaining signature verification and redirect restrictions.

**C. Final verdict**

**No — Part B is not yet acceptable as the approved foundation for MVP implementation plans.**

Before approval, close the three critical protocols above and correct the new replay/import/export defects. Resolve the remaining occurrence, correction and DST rules with concrete examples. Move the **MVP** Transformation/Depth requirements into chapters on the approved MVP planning track, rather than leaving essential behavior dependent on deferred chapter 10.

The module structure, pure engine, MVP AI boundary and expanded review gates are usable foundations. The remaining blockers concern whether progress survives, private data stays within its boundary, and deletion actually holds under concurrency.