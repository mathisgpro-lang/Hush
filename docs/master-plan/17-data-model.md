# 17 — Data Model

**Status:** First pass (Phase B core backbone): Part A ✅ approved 2026-09-30 (small revisions after Codex review) · Part B 🔎 revision 2, in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 30–33, 35–37, 43–44, 48–50 · **Depends on:** [16-system-architecture.md](16-system-architecture.md)

The two layers work as in chapter 16: Part A is for Mathis, and Part B is for the builders.

---

# Part A — For Mathis

## A.1 Three kinds of data

| Kind | What it is | Can it change? | Where it lives |
|---|---|---|---|
| **The record** | Everything you've done: every Action, every Path started, every Spark, every reward received. | **Never.** Entries are only ever added. Mistakes get a correction entry, like an accountant's ledger. | Phone + your private iCloud (health-related facts: see chapter 16 §A.2) |
| **Calculated state** | Your Depth per pillar, Vitality, growth number, the Flame's shape, the current theme. | Recalculated at any time from the record. | Phone (a fast cache that can always be rebuilt) |
| **Working data** | Your current plans (every past version kept), the Companion's memory of you, settings. | Yes, it's living data. You can view and delete any Companion memory. | Phone + your private iCloud (health-related parts: see chapter 16 §A.2) |

## A.2 An example day, as the record sees it

> 06:40 — *Action completed:* Morning run (Path: Sub-4 marathon · Body) — verified by Apple Health
> 08:15 — *Spark dealt:* "Tell someone why you admire them"
> 12:30 — *Spark swapped* (1 swap used today)
> 12:30 — *Spark dealt:* "Eat lunch with no phone"
> 13:05 — *Action completed:* Lunch with no phone (Spark · Spirit) — self-reported
> 21:10 — *Ritual joined:* Week 40 — Call someone you love (Heart) — self-reported
> 21:10 — *Reward granted:* Title "Week 40 — The Callers"

From those lines alone, the brain calculates today's growth, Vitality and the Flame. Notice: **no distance, no heart rate.** Apple Health keeps those.

## A.3 Promises the data model keeps

1. **Nothing you did is ever lost or rewritten** (P6, P11).
2. **What you've been granted is never taken back**, even if we change the formulas later, and even if two of your devices were offline at the same time.
3. **Formulas can improve**, and your Flame is recalculated fairly from your true history.
4. **You can export everything**, anytime, in an open, documented format.
5. **You can delete everything**, anytime: from the phone and from your iCloud. An old phone that comes back online later **can never bring deleted data back**.
6. **It fits decades.** An intense user logging 20 entries a day for 50 years produces about 365,000 entries, a few hundred megabytes at most.
7. **Your Flame dims when you're away even if you log nothing.** The brain knows what time it is, not just what you've logged.

## A.4 When does a day end? *[Decided, 44]*

A day runs from **04:00 to 04:00** in your local time. The user can adjust this in settings, for example for night-shift workers. A workout at 00:30 after a late night counts for the day you were *living*.

---

# Part B — For the builders

## B.1 Storage
- **Local:** SQLite via GRDB, chosen for explicit control over the append-only schema, migrations, export and triggers. Two database files per account namespace (chapter 16 §B.8):
  - `record.sqlite`: P-class data (entries, working data, outbox, sync metadata, projections, queues). Standard backup behavior.
  - `health-local.sqlite`: H2-class data in `.phoneOnly` mode (chapter 16 §B.5). `isExcludedFromBackup = true`, never synced. In `.allowed` mode it's unused and H2 data goes to `record.sqlite`.
- **Sync:** CKSyncEngine, private database, zones `Record`, `Working`, `Meta` (16 §B.8).
- **Encryption:** payload fields use CKRecord `encryptedValues`.

## B.2 Record entry (append-only)

