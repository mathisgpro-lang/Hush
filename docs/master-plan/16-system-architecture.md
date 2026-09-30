# 16 — System Architecture

**Status:** First pass (Phase B foundations): Part A ✅ approved 2026-09-30 (revised after Codex review, decisions 48–50) · Part B revision 5 (Codex round-4 blocking items fixed), 🔎 targeted Codex check · **Last updated:** 2026-09-30
**Based on:** decisions 20, 23, 28–50 · **Reviews:** [Codex round 1](../reviews/2026-09-30-codex-phaseB.md) · **Research:** §B.12

This chapter has two layers:
- **Part A, for Mathis:** plain language. Mathis reads and approves this part.
- **Part B, for the builders:** the technical specification. Codex reviews this part independently.

If the two layers ever disagree, Part A's intent wins and Part B gets corrected.

---

# Part A — For Mathis

## A.1 The big picture: four places

The whole system lives in four places, and only one of them belongs to the company.

```
┌──────────────────────────── The user's iPhone ────────────────────────────┐
│   THE APP  (the body: screens, the Flame, haptics, sound)                 │
│   THE BRAIN (growth rules: how the record becomes Depth, Vitality,        │
│              the Flame; identical on every future platform)               │
│   THE RECORD (the permanent history, stored on the phone)                 │
│   APPLE HEALTH (health data stays here; the app only reads it)            │
│   ON-DEVICE AI (Apple's model: private, free, offline)                    │
└──────┬───────────────────────┬─────────────────────────┬──────────────────┘
       │ syncs                 │ heavier AI              │ anonymous only
       ▼                       ▼                         ▼
┌───────────────┐   ┌─────────────────────────┐   ┌─────────────────────────┐
│ THE USER'S    │   │ APPLE PRIVATE CLOUD     │   │ THE RELAY               │
│ PRIVATE iCLOUD│   │ COMPUTE                 │   │ (the only company piece)│
│ Their copy.   │   │ Apple's bigger model:   │   │ MVP: counts Ritual      │
│ We can't see  │   │ free, stores nothing.   │   │ participants. Knows a   │
│ it.           │   │ (Frontier AI like Claude│   │ random device key, never│
│               │   │  comes after the MVP.)  │   │ who you are.            │
└───────────────┘   └─────────────────────────┘   └─────────────────────────┘
```

- **Your phone does almost everything.** The tracking moment, the Flame and your record all work with no internet at all.
- **Your private iCloud is the backup and sync.** It's yours, and the company can't read it.
- **Apple's AI does all of the Companion's thinking in the MVP,** on the phone or in Apple's private cloud. It's free and stores nothing, so the company never sees your words (decision 49).
- **The Relay** is the only piece the company runs, and in the MVP it has one job: counting Ritual participants. To make sure only the real app can use it, it recognizes a **random anonymous key for each device**. It can tell "the same device joined three Rituals," but it can never tell *who* you are. We say this plainly in the privacy promise (decision 48).

## A.2 What the research changed (2026-09-30)

**1. The AI layer got better and cheaper.** Since iOS 27 (released 14 September 2026), Apple offers three levels of AI through a single system:
- the **on-device model**;
- **Apple's Private Cloud Compute model**: much bigger, **free for small developers** (under 2 million first-time downloads), no account or key, and **no prompts stored**, which independent researchers can verify;
- **frontier models like Claude or Gemini** in the *same* system.

The MVP uses the first two only (decision 49).

**The catch:** Apple's free cloud model has a daily limit per user, and it **ends once an app passes 2 million downloads**, with a 6-month window to migrate. There's no paid option. So it's a launch engine, not the long-term foundation. Adding a frontier AI later is designed in from the start.

**2. Ritual counters live on the Relay.** Apple's shared iCloud database isn't built for millions of people adding to one shared counter at the same moment. The counters stay anonymous.

