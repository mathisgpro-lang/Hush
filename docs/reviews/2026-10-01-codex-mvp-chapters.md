# Independent technical review — MVP chapters, Part B

Report date: 2026-10-01. Reviewer: Codex. Documentation checked during this review on 2026-09-30 (session date).

**Verdict: the set is not ready for implementation plans as a whole.** M0 can proceed as the authorized throwaway feel prototype. Production planning needs the scoring, recovery and safety decisions below resolved first. This is a specification review, not a code or clinical validation.

Baseline: AGENTS.md, CLAUDE.md, decisions 1–66, and approved chapters 04, 16, 17, 20 and 22. Decisions 58–59 govern historical scoring and P/H2 separation; 60 separates engineering details from trust/safety decisions; 63 authorizes defaults; 66 approves the foundation. A `[by default]` label is **not a finding**. Unrelated resume instructions were not executed because this assignment permits only this report to change.

The new chapters correctly retain Apple-only MVP AI, offline completion, private progress, immutable plan revisions and theme tokens. No new chapter explicitly introduces frontier AI. The problems below are specific gaps in making those commitments executable.

## Chapter verdicts

“Ready with fixes” means the chapter's main contract is usable once the listed bounded fixes are incorporated. “Not ready” means implementing it would require inventing product, safety or recovery policy.

| Chapter | Verdict | Main reason |
|---|---|---|
| 03 — The Flame | **not ready** | Permanent motifs can recede; birth identity is undefined; earnable stages exceed available art. B1, B2, B12 |
| 05 — Daily loop | **not ready** | Pause and multi-Path reflow change scoring and training without a complete contract. B3–B5 |
| 06 — Tracking moment | **ready with fixes** | Persistence must win over animation deadlines; failure/Undo behavior needs a concrete plan. B11; D1–D2 |
| 07 — Companion | **not ready** | Safety can fail open or disappear between sessions; plans and Q&A lack sufficient safety contracts. B5–B8 |
| 08 — Birth | **not ready** | Offline birth conflicts with recovery and generation creation; resume state is incomplete. B2, B9 |
| 12 — Identity | **ready with fixes** | Platform choices are largely valid; icon system alerts, font APIs and safety-copy exceptions need documenting. B8; D2–D4 |
| 23 — MVP | **not ready** | M1–M4 depend on work deferred to M5–M7; PCC/provisioning and health gates are misplaced. B9–B10 |
| 28 — Adventure | **not ready** | Hidden Sparks bypass the ordinary safety schema; durable Chronicle and catalog contracts are incomplete. B5, B13; D5–D6 |

## BLOCKING findings

### B1 — Permanent visual growth can shrink or stop appearing

**File/section:** `docs/master-plan/03-the-flame.md` §B.2, §B.5. **Gate:** M2.

**Problem:** `motifStrength_p = sqrt(depth[p] / maxDepth)` drives the motif's reveal mask. With Body = Mind = 10, both strengths are 1. Raising Body to 40 reduces Mind's strength to 0.5 despite losing no Mind Depth. A single-pillar user reaches strength 1 at Depth 1 and never extends that mask again. Below Depth 1, a pillar has no motif at all. The unbounded global `intricacy` does not specify how it repairs either result. A persistent minimum increment for every raw completion also conflicts with deduplicated growth: replaying an existing occurrence must not extend the true vessel.

**Concrete fix:** Separate relative emphasis from permanent geometry. Define a monotone per-pillar reveal/detail function of absolute Depth, plus a deterministic expansion scheme beyond a filled mask. Use relative shares only for emphasis that does not erase built detail. Animate only the actual before/after derived change; zero-credit duplicate/replayed writes get no permanent addition. Add vectors for the 10/10 → 40/10 case, first sub-1 contribution, single-pillar growth and duplicate completion. The mapping choice belongs in the chapter; rendering tolerances belong in the plan.

### B2 — Birth has no safe offline/recovery or single-seed contract

**File/section:** `docs/master-plan/08-the-birth.md` §B.1–B.2, §B.4; `03-the-flame.md` §B.1. **Baseline:** 16 §B.8–B.9. **Gate:** M1/M4.