```
Entry {
  id:              UUIDv7            // unique; idempotency key for storage and sync
  kind:            EntryKind         // see B.3
  schemaVersion:   Int               // payload schema version for this kind
  occurredAt:      Instant (UTC)     // when it happened (user may backdate)
  recordedAt:      Instant (UTC)     // when it was written
  timeZone:        IANA TZ id        // zone at occurredAt (device zone, or the zone chosen when backdating)
  livedDay:        LocalDate         // computed per B.6 at write time; never recomputed
  dayBoundary:     LocalTime         // boundary applied (e.g. 04:00)
  dayRuleVersion:  Int               // LivedDay algorithm version applied
  deviceId:        UUID              // per-install random id; stays in the user's own storage
  healthClass:     P | H2            // decides the store and the sync destination (16 §B.5)
  payload:         JSON (kind-specific, versioned)
}
```

**Invariants:**
- No UPDATE or DELETE on `entries`, except via the deletion protocol (16 §B.9). Enforced by SQLite triggers, with tests.
- No H1 data in any payload (a schema test for known fields). Free-text fields are always H2 (16 §B.5).
- Canonical content hash = SHA-256 of the canonical JSON of all fields except `recordedAt`. Used for duplicate-ID comparison (16 §B.8).

## B.3 Entry kinds (first pass; chapters 04, 05, 07, 10 will extend)

| Kind | Payload (summary) |
|---|---|
| `actionCompleted` | `occurrenceKey` (B.4), `actionRef {catalogId or planRevisionId, itemId, version}`, source (`path` / `spark` / `ritual` / `free`), pillarWeights {pillar: 0–1}, difficulty (calibrated), evidence (B.5), noteRef? (the note lives in H2 storage) |
| `correction` | `targetId`, `action` (`void` \| `amend`), `reason` (`loggedByMistake`, `wrongDay`, `wrongAction`, …), amended fields? (for `amend`) |
| `pathStarted` / `pathRevised` / `pathEnded` | pathId, goal, `planRevisionId` (immutable, B.8), reason |
| `sparkDealt` | sparkId, `catalogRef {catalogId, version}`, pillar, difficulty, prompt text |
| `sparkSwapped` | `swappedSparkDealtId` |
| `ritualJoined` | `ritualWindowId`, evidence |
| `evidenceAssessed` | `targetEntryId`, `{criterionId, criterionVersion, outcome: met \| notMet \| unknown, assessedAt, provenance}`. Always H2. Can be re-emitted on a new device in `.phoneOnly` mode |
| `rewardGranted` | `entitlementKey`, rewardId, tier (`transformation` / `collectible`), window?, rulesVersion |
| `milestoneWitnessed` | `entitlementKey`: presentation acknowledgement only |
| `depthAcknowledged` | {pillar: value}, rulesVersion: the floor input (16 §B.3); the policy comes from chapter 04 |

## B.4 Occurrences and de-duplication

- **`occurrenceKey`** identifies *the thing that was done*, independent of entry IDs:
  - Path item: `path:{pathId}:{planRevisionId}:{itemId}:{livedDay}`
  - Spark: `spark:{sparkDealtEntryId}`
  - Ritual: `ritual:{ritualWindowId}`
  - Free Action: `free:{entryId}` (always unique)
- **Projection rule:** for each `occurrenceKey`, the first non-voided completion by `(occurredAt, id)` counts. Later duplicates are ignored for growth but remain in the record.
- **Evidence:** a HealthKit `sampleUUID` supports at most one occurrence. If two occurrences claim the same sample, the earliest by `(occurredAt, id)` keeps the verified evidence; the other falls back to `selfReported`.
- **Spark swap limit (one per lived day):** enforced locally at the moment of swapping. **Accepted limitation:** two devices offline at the same time could each swap once. After sync, both swaps stand (no retroactive punishment, P6), and the next day is normal.

## B.5 Evidence

```
Evidence {
  level:       selfReported | deviceVerified | partnerVerified
  provenance:  "user" | "healthkit:external" | "healthkit:selfWritten" | <partner id>
  ref:         { sampleType, sampleUUID } | { operationId }?   // references only, never values
  imported:    Bool           // true if it arrived via import (B.9); imported evidence never confers public status
}
```
The level is derived from provenance and assessment, never from storage location (16 §B.6).