**3. Designed for both of Apple's possible answers on health data** (decision 50). Apple's rules say apps *"may not store personal health information in iCloud,"* and it's unclear how strictly that applies to our case. So the app is designed to work either way:
- **Health measurements** (distance, heart rate, sleep hours) **always stay in Apple Health.** Our app never stores them.
- **The fact that you did something** (like "went for a run") is always part of your synced record, **never lost** (decision 57).
- **Things read from Apple Health, your private notes, and Body health plans:**
  - **If Apple says OK:** they sync like everything else.
  - **If Apple says no:** they stay in a separate, phone-only store that's never uploaded, even to backups. On a new phone, verification is rebuilt from Apple Health where possible, and the Companion can rebuild plans. **Losing a phone never lowers your Depth, growth number or rewards.** At worst you lose some "verified" badges and your private notes.

We ask Apple in writing before building the health features. I'll draft the question, and you'll send it from your developer account.

## A.3 What happens when things go wrong

| Situation | What the user experiences |
|---|---|
| No internet | Everything works. The tracking moment is instant. Sync catches up later. Heavy Companion requests wait politely, with the user's draft kept. |
| iCloud off or full | The app works, and says kindly and clearly that the Flame lives only on this phone, with a one-tap backup (decision 32). |
| Apple's AI unavailable (old phone, daily limit, outage) | The Companion falls back to simpler built-in content (hand-written Sparks and encouragement). It never silently breaks, and your day is always ready. |
| The Relay is down | Rituals show the last known count; your participation is saved and sent later. Nothing else is affected. |
| New phone | Sign into iCloud and your record, Flame and Paths come back. Health-related details come back through Apple Health. |
| Switching iCloud accounts on the same phone | The app never mixes two people's data. It asks what to do. |

## A.4 What's still open

- **Minimum iPhone:** the MVP needs iOS 27 (current). Which older iPhones V1 supports gets decided in chapter 24.
- **Where the Relay runs:** proposed Cloudflare (a large, reliable, low-cost provider that runs small programs without anyone managing servers). Confirmed when the Relay is built.
- **Which frontier AI, after the MVP:** chosen by testing quality and cost (decision 34).
- **Delivering new game content without app updates** (decision 40). Real game depth needs a steady flow of new Sparks, Rituals, milestones, story and world content. The proposed way is a public, read-only content catalog. It holds no user data, and it's designed with chapter 28.

---

# Part B — For the builders

## B.1 Platform baseline
- **Minimum OS (MVP):** iOS 27.0. Revisit for V1 (chapter 24).
- **Language/UI:** Swift 6 with strict concurrency checking on; SwiftUI for all UI; Metal for the Flame renderer; Core Haptics; AVFoundation / AVAudioEngine for sound.
- **Tooling:** Xcode 27. Swift Package Manager only.
- **Devices:** iPhone only for the MVP. Module boundaries must not block later Watch or widget targets.
- **Capabilities are checked at runtime, never assumed from the OS version:** model availability, context size, PCC entitlement and eligibility, HealthKit availability, and iCloud account status.

## B.2 Package targets and the dependency graph

The MVP uses **one local Swift package with six targets**. Finer logical modules live as folders inside targets, and they get split into their own targets only when that gives a concrete benefit.

```
Domain  ◄──  Data  ◄──  Companion
  ▲           ▲  ▲          ▲
  │           │  └── Relay  │
  └── Experience            │
        ▲                   │
        └──── Features ─────┘   (Features depends on all five; App depends on Features)
```

