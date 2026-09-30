# 17 — Data Model

**Status:** First pass (Phase B core backbone): Part A ✅ approved 2026-09-30 · Part B 🔎 in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 30–33, 35–37 · **Depends on:** [16-system-architecture.md](16-system-architecture.md)

The two layers work as in chapter 16: Part A is for Mathis, and Part B is for the builders.

---

# Part A — For Mathis

## A.1 Three kinds of data

| Kind | What it is | Can it change? | Where it lives |
|---|---|---|---|
| **The record** | Everything you've done: every Action, every Path started, every Spark, every reward received. | **Never.** Entries are only ever added. Mistakes get a correction entry, like an accountant's ledger. | Phone + your private iCloud |
| **Calculated state** | Your Depth per pillar, Vitality, growth number, the Flame's shape, the current theme. | Recalculated at any time from the record. | Phone (a fast cache that can always be rebuilt) |
| **Working data** | Your current plans, the Companion's memory of you, settings. | Yes, it's living data. You can view and delete any Companion memory. | Phone + your private iCloud (health-derived memory stays on the phone only) |

## A.2 An example day, as the record sees it

> 06:40 — *Action completed:* Morning run (Path: Sub-4 marathon · Body) — verified by Apple Health, workout #ABC
> 08:15 — *Spark dealt:* "Tell someone why you admire them"
> 12:30 — *Spark swapped* (1 swap used today)
> 12:30 — *Spark dealt:* "Eat lunch with no phone"
> 13:05 — *Action completed:* Lunch with no phone (Spark · Spirit) — self-reported
> 21:10 — *Ritual joined:* Week 40 — Call someone you love (Heart) — self-reported
> 21:10 — *Reward granted:* Title "Week 40 — The Callers"

From those lines alone, the brain calculates today's growth, Vitality and the Flame. Notice: **no distance, no heart rate.** Apple Health keeps those (chapter 16, §A.2).

## A.3 Promises the data model keeps

1. **Nothing you did is ever lost or rewritten** (P6, P11).
2. **What you've been granted is never taken back**, even if we change the formulas later.
3. **Formulas can improve**, and your Flame is recalculated fairly from your true history.
4. **You can export everything**, anytime, in an open, documented format.
5. **You can delete everything**, anytime: from the phone and from your iCloud.
6. **It fits decades.** An intense user logging 20 entries a day for 50 years produces about 365,000 entries, a few hundred megabytes at most.

## A.4 One proposal for you: when does a day end?

If you finish a workout at 00:30 after a late night, it should count for the day you were *living*, not the new calendar day.

**Decided (44):** a day runs from **04:00 to 04:00** in your local time. The user can adjust this in settings (for night-shift workers, for example).

---

# Part B — For the builders

## B.1 Storage
- **Local:** SQLite via GRDB (not SwiftData). This gives explicit control over an append-only schema, migrations and export, and avoids SwiftData+CloudKit's all-optional constraints.
- **Sync:** CKSyncEngine, private database, custom zone `Record`. One `CKRecord` per record entry (type `Entry`), plus separate types for working data (`Plan`, `CompanionMemory`, `Setting`).
- **Encryption:** payload fields use CKRecord `encryptedValues`, so they're end-to-end encrypted for users with Advanced Data Protection and encrypted at rest otherwise.

## B.2 Record entry (append-only)

```
Entry {
  id:              UUIDv7            // time-ordered; globally unique; the idempotency key
  kind:            EntryKind         // see B.3
  schemaVersion:   Int               // payload schema version for this kind
  occurredAt:      Instant (UTC)     // when it happened
  recordedAt:      Instant (UTC)     // when it was written
  timeZone:        IANA TZ id        // user's zone at occurredAt
  livedDay:        LocalDate         // the day it counts for (after the day-start rule, B.6)
  deviceId:        UUID              // per-install random id; never leaves the user's iCloud
  payload:         JSON (kind-specific, versioned)
  supersedes:      UUID?             // only for kind = correction
}
```

**Invariants:**
- No UPDATE or DELETE on the `entries` table, except "delete everything" (B.8). This is enforced by database triggers and tests.
- Payloads **must not** contain health measurements (chapter 16, §B.5).

## B.3 Entry kinds (first pass; chapters 04, 05, 07, 10 will extend)

| Kind | Payload (summary) |
|---|---|
| `actionCompleted` | actionId, source (`path` / `spark` / `ritual` / `free`), pathId?, pillarWeights {pillar: 0–1}, difficulty (calibrated), evidence (B.4), note? |
| `correction` | target entry id, reason (`loggedByMistake`, `wrongDay`, …), replacement fields? |
| `pathStarted` / `pathRevised` / `pathEnded` | pathId, goal, planRef, reason |
| `sparkDealt` / `sparkSwapped` | sparkId, pillar, difficulty, prompt text |
| `ritualJoined` | ritualId, window (e.g. `2026-W40`), evidence |
| `rewardGranted` | rewardId, tier (`transformation` / `collectible`), window?, rulesVersion |
| `milestoneWitnessed` | milestoneId, rulesVersion. Written when the user sees the Transformation moment |

## B.4 Evidence

```
Evidence {
  level:   selfReported | deviceVerified | partnerVerified
  source:  "user" | "healthkit" | <partner id>
  ref:     { sampleType, sampleUUID }?     // references, never values
  verifiedAt: Instant?
}
```

## B.5 Calculated state (projections)
- Tables: `pillar_depth`, `vitality`, `growth_number`, `flame_params`, `theme_state`. Each row carries `rulesVersion` and `computedThroughEntryId`.
- They're rebuilt incrementally on each new entry, and fully rebuilt when `rulesVersion` changes.
- They're **never synced.** Every device recomputes them from the synced record, so there's a single source of truth.
- **Grants are not recomputed away:** `rewardGranted` entries are facts. Projections may *add* newly eligible rewards (then emit a `rewardGranted` entry), but never remove any.

## B.6 Lived day
- `livedDay` = the local date of (`occurredAt` in `timeZone`) − `dayStartOffset`. Default offset: 4h (approved, decision 44). The offset is user-configurable, stored as a `Setting`, and the value in effect is written into each entry via `livedDay`, so history never shifts retroactively.

## B.7 Working data (mutable, synced)
- `Plan`: the current plan document for a Path (structured, `@Generable`-compatible), with `sources[]` and a `version`. Every revision also emits a `pathRevised` entry, so history is preserved.
- `CompanionMemory`: small, user-viewable memory notes (`text`, `createdAt`, `origin`). The user can delete them individually. **Health-derived memories live in a separate, local-only table and are not synced.**
- `Setting`: key/value.

## B.8 Export and delete
- **Export:** a `.zip` containing `manifest.json` (format version, counts, rulesVersion), `entries.jsonl` (one entry per line, B.2 schema), `plans.json`, `memory.json`, `settings.json`, and a `README.md` describing the format. The export does not include HealthKit data; the user exports that from Apple Health.
- **Delete everything:** wipes the local database, deletes the CloudKit zone, clears the Keychain items, and resets to first launch. Two-step confirmation.
- **Import:** restores from an export file (for users without iCloud; decision 32).

## B.9 Size budget
- ~200 bytes to ~1 KB per entry. 365k entries ≈ 70–365 MB worst case over 50 years. This is within limits for SQLite and CloudKit. Projections make reads O(1) for the UI.

## B.10 Open (owner → chapter)
- The exact pillar-weight and difficulty model → **04**.
- Reward and milestone catalogs → **10**.
- Verification methods beyond HealthKit → **09**.
- ~~Day-start default~~ → 04:00, decision 44.