## B.6 Lived day (algorithm v1)

```
local      = occurredAt converted to timeZone (civil date + wall-clock time)
if local.wallClockTime < dayBoundary:  livedDay = local.date − 1 calendar day
else:                                   livedDay = local.date
```
- This compares **wall-clock time**, never subtracting durations, so daylight-saving transitions can't shift days. A boundary that falls in a skipped hour works the same way, and a repeated hour is resolved by the wall-clock comparison.
- **Examples (golden vectors):**
  - 00:30 on 29 March in Europe/Paris (the DST-start night) → 28 March.
  - 03:59 → the previous day.
  - 04:00 → the same day.
  - A flight Paris → New York, logging at 02:00 New York time → the previous New York date.
- **Travel:** the zone at the moment of occurrence applies.
- **Backdating:** the user picks the date and time; the zone defaults to the current zone and can be edited.
- `dayBoundary` and `dayRuleVersion` are stored per entry, so history never shifts when settings change.

## B.7 Corrections

- A `correction` targets exactly one entry (`targetId`). `void` removes the target from growth. `amend` replaces the listed fields for growth purposes.
- **Several corrections to the same target:** the latest by `(recordedAt, id)` wins. A `correction` can target another `correction` (that's how "undo" works).
- **A correction that arrives before its target** (sync order): it's held and applied when the target arrives. The projection ignores corrections with missing targets.
- Corrections can lower growth that came from *mistakes* (honest numbers, guardrail 6). How this interacts with the Depth floor is chapter 04's decision.

## B.8 Working data

- **`PlanRevision`**: immutable. It holds the full structured plan (`@Generable`-compatible), `sources[]` (registry IDs), `createdAt`, `parentRevisionId`. Health class: H2 if Body-pillar, otherwise P.
- **`ActivePlan`**: a pointer `{pathId → planRevisionId}`, last-writer-wins (16 §B.8). A revision and its `pathRevised` entry are committed in one transaction.
- **`CompanionMemory`**: `{id, text, createdAt, origin, healthClass}`. Create-only plus tombstones. The user can view and delete them. The text is free text, so it's always H2.
- **`Setting`**: key/value, last-writer-wins. Includes `dayBoundary` and `healthFactSyncMode` (read-only, from the build config).

## B.9 Export and import

**Export:** a `.zip` containing:
- `manifest.json`: format version, counts, rulesVersion, datasetGeneration, `healthFactSyncMode`;
- `entries.jsonl` (P-class);
- `plan-revisions.jsonl`, `memory.jsonl`, `settings.json`;
- `README.md` describing the format;
- optionally, if the user opts in: `health-local.jsonl` (H2 from the phone-only store).

HealthKit data isn't included; the user exports it from Apple Health.

**Import** (untrusted input):
1. Size limits: archive ≤ 500 MB, ≤ 2M lines, per-line ≤ 64 KB. Zip bomb and path-traversal checks.
2. Supported format versions only; otherwise refuse, with a clear message.
3. Import into a **temporary database**, validate every entry (schema, references, invariants), and only then merge atomically.
4. **Merge semantics** (never replace): union by entry ID. Same ID + same hash → skip. Same ID + different hash → quarantine.
5. Imported evidence is marked `imported = true`. It still counts for the private Flame, but **never** confers public or verified status.
6. Tombstones in the import are honored. Import is refused if the manifest's `datasetGeneration` belongs to a generation that was deleted on this account, unless the user explicitly confirms a restore.

## B.10 Size budget
- Roughly 200 bytes to 1 KB per entry. 365k entries ≈ 70–365 MB worst case over 50 years, within limits for SQLite and CloudKit. Projections keep UI reads fast.

## B.11 Open (owner → chapter)
- The pillar-weight, difficulty and Depth models, and the Depth-floor versus corrections policy → **04**.
- Reward and milestone catalogs, and the Transformation → theme mapping → **10**.
- Verification beyond HealthKit → **09**.