| Target | Contains (folders) | Depends on | Must not import |
|---|---|---|---|
| `Domain` (pure) | `GrowthEngine` (the brain), domain types (Entry, Evidence, Pillar, Grant…), rule sets, `LivedDay` | Foundation only | GRDB, CloudKit, HealthKit, FoundationModels, SwiftUI, UIKit |
| `Data` | `RecordStore` (GRDB), `ProjectionService`, `GrantService`, `Sync` (CKSyncEngine), `Evidence` (HealthKit), `HealthLocalStore`, `ExportImport`, `Deletion`, the persistent `Outbox` and `RelayQueue` tables | `Domain` | FoundationModels, SwiftUI |
| `Relay` | `RelayClient` (App Attest transport), `RitualClient` (uses `Data`'s `RelayQueue` for offline joins) | `Domain`, `Data` | SwiftUI |
| `Companion` | AI routing, task definitions, `SourceRegistry`, safety validators, the non-generative fallback, Companion memory service | `Domain`, `Data` | SwiftUI |
| `Experience` | `Theme` (tokens), `Flame` (Metal), `Sensory` (haptics/sound) | `Domain` | `Data`, `Companion` |
| `Features` | SwiftUI screens: Today, Flame, Paths, Companion, Record, Settings | all of the above | — |

**Orchestration:** `Features` calls *commands* on `Data` (for example `RecordStore.complete(action:)`). `Data` writes the entry and its outbox row in one transaction, then asks `ProjectionService` to refresh. `ProjectionService` calls the pure `Domain.GrowthEngine`. `GrantService` applies eligible grants as a separate command (§B.3). `Experience` receives only derived state (`FlameParams`, `ThemeState`) and never touches storage.

**Rules:**
1. `Domain` compiles and passes tests with Foundation as its only import. It's the reference for a future Android port.
2. No `Features` or `Experience` code hard-codes a color, font, duration, sound or haptic. It reads from `Theme` (decision 35). Enforced by a lint rule plus a review checklist item.
3. Only `Data/Evidence` imports HealthKit. Only `Companion` imports FoundationModels. Only `Data/Sync` imports CloudKit. Only `Relay` makes network calls to the Relay.

## B.3 The brain, projections and grants

**Pure engine:**
```
GrowthEngine.compute(entries: [Entry], asOf: Instant, settings: EngineSettings, rules: RuleSet) -> DerivedState
```
- **Deterministic.** Entries are sorted internally by `(livedDay, occurredAt, id)`, so the same set of entries in any arrival order gives the same result. Tests run permutations of the same set.
- **`asOf` is an explicit input,** so Vitality decays with the passage of time even when there are no new entries.
- **No writes.** It returns `DerivedState`, which includes `eligibleGrants: [EntitlementKey]`.
- **Golden test vectors:** `Domain/Tests/Vectors/*.json` hold hand-checked `{entries, asOf, settings, rulesVersion} → expected DerivedState`. They're the platform-neutral contract.

**Projection refresh (`ProjectionService`):**
- Triggers: a local write, a sync ingest, app foreground, crossing a lived-day boundary, background refresh, and a `rulesVersion` change.
- Each stored projection carries `rulesVersion`, `asOf`, and `inputRevision` (a monotonic counter bumped by every ingested entry, local or synced). If an ingested entry's sort key is earlier than the projection's last sort key, or it's a correction, the projection is **fully recomputed**. For MVP-scale records that's cheap; incremental invalidation is a later optimization.
- Projections are local caches: never synced, always rebuildable.

**Grants (`GrantService`), the "never taken back" promise:**
- Every reward or milestone has a deterministic **`entitlementKey`** (e.g. `reward:week-40-callers:2026-W40`, `milestone:transformation-1`).
- The `rewardGranted` entry carries `entitlementKey`. The projection treats the **set of entitlement keys** as ownership. Duplicate grants of the same key from different offline devices collapse to the earliest by `(recordedAt, id)`. The duplicates stay in the append-only record but are ignored.
- `GrantService` runs after each projection refresh, and emits `rewardGranted` for eligible keys not yet owned, in its own transaction.
- **Ownership ≠ presentation.** `milestoneWitnessed` records that the user *saw* the moment (so it isn't celebrated twice). Ownership never depends on having witnessed it.
- **Formula changes (decision 58): each day is scored by the rules of its time.** Every lived day carries its `rulesVersion` (via its `dayPlanned` entry, chapter 04 §B.1), and the engine keeps every published rule set forever. There are no legacy offsets. History changes only through user corrections.
- An owned Transformation constrains the displayed theme to at least that stage. The **MVP** mapping is defined in **chapter 03** (on the MVP planning track); chapter 10 extends it later.

## B.4 AI routing (`Companion`)

**MVP tiers** (decision 49): tier 1 = on-device `SystemLanguageModel`; tier 2 = Apple PCC. Tier 3 (frontier, via the Relay) is **post-MVP** and requires (a) a Relay-backed `LanguageModel` adapter, since direct provider packages must never bypass the Relay, (b) an explicit consent screen per App Review 5.1.2(i), and (c) verified zero-retention terms for the actual account and endpoint.

**Per-task outcome matrix** (every task defines each row; the MVP task list comes from chapters 05 and 07):

| Condition | Required behavior |
|---|---|
| Tier 1 available | Use it for tasks marked on-device-capable |
| Tier 1 unavailable (device, settings, region, model not downloaded, language) | Use tier 2 if eligible; otherwise the non-generative baseline |
| Tier 2 unavailable (no entitlement, ineligible, daily allowance, outage, offline) | Tier 1 if acceptable for the task; otherwise queue (below); otherwise the baseline |
| Both unavailable | **Non-generative baseline:** curated content from the content catalog (hand-written Sparks, encouragement, plan templates). The day is always ready. |
| Safety validation fails | Fail closed: don't show the output, fall back to the baseline, and log a non-personal diagnostic code |

- **Queue:** a local table; entries expire after 7 days and the user can see or cancel them. Queued content follows data classification (health-classified content is queued only in the phone-only store in phone-only mode).
- **Context size** is read at runtime (`model.contextSize`) and prompts are budgeted with `tokenCount(for:)`, never with hard-coded sizes.
- **Guided generation** (`@Generable`) for all structured outputs. This constrains *structure only*. Safety comes from the validators below.

**Safety and sources:**
- **`SourceRegistry`:** a versioned, curated list of approved sources (`sourceId`, title, publisher, URL, summary of what it supports). It ships in the content catalog.
- A generation task receives **only** the registry excerpts relevant to it. Any `sourceId` in the output must resolve to one of the supplied IDs, or the output is rejected. The model can't invent citations.
- **Deterministic validators** per task type (e.g. running plans: maximum weekly volume increase, required rest days, no plan for flagged medical contexts), versioned in `Domain` rule sets.
- Unsupported domains (medical, eating disorders, mental-health crisis) get fixed, reviewed referral responses, never generated ones.
- **Chapter 07 defines** the exact task list, validators, referral texts and adversarial evals. **Plan generation can't ship until chapter 07 is approved.**

## B.5 Health data (decisions 50, 57)

**Build-time mode:** `HealthFactSyncMode = .allowed | .phoneOnly`, set by Apple's written answer. **The default until then is `.phoneOnly`.**

**Rule of thumb (decision 59): structure and numbers are P; words and health readings are H2.**

Every record entry is a **P envelope** (it always syncs) that may have **H2 attachments** (a separate table keyed by `entryId`, stored per mode):

| Class | Contents | `.allowed` | `.phoneOnly` |
|---|---|---|---|
| **H1 Measurements** | Values read from HealthKit | Never stored by the app | Same |
| **H2 attachments** | All words: Path goal wording, generated Spark text, plan revisions (all pillars, since they're prose), notes, Companion memory text, drafts, queued AI requests. All health readings: `evidenceAssessed`, `levelSeeded` (HealthKit-derived L0) | Synced | `health-local.sqlite`, backup-excluded, never synced |
| **P envelopes** | IDs, kinds, instants, `livedDay`, `occurrenceKey`, catalog references, pillar weights, `d` (explicitly allowed, decision 59), `isEdge`, rest flags, `dayPlanned` slots, grants, corrections, `feedbackGiven`, `momentWitnessed` | Synced | Synced |

**Rules:**
- A P envelope never contains free text, HealthKit sample references or evidence. Catalog-sourced text is referenced by `catalogRef` (the words live in the public catalog, not in user data).
- A value's class is the highest class of its inputs, except for `d`, which is a P scalar by explicit decision (59).
- Temporary files, caches, queues and export staging inherit the class of their contents (H2 → the backup-excluded directory).
- H1 values must never be written into H2 text by the app (for example, a validator on Companion memory writes).
- A missing H2 attachment after device loss renders as "not available on this device," never as an error or a loss of growth.
- **Growth reads P only.** `GrowthEngine` consumes P envelopes (completions, `dayPlanned`, corrections, feedback). So Depth, G, Vitality, levels-after-seed and grants are fully reconstructible from synced data.

**Recovery (`.phoneOnly`, new device):** all P data syncs back, including every `dayPlanned` (scoring sets, difficulties, rest flags). So **Depth, G, Vitality and grants are reconstructed exactly**, including days with zero completions. H2 evidence is re-assessed from HealthKit where the samples are available (a new `evidenceAssessed` attachment with `provenance: reassessed`); otherwise the Action shows as self-reported. Level seeds are re-derived from HealthKit, or from the Companion if HealthKit is unavailable. Adaptation events are P, so levels converge. Plan wording is regenerated by the Companion on request.

**Backup exclusion** is verified by a test after every schema migration.

## B.6 Evidence provenance and HealthKit writes

- **`deviceVerified`** requires all of the following:
  - a HealthKit sample **not written by this app**;
  - `HKMetadataKeyWasUserEntered` absent or false;
  - the sample's `sourceRevision.source.bundleIdentifier` is in the **trusted-source allowlist** (Apple's own sources, such as the iPhone and Apple Watch, in the MVP; partner apps are added in chapter 09);
  - the sample meets the criterion.
  - Samples from any other source can support completion but stay `selfReported`.
- App-written samples (health-type self-reports) remain **`selfReported`**.
- **HealthKit write protocol:**
  1. persist an `operationId`;
  2. write the sample with `HKMetadataKeySyncIdentifier = operationId` and `HKMetadataKeySyncVersion = 1`, which is idempotent on retry;
  3. write the entry referencing the operationId;
  4. on launch, reconcile orphans in both directions.
- If a write is denied, the type is unsupported, or HealthKit is unavailable, the Action is still completed (self-reported, private). Completion **never** depends on HealthKit (P4).
- **Evidence de-duplication:** a HealthKit `sampleUUID` can be evidence for at most one occurrence. **No HealthKit identifier ever appears in a P envelope** (Codex round 4, blocking #2).
- **Auto-detected activity is a suggestion, not an automatic completion.** When a HealthKit workout matches an open slot, the app offers "Count this morning's run?". Confirming completes **that slot** (its app-owned `occurrenceKey`), so slot keys de-duplicate across devices. If no slot matches, the confirmation creates a free Action (`free:{entryId}`). The sample → occurrence mapping lives only in the H2 `evidenceAssessed` attachment. **Accepted limitation:** confirming the same unmatched workout on two devices creates two free Actions. That's the user's responsibility (P2), and the same device never offers an already-mapped sample twice.

## B.7 The Relay (MVP: Rituals only)

- **Runtime (proposed):** Cloudflare Workers (TypeScript) + Durable Objects. Confirmed when built.
- **Endpoints (MVP):**
  - `GET /catalog/{version}` (public, unauthenticated, signed content, §B.10)
  - `POST /attest/challenge`
  - `POST /attest/register`
  - `POST /ritual/{ritualWindowId}/join`
  - `GET /ritual/{ritualWindowId}/count`
- **Authentication (decision 48):** App Attest.
  - Registration stores `{keyIdHash, publicKey, assertionCounter, registeredAt, lastSeenAt}`.
  - Every request carries an assertion over a server challenge plus the request hash; the counter must strictly increase.
  - A reinstall gets a new key. Keys unused for 90 days are deleted.
  - **This is minimal pseudonymous state, and it's disclosed plainly** (chapter 20).
- **Ritual counting:**
  - The count means **"participating app installations,"** and the UI copy reflects that honestly (for example "41,209 joined," not "41,209 people").
  - De-duplication: the Durable Object stores `SHA-256(keyIdHash ‖ ritualWindowId)` and atomically inserts it and increments the count.
  - **Acceptance deadline:** window close + 72 h (for offline joins). De-dup hashes are deleted at the deadline + 7 days. Only the aggregate count is retained.
- **Load target (MVP):** fewer than 1,000 installs, so one Durable Object per `ritualWindowId`.
- **Scale path (documented, not built):** shard by `hash(keyIdHash) mod N`, with the aggregate read cached for 60 s at the edge. Cloudflare guidance is roughly 500–1,000 simple requests/s per object.
- **Logging:**
  - no request bodies, IP addresses or key identifiers in logs;
  - Worker observability configured to status codes and latency only, and verified;
  - a documented retention table in chapter 20.
- **Kill switch:** a config flag that disables joins; the app shows the last known counts.
- **Retries:** Ritual joins are idempotent (de-dup), so safe to retry. The (post-MVP) AI endpoints need request IDs and must never auto-retry billable calls without idempotency.

## B.8 Sync (`Data/Sync`, CKSyncEngine, private database)

- **Zones are generation-named:** `Record-{gen}`, `Working-{gen}`, plus a permanent `Meta` zone holding the **generation lifecycle** (§B.9). Generation IDs are random and carry no personal data.
- **Outbox:** every local write inserts its outbox row **in the same transaction**. Each row is tagged with the generation it was created under. CKSyncEngine's `nextRecordZoneChangeBatch` reads from the outbox, and rows are removed only after a confirmed save. Rows tagged with a retired generation are discarded, never sent.
- **Engine state:** `stateSerialization` is persisted in the database on every `stateUpdate` event. CKRecord system fields are stored in a separate metadata table.
- **Errors:** handled per `CKError` category (retry with backoff, zone-not-found → **never recreate**: re-fetch `Meta` and follow §B.9, quota exceeded → the decision-32 UI, partial failures handled per record).
- **Conflicts:**
  - Entries are immutable. Same ID + same canonical content hash (which covers **every immutable field, including `recordedAt`**; chapter 17 §B.2) = no-op. Same ID + different content = **quarantine** both, plus a non-personal diagnostic, and the projection uses neither until resolved.
  - `PlanRevision` records are immutable. The `ActivePlan` pointer and `Setting`s are last-writer-wins by `modifiedAt`, with deterministic tiebreak by device ID.
  - Memory: create-only plus **tombstones** for deletion; a tombstone always wins.
- **Account isolation:**
  - The local database is namespaced by a hash of the iCloud user record ID.
  - On `accountChange`: stop sync, keep the old namespace's data local and untouched, **never upload it to the new account**, and ask the user.
  - No-iCloud mode uses a `local` namespace. When iCloud becomes available, the user explicitly chooses to attach it.
- **Offline-first:** the tracking-moment code path contains no network calls. A test enforces it.

## B.9 Deletion protocol ("delete everything"), with generation fencing

**Fencing principle:** data is written only into zones named for the *current* generation. A deleted generation's zones are gone, so any stale write to them fails with `zoneNotFound`.

**Generation lifecycle in `Meta`** (Codex round 4, blocking #1): `generations: [genId → state]` with states `proposed → active → retired`, or `proposed → abandoned`, plus `currentGeneration` (always the single `active` one). Every Meta write uses the server change tag; a conflict means re-fetch and re-evaluate.

**Zone creation happens only inside the generation-creation procedure, for a brand-new random ID.** The same ordering applies at first launch and at deletion step 5:
1. mint `newGen` and write Meta with `newGen: proposed`;
2. create `Record-{newGen}` and `Working-{newGen}`;
3. write Meta: `newGen: active`, `currentGeneration = newGen` (and, for deletion, the old generation becomes `retired`).
- If step 3 loses a race to another device's activation: mark `newGen: abandoned` and adopt the winner.
- **Ordinary sync never creates or recreates zones.**

**Sweep (garbage collection):** deletes zones **only** for generations in state `retired` or `abandoned`, **never merely "not current."** A `proposed` generation older than 7 days whose creator never activated it may be marked `abandoned` by any device (change-tagged), and swept after that.

**Deletion intent:** bound to `{accountHash, generationToRetire}`, persisted in the Keychain, and **kept until zone deletion of the retired generation is confirmed**. It isn't cleared merely because Meta records the retirement. A concurrent-deletion loser whose target is already retired keeps its intent until the old zones are confirmed gone (it may perform that deletion itself), then clears it.

1. Persist a `DeletionIntent {generationToRetire, startedAt}` in the Keychain (it survives a local wipe) and stop all outgoing sync.
2. Wipe local data immediately (both stores), so the user sees an instant reset.
3. Run the generation-creation procedure (above). Its step 3 marks the old generation `retired`.
4. Delete zones `Record-{old}` and `Working-{old}`. Retry until confirmed; the intent survives relaunches.
5. Once deletion is confirmed, clear the intent.
6. **Stale device B** (the interleaving from Codex round 2): B's prepared upload to `Record-{old}` fails with `zoneNotFound` once step 4 completes. If it lands *before* step 4, those records are deleted with the zone. B then re-fetches `Meta`, sees its generation is `retired`, discards its outbox and local data for that account, and informs the user. **Nothing ever recreates a zone for an existing generation ID, so resurrection is impossible.**
7. **HealthKit samples written by the app:** the user is offered a choice to delete them too.
8. **Exports the user saved** are the user's files and aren't touched. The confirmation screen says so. An export's manifest records its generation, and import honors the generation lifecycle (retired generations) (chapter 17 §B.9).
9. **Single memory deletion** = tombstone (§B.8).
10. **Verification requirement:** the scenario tests (chapter 22 §B.4) must confirm on real CloudKit that saves into a deleted zone fail with `zoneNotFound` and don't recreate the zone implicitly. This is the platform behavior the fencing relies on.

## B.10 Content catalog (hook for chapter 28)

A public, read-only, versioned bundle (Sparks, Ritual definitions, source registry, plan templates, milestone definitions, story/world content). It's signed (the signature is verified on device) and **served from the Relay domain at `/catalog/{version}`** with edge caching, so no extra host is allowlisted. It's cached on device, falls back to the bundled version, and contains no user data. The format is defined with chapter 28.

## B.11 Non-goals for the foundations
- No custom backend database. No user accounts. No analytics SDKs. No third-party UI frameworks. No cross-platform frameworks. No frontier AI in the MVP.

## B.12 Research sources (checked 2026-09-30)
- Apple WWDC26, "What's new in the Foundation Models framework": https://developer.apple.com/videos/play/wwdc2026/241/
- Private Cloud Compute eligibility: https://developer.apple.com/private-cloud-compute/ (Small Business Program, a threshold of 2M first-time downloads for any app, and the PCC entitlement; both eligibility conditions are monitored) · https://daringfireball.net/linked/2026/06/13/pcc-severely-limited-third-party-developers
- iOS 27 release (14 Sept 2026): https://9to5mac.com/2026/09/09/apple-confirms-ios-27-release-date-september-14/
- App Review Guidelines 5.1.2(i), 5.1.3: https://developer.apple.com/app-store/review/guidelines/
- 5.1.3(ii) ambiguity: https://github.com/jirigrill/eczema-helper/issues/675
- HealthKit authorization (denied vs. no data): https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data
- CKSyncEngine state and account changes: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/stateupdate/stateserialization · https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/accountchange
- App Attest server validation: https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server
- Durable Objects guidance: https://developers.cloudflare.com/durable-objects/best-practices/rules-of-durable-objects/
- File-system backup behavior: https://developer.apple.com/documentation/foundation/using-the-file-system-effectively
- Note: the CloudKit public-database throughput figure cited in revision 1 (~40 req/s, from a forum post) is **unverified** and no longer used as a rationale. The Relay is chosen because the CloudKit public DB isn't designed for high-contention shared counters.