**Problem:** First launch must fetch Meta to discover a prior Flame, yet steps 1–2 must be offline with zero network, and generation creation must precede `flameBorn`. The approved generation procedure requires CloudKit writes. Meta holds generation lifecycle, not the `flameBorn` entry. An unavailable fetch is not proof that no Flame exists. Two offline installations can create two different seeds; no selection/adoption policy exists. LWW `birthStep` alone also cannot make “write event, advance step” crash-safe. Re-entering birth may mint another seed or repeat the first completion.

**Concrete fix:** Specify three explicit states: recovered dataset, confirmed new dataset, and cloud state unknown. Define provisional local birth under the approved local namespace, how the user attaches/adopts it when iCloud returns, and how a pre-existing Flame is handled without silently overwriting identity or merging accounts. Fetch the active generation's Record zone after Meta. Define one canonical birth identity per dataset, an explicit concurrent-birth policy, and idempotent command IDs for every onboarding write. Commit/resume each step through the existing journal/transaction rules. Test offline reinstall, partial sync, two births, kill after write but before step advancement, and a retired generation. A recovery/merge policy is not an implementation detail.

### B3 — Pause can last indefinitely, change rewards unexpectedly, and expose a health reason

**File/section:** `docs/master-plan/05-daily-loop.md` §B.3; `07-companion.md` §B.4. **Baseline:** 04 §B.4–B.6; 16 §B.5; decision 59. **Gate:** M1/M3.

**Problem:** Checking the 14-in-90 allowance only at `pauseStarted` cannot bound an open-ended pause. There is no planned end or automatic expiry. `pauseEnded` lacks a pause ID; overlap, concurrent starts and inclusive/exclusive boundaries are undefined. Setting presence to 1 feeds the existing comeback/forgiveness algorithm, potentially relighting the Flame and completing a comeback through pause alone. “Normal completion” when an Action is logged on a paused planned-rest day can select the full rest credit. Skips still feed level reduction unless explicitly excluded. Finally, a P `reasonCode` that means “sick” reveals health information; encoding a word as an enum does not make it harmless structure under the highest-input-class rule.

**Concrete fix:** Specify bounded intervals, automatic end, overlap/merge and per-day quota evaluation from synced P events. Define precedence among pause, rest and completed effort, and whether pause freezes Vitality or intentionally counts toward comeback; add a distinct vitality treatment if necessary. State whether paused slots produce skips. Keep a neutral pause fact in P; omit the reason or keep it H2. Update the reference vectors for quota exhaustion without reopening, concurrent devices, rest overlap and comeback. These are scoring/privacy choices, not permission to retune approved past days.

### B4 — Three-Path dealing and undealt-day scoring can describe different days

**File/section:** `docs/master-plan/05-daily-loop.md` §B.1–B.2; `23-mvp.md` §B.1 M3. **Baseline:** 04 §B.1, §B.6; 17 §B.4. **Gate:** M3.

**Problem:** Chapter 05 aggregates active Paths and caps three slots; chapter 04's undealt-day materialization speaks of the latest effective schedule. No shared multi-Path aggregation/reflow contract reconciles them. “Defer to the next day” does not say how stable occurrence keys, rest days, collisions or repeated overflow work. A lower-priority Path can starve indefinitely. Dealt plans can differ in denominator/rest status from days materialized after an absence. Spark selection has no result when all safe candidates were dealt in the last 30 days, when `recentMix` is nil, or when several Hidden Sparks qualify. The dealer also does not explicitly write `sparkDealt`, although Spark occurrence keys and once-per-user discovery require it.

**Concrete fix:** Define one scheduler used for both materialization and dealing: latest revision **per Path**, combination/rest precedence, priority and overflow policy, stable slot/occurrence identities, and effective dates for reflow. Never silently revise a frozen day contract. Define a safe catalog fallback, nil-mix and multiple-candidate ordering, and atomic `sparkDealt`/`dayPlanned`/swap writes. Preserve the approved max-over-contracts rule. Reflow that changes health sessions must pass B5's combined safety check.

### B5 — Training limits apply to individual templates, not the actual day delivered

**File/section:** `docs/master-plan/07-companion.md` §B.2–B.3; `05-daily-loop.md` §B.1–B.3; `28-the-adventure.md` §B.1. **Gate:** M3/M4.

