# 17 — Data Model

**Status:** First pass (Phase B core backbone): Part A ✅ approved 2026-09-30 (small revisions after Codex review) · Part B 🔎 revision 3, in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 30–33, 35–37, 43–44, 48–50 · **Depends on:** [16-system-architecture.md](16-system-architecture.md)

The two layers work as in chapter 16: Part A is for Mathis, and Part B is for the builders.

---

# Part A — For Mathis

## A.1 Three kinds of data

| Kind | What it is | Can it change? | Where it lives |
|---|---|---|---|
| **The record** | Everything you've done: every Action, every Path started, every Spark, every reward received. | **Never.** Entries are only ever added. Mistakes get a correction entry, like an accountant's ledger. | Phone + your private iCloud. **Always synced, never lost** (decision 57) |
| **Calculated state** | Your Depth per pillar, Vitality, growth number, the Flame's shape, the current theme. | Recalculated at any time from the record. | Phone (a fast cache that can always be rebuilt) |
| **Working data** | Your current plans (every past version kept), the Companion's memory of you, settings. | Yes, it's living data. You can view and delete any Companion memory. | Phone + your private iCloud (private notes, Companion memory text and Body health plans may be phone-only; see chapter 16 §A.2) |

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
  - `health-local.sqlite`: H2-class data in `.phoneOnly` mode (chapter 16 §B.5), in a backup-excluded directory, never synced. In `.allowed` mode it's unused and H2 data goes to `record.sqlite`.
  - **Class is a property of the data, not of the file:** every row carries `healthClass`, so export, import and deletion operate by class and mode (B.9), independent of which physical store holds it.
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
  healthClass:     P | H2            // actionCompleted is always P (decision 57); evidenceAssessed is always H2
  payload:         JSON (kind-specific, versioned)
}
```

**Invariants:**
- No UPDATE or DELETE on `entries`, except via the deletion protocol (16 §B.9). Enforced by SQLite triggers, with tests.
- No H1 data in any payload (a schema test for known fields). Free-text fields are always H2 (16 §B.5).
- **Canonical content hash** = SHA-256 of the canonical JSON of **all immutable fields, including `recordedAt`** (it drives correction and duplicate-grant precedence). Local metadata such as receipt time, sync state and import provenance lives in **separate tables**, never in the entry. Used for duplicate-ID comparison (16 §B.8).

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

- **`occurrenceKey`** identifies *the thing that was done*, independent of entry IDs and **stable across plan revisions**:
  - Path item: `path:{pathId}:{livedDay}:{slotId}`, where `slotId` is the schedule slot (e.g. `am-run`), which survives plan revisions. The plan revision is recorded in `actionRef`, not in the key.
  - Spark: `spark:{sparkDealtEntryId}`
  - Ritual: `ritual:{ritualWindowId}`
  - Created from a HealthKit sample (auto-detected): `hk:{sampleUUID}`
  - Free Action: `free:{entryId}` (always unique)
- **Projection rule:** for each `occurrenceKey`, the first non-voided completion by `(occurredAt, id)` counts. Later duplicates are ignored for growth but remain in the record.
- **Evidence:** a HealthKit `sampleUUID` supports at most one occurrence. If two manually logged occurrences cite the same sample, the earliest by `(occurredAt, id)` keeps the verified evidence and the other stays `selfReported`. Manual logging is the user's own responsibility (P2); auto-detected completions can't double count because they're keyed by sample.
- **Spark swap limit (one per lived day):** enforced locally at the moment of swapping. **Accepted limitation:** two devices offline at the same time could each swap once. After sync, both swaps stand (no retroactive punishment, P6), and the next day is normal.

## B.5 Evidence

```
Evidence {
  level:       selfReported | deviceVerified | partnerVerified
  provenance:  "user" | "healthkit:trusted" | "healthkit:otherSource" | "healthkit:selfWritten" | "reassessed" | <partner id>
  ref:         { sampleType, sampleUUID } | { operationId }?   // references only, never values
}
```
Import provenance is **not** stored in the entry (it would change the hash). It lives in a local `import_provenance(entryId, importedAt, manifestId)` table. Anything with an import-provenance row never confers public or verified-for-others status, though it counts in the private Flame.

The level is derived from provenance and assessment, never from storage location (16 §B.6).

## B.6 Lived day (algorithm v2: boundary instants)

For a local calendar date X in zone Z and boundary time b (e.g. 04:00):
```
B(X) = the earliest instant whose wall-clock time in Z, on date X, is ≥ b
livedDay(t) = the latest date X such that B(X) ≤ t
```
- **Skipped hour** (spring forward): if b falls in the gap, B(X) is the first instant after the gap, and nothing is ambiguous.
- **Repeated hour** (fall back): B(X) is the *first* occurrence, so livedDay only ever moves forward as time passes, never backward. This fixes the 02:30-boundary reversal Codex found.
- The boundary setting is limited to whole or half hours. Any value is safe under this algorithm.
- **Golden vectors:** 00:30 on 29 Mar 2026, Europe/Paris → 28 Mar; 03:59 → previous day; 04:00 → same day; boundary 02:30 on the DST-start night (Paris, the gap is 02:00–03:00) → B = 03:00; boundary 02:30 on the fall-back night (the repeated 02:00–03:00) → the first 02:30, then every later instant that night maps to the new day; travel Paris → New York logging at 02:00 local → the previous New York date.
- **Travel:** Z = the zone at the moment of occurrence. **Backdating:** the user picks the date and time; Z defaults to the current zone and can be edited.
- `dayBoundary` and `dayRuleVersion` are stored per entry, so history never shifts when settings change.

## B.7 Corrections

- A `correction` targets exactly one entry (`targetId`). `void` removes the target from growth. `amend` replaces the listed fields for growth purposes.
- **Creation rule:** a correction may target only an entry that exists locally when it's created, so its `recordedAt` is later than its target's. **Cycles are therefore impossible.**
- **Several corrections to the same target:** the latest by `(recordedAt, id)` wins. `recordedAt` is part of the hash (B.2), so every device picks the same winner.
- **Undo** = a `void` correction targeting a correction. The corrected target is evaluated using the winning correction at the end of the chain.
- **A correction that arrives before its target** (sync order): it's held and applied when the target arrives. The projection ignores corrections with missing targets.
- Corrections lower growth that came from *mistakes* (honest numbers). Legacy offsets from formula changes don't absorb corrections (chapter 04 §B.2).

## B.8 Working data

- **`PlanRevision`**: immutable. It holds the full structured plan (`@Generable`-compatible), `sources[]` (registry IDs), `createdAt`, `parentRevisionId`, and `slots[]` (stable slot IDs, B.4). Health class: **H2 for Body health tracks** (training, nutrition, sleep), otherwise P (chapter 16 §B.5).
- **`ActivePlan`**: a pointer `{pathId → planRevisionId}`, last-writer-wins (16 §B.8). A revision and its `pathRevised` entry are committed in one transaction.
- **`CompanionMemory`**: `{id, text, createdAt, origin, healthClass}`. Create-only plus tombstones. The user can view and delete them. The text is free text, so it's always H2.
- **`Setting`**: key/value, last-writer-wins. Includes `dayBoundary` and `healthFactSyncMode` (read-only, from the build config).

## B.9 Export and import

**Export matrix** (by class and mode, independent of physical storage):

| File | Contents | Included |
|---|---|---|
| `manifest.json` | format version, counts per file, rulesVersion, `datasetGeneration`, `retiredGenerations`, `healthFactSyncMode`, whether H2 was included | Always |
| `entries.jsonl` | all P entries (including every `actionCompleted`) | Always |
| `plan-revisions.jsonl` | P plan revisions | Always |
| `settings.json`, `tombstones.jsonl` | settings; memory tombstones | Always |
| `health.jsonl` | all H2 data in either mode: `evidenceAssessed`, H2 plan revisions, notes, memory text, HealthKit-derived levels | **Only if the user opts in** at export time (default: ask; the "include private notes and health details" toggle is off) |
| `README.md` | the format description | Always |

- References from P to H2 that aren't exported are kept as IDs and render as "not included" on import.
- HealthKit data itself is never exported; the user exports it from Apple Health.
- **Round-trip tests:** both modes × both opt-in choices.

**Import** (untrusted input):
1. Size limits: archive ≤ 500 MB, ≤ 2M lines, per-line ≤ 64 KB. Zip bomb and path-traversal checks.
2. Supported format versions only; otherwise refuse, with a clear message.
3. **Stage** into temporary databases (one per class destination) and validate every row (schema, references, invariants, hashes). Nothing touches the live stores until validation passes.
4. **Merge semantics** (never replace): union by ID. Same ID + same hash → skip. Same ID + different hash → quarantine. Entries are inserted **byte-identical** to the export (the hash is preserved); provenance goes to `import_provenance` (B.5).
5. **Atomic commit across two stores:** write an `ImportJournal {importId, stage, files}` first, commit the P store, then the H2 store, then mark the journal done. On relaunch, an unfinished journal is resumed idempotently (the ID union makes re-applying safe).
6. **Generations:** if the manifest's `datasetGeneration` is in this account's `retiredGenerations`, import requires explicit user confirmation ("restore data you previously deleted?"). Imported rows are re-tagged to the current generation for upload. Tombstones in the import are honored.

## B.10 Size budget
- Roughly 200 bytes to 1 KB per entry. 365k entries ≈ 70–365 MB worst case over 50 years, within limits for SQLite and CloudKit. Projections keep UI reads fast.

## B.11 Open (owner → chapter)
- The pillar-weight, difficulty and Depth models, and the Depth-floor versus corrections policy → **04**.
- The MVP Transformation → theme mapping and MVP milestones → **03** (MVP track); the full reward catalogs → **10**.
- Verification beyond HealthKit → **09**.