**Problem:** A valid running plan can become unsafe when combined with strength, a 1.25-stretch Body Spark, postponed sessions and pause recovery. The specification does not validate that combined schedule. Hidden Spark records have no `safetyTags`, track or stretch, and their selection path does not expressly apply the safe-context filter. The running generator's +10% progression and chapter 04's +7% level bumps are separate engines with no agreed authority. Three bumps are +22.5%; adding a weekly clamp without defining its baseline, time window and application to final sessions is not sufficient. Safe rest may be undone by reflow.

**Concrete fix:** Make a deterministic validator of the **final combined prescription** mandatory after generation, adaptation, dealing, swap and reflow. Define workload/intensity/rest constraints across Paths and Sparks; use the same safety schema for Hidden Sparks. Specify which engine owns targets, how deload and return-from-absence affect them, and how clamp results are reflected in the frozen target and difficulty. Clamp all fallback plans too. If safe work cannot fit, offer less or no training; do not accumulate catch-up debt. Preserve historical P scores.

### B6 — Safety screening has an undefined failure path and no durable stop

**File/section:** `docs/master-plan/07-companion.md` §B.1, §B.4, §B.7; `08-the-birth.md` §B.5. **Gate:** M4.

**Problem:** Screening requires tier 1 plus keywords, but tier 1 can be unavailable even while PCC is available. Refusal, timeout, unsupported language and malformed classifier output have no specified disposition. Keywords do not establish safety. Flags disappear after the session; a chest-pain or injury referral therefore does not prevent tomorrow's existing schedule or Spark. The birth test explicitly allows continuation after a safety flag without defining which Path is still allowed. Generated tasks without user input cannot meaningfully run the specified “user input” pre-check.

**Concrete fix:** Define a safety outcome matrix independent of task routing. Missing/uncertain screening must withhold personalized health guidance and use reviewed low-risk content, never silently bypass the check. Define stop/continue/resume transitions and which domains remain available. Either persist a minimal restriction as H2 with an approved recovery policy, or require fresh clearance screening before health prescriptions whenever safety state is unknown; do not move flags into P to solve recovery. Apply screening to relevant context and validate output. Test next-day, relaunch, new-device and both-models-unavailable cases, not just single prompts. This needs an explicit safety/privacy decision.

### B7 — The “proven” plan library is not specified or supported at the claimed level

**File/section:** `docs/master-plan/07-companion.md` §B.2–B.3, §B.5–B.6; `23-mvp.md` §B.1 M4 (scope in §A.3). **Gate:** M4.

**Problem:** Only one running outline exists; “other generators follow the same pattern” leaves seven launch Paths' programs to the implementer. Strength minutes do not constrain load, exercises, sets, repetitions or recovery. Running has no defined run/walk progression, intensity definition for “hard,” suitability screen, progression after a deload, or return-to-running policy. A minimum race horizon plus volume caps does not prove readiness. The generic kilometer progression cannot simply be presented as NHS Couch to 5K: the NHS program uses nine weeks of run/walk sessions with rest between runs, ending in 30 minutes of running. [NHS plan](https://www.nhs.uk/better-health/get-active/get-running-with-couch-to-5k/couch-to-5k-running-plan/)

**Concrete fix:** Provide a versioned template contract for each shipped Path: eligible population, parameters, exact actions/doses, progression, recovery, exclusions, deterministic safe default and source-to-rule mapping. Use an identifiable beginner program faithfully, and separately justify any modifications and 10K/half-marathon progression. Do not call a collection of invented thresholds “proven.” Have health content and fixed safety text reviewed by someone qualified for that content before personal training use. Narrowing the launch library is a scope choice, not something an agent should do invisibly. Evals test adherence to the approved contract; they cannot establish clinical safety by themselves.

### B8 — Q&A and referrals can still deliver unsafe or mislocated advice

**File/section:** `docs/master-plan/07-companion.md` §B.1, §B.4–B.6; `12-identity.md` §B.2. **Baseline:** 16 §B.4; 20 §B.3. **Gate:** M4.

**Problem:** A supplied `sourceId` can accompany an unsupported claim. “Banned claims” is not defined, and unconstrained Q&A can prescribe an unsafe workout while bypassing the plan validator. `spark.phrase` can also change a safe instruction's meaning. Referral text is referenced but absent. Chest pain is grouped with routine “see a doctor first,” although some presentations require immediate emergency help. `Locale`/region is not a reliable current physical location, especially while travelling. The blanket copy ban can reject necessary crisis wording such as “hopeless”/“lost” descriptions or legitimate warnings. `findahelpline.com` and source URLs are outside the approved app-network allowlist if fetched in-app. [NHS emergency distinctions](https://www.nhs.uk/conditions/chest-pain/?ContensisTextOnly=true)

**Concrete fix:** Limit health Q&A to reviewed, source-bound answer content, or validate every actionable prescription through the same health rules as a plan. Require semantic preservation for Spark phrasing. Supply reviewed emergency, non-emergency and crisis texts, severity precedence and an offline resource table; let users confirm/change their country rather than treating locale as location. Make safety copy authoritative over the motivational word ban. Open optional external resources only through an explicitly defined user-initiated browser handoff with no personal data in URLs; no embedded fetch outside `NetworkGate`. Keep the core help usable without that link.

### B9 — M4 introduces sensitive storage and health behavior before their gates

**File/section:** `docs/master-plan/23-mvp.md` §B.1–B.2; `08-the-birth.md` §B.2; `07-companion.md` §B.1, §B.7. **Baseline:** decisions 50, 59; 16 §B.5; 17 §B.8; 20 §A.4. **Gate:** M1/M4.

**Problem:** M4 creates H2 answers, profile, plans, notes and queued requests, but H2 isolation/backup exclusion is listed at M6 and both storage modes at M5. Backups can leak before CloudKit is implemented. M4's birth includes HealthKit, though M6 alone requires Apple's answer. The standing requirement is before building health features, not merely before enabling the HealthKit adapter. `levelSeeded` is described as an H2 entry in chapter 08 instead of the approved P track envelope plus H2 attachment. No attachment owner is defined for BirthProfile.

**Concrete fix:** Move class-aware stores, backup exclusion, safe logs, cross-store journal and local deletion into M1, before real input. Make all M4 tasks use them. Resolve Apple's health-data gate before real health feature work, or explicitly limit the earlier milestone to synthetic data and non-health Paths with the Health step unavailable. Preserve the chapter 17 envelope model and add a defined BirthProfile attachment owner. Do not interpret `.phoneOnly` as permission to ignore the founder's Apple-answer gate.

### B10 — Milestones omit required work and overpromise free PCC access

**File/section:** `docs/master-plan/23-mvp.md` §B.1–B.2, with §A.2/§A.6 prerequisites; `07-companion.md` §B.1. **Gate:** M0–M4 planning.

**Problem:** M3 needs accepted schedules before M4 builds plans; no temporary curated-plan acceptance path is assigned. `path.adapt` is absent from M4 and every later acceptance row despite being an MVP task. M4 needs templates, referrals, sources and fallback content although the catalog route arrives in M7. M2 consumes a real seed that M4 alone creates. M1 implements chapter 04 “exactly,” but M3 adds pause semantics that its oracle does not define. PCC before M4 also conflicts with a free Personal Team “real MVP” stage and membership only before M5.

**Concrete fix:** Add a dependency checklist: bundled validated catalog and neutral seed fixture at M1/M2; curated schedule acceptance at M3; production birth identity and `path.adapt` at M4; remote catalog transport only at M7. Extend the oracle with approved pause semantics before M1 closes. Distinguish a free local/template build from the full PCC/iCloud MVP. Apple requires PCC eligibility, an entitlement and Small Business Program enrollment, and documents testing via TestFlight or ad hoc distribution; on-device tests are possible with a Personal Team but that does not establish PCC access. Schedule the appropriate paid provisioning before PCC acceptance and obtain founder authorization for spending. [Apple PCC eligibility](https://developer.apple.com/private-cloud-compute/), [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)

### B11 — The tracking deadline must not manufacture success or lose a completion

**File/section:** `docs/master-plan/06-tracking-moment.md` §B.1–B.2 (Undo promise in §A.6); `23-mvp.md` §B.1 M3. **Baseline:** 16 §B.2, §B.8; 17 §B.7. **Gate:** M3.

**Problem:** “Must commit before 900 ms” has no safe outcome for a slow local commit. Local writes can fail or be delayed despite being offline. Reversing the animation at a deadline while the transaction later commits can invite a duplicate retry; showing the landing before durable success can celebrate work that is lost on termination. The five-second Undo is not connected to append-only corrections or an in-flight commit.

**Concrete fix:** State that durable success, including the outbox, controls permanent landing/growth; 900 ms is a performance target. A delayed write stays pending and cannot become an independent retry. Retry the same command ID, reconcile outcome after relaunch, and append a void correction for Undo once the original write exists. Never delete the Action row. Define whether already-issued grants remain after Undo (the foundation says yes). Tests must cover delayed commit, disk failure, kill, rapid repeat activation and Undo during a pending write. Actor scheduling details can wait for the plan; this durability policy cannot.

### B12 — Reachable Eras have no renderable implementation

**File/section:** `docs/master-plan/03-the-flame.md` §B.4–B.5; `12-identity.md` §B.3; `23-mvp.md` §B.1 M2/M7. **Gate:** M2/M7.

**Problem:** Stage 3 and 4 grants are active MVP rules, but only veiled silhouettes are supplied. A beta user can reach 150 active days, or import/backdate legitimate history. A grant must constrain the displayed stage; there is no complete theme/vessel/icon for it. A short planned beta duration is not an enforceable data invariant.

**Concrete fix:** Define renderable fallback presentations for every earnable stage, or explicitly decide which stage grants are enabled in MVP and how later activation works without revoking owned entitlements. Do not silently keep a stage-3 owner in Stone/Metal or dereference missing assets. This is a product/art scope choice.

### B13 — New durable records and catalog data lack a canonical contract

**File/section:** `docs/master-plan/28-the-adventure.md` §B.1, §B.3; `08-the-birth.md` §B.2; `05-daily-loop.md` §B.3; `03-the-flame.md` §B.1. **Baseline:** 17 §B.2–B.3, §B.8–B.9. **Gate:** M1, then M4/M7.

**Problem:** Four new entry kinds are absent from chapter 17 (inventory below). The Chronicle has no same-week concurrency, revision/correction, retention or missing-H2 policy. In `.phoneOnly`, its promised ten-year book is lost with the device unless the user explicitly exported H2. It cannot be exactly regenerated from P because generated wording is not deterministic. The catalog schema omits fields that onboarding and safety require, so a schema-valid catalog can still leave the app without required content.

**Concrete fix:** Add canonical schemas and lifecycle rules before those records are written. All must participate in the approved generation, export/import, hashing and class rules. Define one Chronicle identity per lived week, source revision and duplicate policy; explain that `.phoneOnly` prose is not cloud-backed, and offer explicit H2 export or deterministic replacement summaries. Never silently sync it as P. Complete the bundled catalog contract and validate references, safety data and asset availability before activation. Exact serializer layout is deferrable; deciding what survives a lost phone is not.

## New/undefined data inventory against chapter 17

These are omissions or ambiguities, not a recommendation to make every item a new entry kind. Existing generic `Setting`, derived caches and catalog records should be reused where appropriate.

| New use | Where | Missing definition / required treatment |
|---|---|---|
| `flameBorn {seed, bornAt}` | 08 §B.2; 03 §B.1 | **New entry kind.** P; identity, uniqueness, generation scope, conflict/recovery policy. B2 |
| `pauseStarted {reasonCode, from}` | 05 §B.3 | **New entry kind.** P interval facts; health reason excluded or H2; duration and conflict policy. B3 |
| `pauseEnded {at}` | 05 §B.3 | **New entry kind.** Needs linked interval identity, boundary semantics and concurrency rules. B3 |
| `chronicleWritten {weekId}` + text | 28 §B.3 | **New entry kind.** P identity plus H2 text; cross-store commit, regeneration and duplicate rules. B13 |
| `BirthProfile`, `params`, `tone`, `levelEstimates` | 07 §B.1; 08 §B.2 | H2 attachment structure and owner missing. HealthKit raw values must not be persisted in text. Typed parameter schema needed. |
| `levelSeeded` at birth | 08 §B.2 | **Not new**, but incorrectly abbreviated as H2-only; retain 17's P `trackId` envelope and H2 seed/source. |
| `birthStep`, `notifyTime` | 08 §B.1–B.2 | Generic Setting exists; define keys, defaults and scope. A device-local onboarding checkpoint must not inadvertently use ordinary synced LWW settings. |
| Path priority, active/paused/finished state, completion mark | 05 §B.1; feature promise §A.5 | Map lifecycle to existing `pathStarted/Revised/Ended`, define priority storage and completion criterion. The permanent vessel mark has no grant/derived-state contract. |
| Selected `fireStyle`/`vesselForm`, sound/haptic toggles, icon opt-out | 03 §B.1; 06/12 settings | Define Setting keys, scope/defaults, and ownership validation; grants already exist. |
| `recentMix`, `activeDays`, `pausedDays`, `comebackN` | 03 §B.1; 05 §B.3 | Derived state, not new source-of-truth records. Define corrections/dedup/day bounds; derive pause from P, not an unsynced external input. |
| Hidden-Spark deal history | 28 §B.1; 05 §B.1 | Reuse `sparkDealt` with stable catalog identity; define once-per-user scope and offline conflict behavior. No separate hidden mutable counter. |
| Templates, `firstSparks`, birth suggestions, referrals, notification copy | 07 §B.2/B.4; 08 §B.2/B.3; 05 §B.4 | Catalog, not user record. Missing from 28's schema (`voice` currently only has myth and Chronicle templates). Include required safe defaults and rule/source IDs. |
| Memory candidates from three tasks | 07 §B.7 versus §B.1 | `CompanionMemory` exists, but the tasks have no memory output contract. Specify a separate validated command, not arbitrary model writes. |

## DEFERRABLE findings — mandatory implementation-plan items

### D1 — Sensory event arbitration and accurate numbers

**File/section:** `06-tracking-moment.md` §B.2–B.4; `03-the-flame.md` §B.4; `08-the-birth.md` §B.4. **Problem:** One completion can trigger Spark, comeback, full-day and Transformation simultaneously. Birth introduces events absent from `SensoryEvent`; the accessibility text hard-codes growth. **Fix:** Define event priority/queue, interruption, foreground-only playback, actual derived delta formatting and synced witness suppression. Undo grants remain as specified in the foundation. Test VoiceOver/tap/hold parity, Reduce Motion, leaving mid-moment and duplicate sync ingestion. Do not promise a full-day +1% just because the final visible card was completed.

### D2 — Core Haptics is feasible; the absolute platform guarantees are not established

**File/section:** `06-tracking-moment.md` §B.1, §B.3–B.4. **Problem:** AHAP, transient/continuous patterns and intensity/sharpness are valid. A warm engine does not establish an OS guarantee of physical feedback within one display frame. The statement that turning off “system haptics” disables all custom haptics needs device verification; no documented public global-setting query was established in this review. **Fix:** Check `supportsHaptics`, implement stopped/reset handlers, retain an app-level haptics switch, and measure latency under interruption/suspension. Use an audio session category such as `.ambient` to honor silent mode and mix appropriately. Treat timing as a measured target with graceful fallback. **Uncertainty:** test the exact iOS 27 settings behavior on hardware; do not invent a settings API. [Apple haptic setup](https://developer.apple.com/documentation/corehaptics/preparing-your-app-to-play-haptics), [Apple ambient audio](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/ambient)

### D3 — Alternate icons produce a system alert

**File/section:** `12-identity.md` §B.3; `23-mvp.md` §B.1 M7. **Problem:** `setAlternateIconName` is valid, but changing the icon is not a seamless extension of the ceremony: iOS displays a notification alert. **Fix:** Include that interruption in the interaction design, use bundled alternate assets, check support and current icon, handle errors, and avoid repeated calls on witness replay. Honor opt-out; ownership never depends on icon success. No private alert-suppression workaround. [Apple alternate-icon sample](https://developer.apple.com/documentation/xcode/configuring-your-app-to-use-alternate-app-icons)

### D4 — New York is valid; retrieve it through system typography

**File/section:** `12-identity.md` §B.1. **Problem:** `NewYork(weights)`/`SFPro(weights)` are conceptual tokens, not runtime font constructors. **Fix:** Map them to system text styles and `.serif`/default design with Dynamic Type; do not bundle Apple's font files or rely on a literal custom-font name. Apple confirms New York as the system serif: no finding against the font choice itself. Test large text and all live accent combinations, not just one minimum-Vitality palette. [Apple font guidance](https://developer.apple.com/documentation/technologyoverviews/fonts)

### D5 — Catalog selection needs version and exhaustion tests

**File/section:** `28-the-adventure.md` §B.1; `05-daily-loop.md` §B.1–B.2. **Problem:** Hash concatenation/ordering, content-version pinning, safe replacement exhaustion and offline Hidden-Spark races remain unspecified. **Fix:** After B4/B5 settle policy, specify canonical hash bytes and stable sorting, pin deal references to catalog versions, retain referenced content, reject unsupported rule IDs, and test bundled fallback/signature failure. Keep content delivery on the approved Relay host. Do not retroactively alter scoring rules for past lived days through a catalog update.

### D6 — Chronicle generation needs honest scope and week boundaries

**File/section:** `28-the-adventure.md` §B.3; `07-companion.md` §B.1. **Problem:** P-only weekly aggregates cannot substantiate invented details such as a “hard Tuesday.” Missed weeks, travel and correction-driven regeneration are undefined. **Fix:** Define the lived-week algorithm, catch-up range, input snapshot and correction labeling. Restrict narrative to supported counts/deltas and generic imagery; do not infer feelings or undocumented events. Classify generated text as H2 despite P-only inputs.

### D7 — HealthKit read permission is intentionally opaque; onboarding copy overpromises

**File/section:** `08-the-birth.md` §B.2/§B.5 and associated step-5 copy; `23-mvp.md` §B.1 M6. **Problem:** A read-denied test must not imply the app can detect read denial. “Runs can count automatically” contradicts approved confirmed suggestions. HealthKit access after accepting the first plan also leaves timing of reseeding unclear. **Fix:** Test denied and empty-query cases with the same unknown/fallback result; do not use write-authorization status to infer read permission. Say the app can suggest runs to count. Decide when a new seed affects future targets without rewriting today's contract. Keep this MVP read-only; the foundation's write machinery is a future hook, not a reason to request write access. [Apple authorization semantics](https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationstatus(for:))

### D8 — Foundation Models claims are broadly confirmed; availability is still per task

**File/section:** `07-companion.md` §B.1/§B.6; `08-the-birth.md` §B.3. **Problem:** The new chapters rely on a general matrix but do not instantiate retry/queue/cancel behavior for each task. A 90-second onboarding budget must not leave a late model response applying a stale plan. **Fix:** Write per-task availability, refusal, context-limit, cancellation and stale-response fixtures; bind every result to the current account, dataset generation and accepted plan revision. No tier-3 fallback. Apple's documentation confirms `PrivateCloudComputeLanguageModel` on iOS 27 and guided Foundation Models capabilities; the PCC concept is **not flagged as fictional**. **Uncertainty:** this review did not compile the SDK or verify this project's entitlement/device eligibility. [Apple PCC framework documentation](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute)

### D9 — M1 must not port the stale duplicate-selection wording

**File/section:** `23-mvp.md` §B.1 M1; inherited discrepancy: `17-data-model.md` §B.4 versus `04-growth-model.md` §B.2/V12. **Problem:** Chapter 17 still says one highest-`d × edge` completion wins, whereas approved round-6 chapter 04 uses the **maximum contribution per pillar**. The new chapters do not introduce this inconsistency, but “implement the foundation” is ambiguous unless precedence is explicit. **Fix:** Follow chapter 04 and V12, with a plan note and later editorial correction to chapter 17. Do not reopen the settled formula. Port raw-entry permutation/correction fixtures in addition to arithmetic vectors; line coverage is not a substitute.

### D10 — Small missing interaction rules should be resolved in plans

**File/section:** `05-daily-loop.md` §B.4; `08-the-birth.md` §B.1–B.3; `23-mvp.md` §B.1 M0–M4. **Problem:** The extra weekly notification can violate the stated one-per-day cap; the three fallback Path cards are unnamed; changing the first Path, persistent conversation draft scope and resuming on a different lived day are unspecified. **Fix:** Coalesce notifications under one daily budget; choose safe catalog-backed fallback cards; store drafts as H2; define abandon/retry and day-rollover behavior. Show the actual calculated first-day Ascent instead of the illustrative ×1.003. Use a local adult attestation before personalized guidance, with a defined under-18 exit. Keep M0 fake data visibly separate from production data and identify the physical target iPhone for performance acceptance.

## What can proceed

M0's throwaway feel work is sufficiently bounded. M1 planning should wait for B2/B3/B9/B13's data contracts and the approved pause extension. M2 needs B1/B12's truthful render contract. M3 needs B3–B5 and B11. M4 needs the complete B6–B10 safety, content and provisioning gates. Deferrable items belong in the corresponding plans with their specified checks; they are not waivers of the blocking findings.
