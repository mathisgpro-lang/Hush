# 04 — The Growth Model

**Status:** Part A ✅ approved 2026-09-30 (decisions 56, 58) · Part B ✅ approved 2026-10-01 (decision 66, Codex round 6) · **Last updated:** 2026-09-30
**Based on:** decisions 13–15, 47, 51–55 · **Feeds:** chapter 03 (the Flame draws what this chapter calculates), 05, 10, 16 §B.3, 17

Part A is for Mathis. Part B is for the builders (and goes to Codex review).

---

# Part A — For Mathis

## A.1 What this chapter decides

How real life becomes growth in the app. Everything the Flame shows (chapter 03) is a picture of four numbers calculated here:

| | What it is | How it moves |
|---|---|---|
| **Depth** (one per pillar) | Who you've become in Body, Mind, Heart, Spirit, Craft and World | Only grows |
| **Vitality** | How you've been living lately | Brightens and dims, never goes out |
| **Growth number** | Your "1% a day," compounding | Only grows, up to 1% a day |
| **Your level** (per skill) | What "a real effort" means for *you* right now | Adapts continuously |

## A.2 The six pillars *[Settled, 13 and 47]*

| Pillar | Covers |
|---|---|
| **Body** | Movement, strength, endurance, sleep, nutrition, recovery, health |
| **Mind** | Learning, reading, focus, clear thinking |
| **Heart** | Family, friends, partner, kindness, connection |
| **Spirit** | Presence, meaning, gratitude, values, resilience, courage |
| **Craft** | Work, skills and building your life: career, mastery, creativity, money |
| **World** | Your world, from your room to the planet: home, community, helping others, nature |

**Adventure is the spirit of the whole game**, not a pillar. The Spark is the adventure engine across all six.

An Action can feed more than one pillar. A hike with a friend feeds Body *and* Heart.

## A.3 Depth: effort that compounds with consistency *[Settled, 51]*

1. **Every real Action adds Depth**, weighted by how hard it is *for you*.
2. **Within a day, extra Actions in the same pillar count less.** Bingeing never beats showing up.
3. **Coming back to a pillar week after week makes each Action worth more.** Practice builds on practice. Missing days never removes Depth; compounding just pauses.
4. **Pushing past your usual level earns a bonus.** Sparks and comfort-zone challenges.
5. **Verified and self-reported count the same** in your own Flame *[Settled, 55]*.

## A.4 Vitality: alive and responsive *[Settled, 52]*

- It reflects roughly **the last week**, with recent days counting most.
- **One day off is free.** It doesn't dim the Flame at all.
- **Planned rest days never dim it.** Resting when your plan says rest *is* following the plan.
- **After about 3 days away,** dimming becomes visible.
- **After about 2 weeks,** the Flame settles into **embers**: its lowest state, still glowing, never out.
- **The comeback:** your first Action back makes the Flame roar back to life with its own sensory moment, and it's back to full within about 3 days of showing up.

## A.5 The growth number: your 1% *[Settled, 53]*

- **A full day earns +1%.** A "full day" means your day's Actions, at your level.
- **A partial day earns its share,** weighted by difficulty.
- **1% is the ceiling,** so **×37.8 a year** is the true maximum.
- **It never goes down,** except when you correct something logged by mistake.

You start at **×1.00**. After a strong first year you might be at ×20 or ×30. After five years of showing up, the number itself becomes the proof.

## A.6 Your level: always in the flow zone *[Settled, 54]*

- **A starting point with no questions**, from your first conversation with the Companion and (with permission) what Apple Health already knows.
- **It adapts by watching what you do.** Easy and consistent gradually gets harder; skipped or struggled with gently gets easier.
- **Occasional one-tap feedback:** *"Too easy · Just right · Too hard."* It's rare and never mandatory.
- **Sparks aim a little above your level.**

## A.7 Two rules *[Approved, 56]*

**1. Each day is scored by the rules of its time** *(decision 58, replaces "formulas never lower your Flame")*. When we improve a formula, it applies from that day forward. Your past days keep the score they earned, like a sports record. Your history only changes when *you* correct a mistake, and then it changes honestly.

**2. Balance is shown, never forced.** There's no penalty and no bonus for balance across pillars. Your Flame's shape simply *shows* it (chapter 03): a deep Body and young Heart look different from the reverse. The Companion may gently suggest a neglected pillar now and then. It never nags, and a specialist's Flame is just as beautiful.

## A.8 What the numbers look like in practice (starting values, tuned after testing)

| Situation | Result |
|---|---|
| You do your full day, every day, for a week | Growth number ×1.07; Vitality full; Depth grows in the pillars you worked |
| You skip one day | Vitality unchanged (the free day); growth +0% that day |
| You're away 3 days | Vitality visibly dimmer (about 70%) |
| You're away 2 weeks | Embers |
| You come back | The comeback moment; full brightness again after about 3 days of showing up |
| You do 6 workouts in one day | The first two count fully, then less and less. Showing up tomorrow is worth more. |

All the numbers in Part B are **starting values**. We'll tune them by feel during the private beta. Every change applies from that day forward (rule 1).

**Decided (65):** on a **planned rest day** (your plan says rest), resting counts as a **full day**: +1% and full Vitality. Rest is part of growth. Rest days are set by your plan, not by you on the spot, so this can't be used to skip days.

---

# Part B — For the builders

All functions live in `Domain.GrowthEngine`. They're pure and deterministic (16 §B.3). Constants form `RuleSet v1`.

**Reference implementation:** [`reference/growth_reference_v1.py`](reference/growth_reference_v1.py) computes every golden vector in §B.8. The Swift engine must reproduce its outputs within 1e-9. When the spec and the reference disagree, it's a spec bug: fix both and log it.

## B.1 The scoring day (frozen inputs, decision 58)

- **Rule-set effectivity is by lived day:** a published table `ruleSetEffectiveFrom: [livedDay → rulesVersion]` (shipped in the app and the content catalog). `rulesVersion(D)` is a pure function of D, so competing records can never disagree about a day's rules.
- **`scheduleIssued`** (P, decision 59): written when a plan (revision) is accepted.
  ```
  scheduleIssued { pathId, planRevisionId, effectiveFrom: LivedDay, effectiveTo: LivedDay?,
                   weekPattern: [weekday → { isPlannedRest, slots: [{slotId, trackId?, pillarWeights, stretch, sessionsPerWeek?}] }] }
  ```
  It contains structure and numbers only; the prose stays in the H2 plan revision.
- **`dayPlanned`** (P): written when a lived day is dealt (background scheduler or first open, whichever comes first). It freezes that day's slots with their `d`, and the Spark:
  ```
  dayPlanned { livedDay, isPlannedRest, slots: [{ slotId, occurrenceKey, kind: path|spark, pillarWeights, d, isEdge }] }
  ```
- **Days the app never ran on** (no `dayPlanned`, which is common because background execution isn't guaranteed): the engine **materializes** S(D) deterministically from the latest `scheduleIssued` effective on D (by `effectiveFrom`, then `(recordedAt, id)`), with `d = stretch` for track slots (1.0 normally) and 1.0 otherwise. There's no Spark on undealt days. A planned rest day in the pattern is preserved, so it's never counted as absence. A day with no effective schedule is **unplanned** (S empty), which is distinct from a planned day that simply wasn't dealt.
- **Competing day contracts never retract growth** (Codex round 4, blocking #3):
  - every `dayPlanned` for D (any device) is a **contract**;
  - each device's `sparkSwapped` entries for D apply to its own contracts (matched by `deviceId`);
  - `completion(D) = max over contracts c of completion_c(D)`. Adding a contract or a swap can only raise the day's score (reference vectors V10).
- **Finalization:** D is *finalized* when `asOf ≥ B(D+1)` (the lived-day boundary instant, 17 §B.6). Today is provisional.

## B.2 Inputs per completed Action (after de-duplication and corrections, 17 §B.4, §B.7)

- `pillarWeights` (Σ = 1; any listed pillar ≥ 0.1) and `d` are copied from the slot for S actions. For non-S actions they're set at completion time.
- **Duplicates of one occurrence** (same `occurrenceKey`, rev 6): the occurrence contributes, **per pillar**, the maximum over its duplicates of `w_p × d × edge`. Adding a duplicate can never lower any pillar (vectors V12). **Accepted bound:** a duplicate with *different* weights can add credit to a pillar the original didn't favor. This only happens when the user re-logs the same occurrence with different weights, and the user can correct it (P2).
- `isEdge` = spark **or** `d ≥ 1.2`.
- Evidence is **ignored** by all growth formulas (decision 55). Growth reads P-class entries only.

## B.3 Depth (per pillar p), monotonic by construction

```
E(p,D)            = Σ_{actions a on D} w_p(a) × d(a) × (1.2 if isEdge(a) else 1.0)
f(x)              = min(x,2) + 0.5·clamp(x−2, 0, 1) + 0.25·max(x−3, 0)       // concave, non-decreasing
consistency(p,D)  = 1 + 0.5 × activeDays(p, D−27 … D−1) / 27                 // ∈ [1.0, 1.5]
dayDepth(p,D)     = f(E(p,D)) × consistency(p,D)          // under rulesVersion(D)
Depth(p)          = Σ_{D ≤ asOf.livedDay} dayDepth(p,D)
```
- **Monotonicity:** adding a positive Action increases E on its day (f is non-decreasing) and can only increase `activeDays` for later days. So **Depth never decreases when an Action is added** (vector V3). It decreases only through corrections.
- `activeDays(p, range)` = the number of lived days in the range with E(p,D) > 0.
- Rules of its time: each `dayDepth` is computed with `rulesVersion(D)` (B.1). The engine keeps every published rule set forever.

## B.4 Day completion and the growth number

```
T          = Σ_{slots s ∈ S(D)} d(s)
C_S        = Σ_{completed slots} d(s)
F          = Σ_{completed non-S actions} d(a)
completion = min(1, (C_S + min(F, 0.5·T)) / T)          if S(D) non-empty
           = min(1, F / 2.0)                              if S(D) empty (early days, no plan)
           = restGrowthCredit (RuleSet v1: 1.0)           if isPlannedRest (decision 65, by default; reversible by setting 0)
G          = Π_{finalized D} (1 + 0.01 × completion(D)) × (1 + 0.01 × completion(today))
```
- **Fill can cover at most half the day:** extra effort helps, but you can't earn a full day without your day (vector V7c).
- **completion(D) is the max over the day's contracts (B.1).** Each day's completion uses `rulesVersion(D)`. G changes only through corrections.
- **Vitality presence is separate from growth credit:** `presence(D) = 1` on a planned rest day regardless of `restGrowthCredit`.
- A correction that voids surplus effort on a full day leaves completion at 1 (vector V8b).

## B.5 Vitality (rev 6)

**Inputs:** `presence(D)` for finalized days (= completion(D); planned rest and pause = 1), plus `presence(today)` so far.

```
forgiven     = every absence day belonging to a run of ≥ 3 presence-0 days that is immediately followed
               by ≥ 3 finalized days with presence > 0 (a COMPLETED comeback). Forgiveness is permanent.
window       = the last 14 finalized calendar days, minus forgiven days; days before the Flame's birth count as 1.0
               (rev 7: the Flame is born bright, never starts in embers)
w_r          = 0.8^r / Σ 0.8^r over the included days, r = 0 (most recent included day) …
freeDay      : if any included day among the 7 most recent has presence > 0, set the lowest of those 7 to 1.0
               (ties → most recent; the tie-break is normative)
V_hist       = Σ w_r × presence_r
V_live       = V_hist + (1 − V_hist) × 0.3 × presence(today)
```

**Comeback state (from finalized days only):**
```
n_fin        = the number of trailing finalized days with presence > 0
absence      = the length of the run of presence-0 days right before them
inComeback   = absence ≥ 3  and  n_fin ≤ 3  and  (n_fin ≥ 1 or presence(today) > 0)
n_eff        = min(3, n_fin + [presence(today) > 0])
V            = max(0.15, inComeback ? max(V_live, R(n_eff)) : V_live)      R(1)=0.60, R(2)=0.80, R(3)=1.00
```

**Invariants** (each has vectors):
1. **Within a lived day, completing more never lowers V.** All day-state comes from finalized days, and today can only add (V13: a property test over 2,000 random histories).
2. **Day 4 of a comeback can't dim**, even after half-completed comeback days (V11a/b). The relight minimum holds through the day on which the third comeback day is behind you.
3. **A completed comeback forgives the absence before it, permanently.** V then reflects only how you've lived since (V9). Partial days can still show honestly **overnight**, for example 0.80 on the morning of day 5 after three half days (V11c), but never at the moment of a completion.
4. After 14+ fully absent days, V = 0.15 (the floor) for as long as the absence lasts (V6d/e).

- **"Embers"** = `V ≤ 0.25`.
- **The sensory event `comeback`** fires on the first completion of the day where `n_eff` becomes 1. It's shown **at most once per installation**, and suppressed on any device once a synced `momentWitnessed { key: "comeback:{livedDay}" }` has arrived. Two devices used offline at the same moment may each show it once; that's an accepted limitation, since eventual sync can't promise global exactly-once.
- Vitality is a function of `asOf` (16 §B.3), so it changes without new entries.

## B.6 Level and difficulty (skill tracks)

- **Skill track:** a measurable dimension with a unit and an aggregation (`perSession` or `perWeek`), defined in the catalog. Items without a track use `d = 1.0`.
- **Level L** (per track) is a projection over P events: `actionCompleted`, `feedbackGiven { occurrenceKey, rating: easy|right|hard }`, and derived **skips** (an S slot of a finalized day with no completion and no void correction).
- **L0** (seed), strictly positive:
  1. the median of HealthKit history over the last 4 weeks for the track, if permitted and > 0 (H2: the seed lives in a `levelSeeded` H2 attachment);
  2. else the Companion's estimate, clamped into the track's starting range (chapter 07);
  3. else the track default.
  Every level is clamped to `[Lmin(track) > 0, Lmax(track)]`. **After a device loss in `.phoneOnly` mode, levels are freshly re-seeded** (HealthKit or Companion), and adaptation continues from the new seed. They don't converge to the old value, and that's accepted: historical scores are unaffected because each day's `d` is frozen in P entries.
- **Transition table** (events processed in order `(livedDay, occurredAt, id)`; state per track: `L`, `streak`, `skips`, `lastEasyBumpDay`):

| Event | Effect |
|---|---|
| on-time completion (within its lived day) | `streak += 1`, `skips = 0`; if `streak == 3` → **increase**, `streak = 0` |
| feedback `easy` | if `D − lastEasyBumpDay ≥ 3` → **increase**, `lastEasyBumpDay = D`, `streak = 0` |
| feedback `right` | no change |
| feedback `hard` | **decrease**, `streak = 0` |
| skip | `skips += 1`, `streak = 0`; if `skips == 2` → **decrease**, `skips = 0` |

  - increase: `L ← L × 1.07`; decrease: `L ← L × 0.90`.
  - **At most one increase and one decrease per track per lived day. If both trigger on the same day, only the decrease applies.** Then the safety validators clamp the result (chapter 07).
- **Difficulty is fixed when the day is dealt:** `target = L_at_dealing × stretch` (stretch 1.0 for Path items, 1.25 for Sparks). For a `perWeek` track: `sessionBaseline = L_week / sessionsPerWeek`, `target = sessionBaseline × stretch`, and **`d = target / sessionBaseline`** (= stretch). For `perSession` tracks, `d = target / L_at_dealing` (= stretch). So a slot's d is normally 1.0 or 1.25. For fixed-target catalog items (e.g. "run 5 km"), `d = target / L`, clamped to [0.5, 2.0]. Adaptation after dealing never changes a dealt day.
- **The feedback prompt** is shown iff `SHA-256(occurrenceKey)` mod 5 = 0 (mod 2 during the first 14 lived days since the first entry), on the first eligible completion of the lived day only, never on a comeback completion. This is deterministic, so no randomness needs storing.

## B.7 Balance
- No balance term in any formula (decision 56). The pillar Depth vector goes to chapter 03 unchanged.
- **Companion nudge rule (for chapter 07):** a pillar with no contribution for 21+ days *and* a Depth share < 10% may be suggested at most once per 14 days, and never during an active comeback.

## B.8 Golden vectors (computed by the reference implementation; tolerance 1e-9; all pass)

| ID | Fixture | Expected |
|---|---|---|
| V1 | body, one action/day, d=1, 28 days | day-28 contribution = **1.5** |
| V2 | six body actions, d=1, one day, no history | Depth = **3.25** |
| V3a / V3b | two d=2 actions / plus an earlier d=0.5 | **2.95** / **3.075** (adding raises Depth) |
| V4 | one action d=1, weights body .5 / heart .5 | body = **0.5** |
| V5a / V5b | Spark d=1 / Path item d=1.25 | **1.2** / **1.5** |
| V6a / V6b | 30 full days / then yesterday off | **1.0** / **1.0** (free day) |
| V6c | 30 full days, then 3 days off | **0.6987509255933241** |
| V6d / V6e | 14 days off / 30 days off | **0.15** / **0.15** |
| V6f–h | after 14 off, comeback days 1, 2, 3 (today presence 1) | **0.60**, **0.80**, **1.00** |
| V7a / V7b | S = [1,1], both / one done | G = **1.01** / **1.005** |
| V7c | S = [1,1], none done, four extra d=1 | completion = **0.5** (fill cap) |
| V7d | S empty, one action d=1 | completion = **0.5** |
| V7e | 365 full days | G = **37.783434332887275** |
| V8a / V8b | void one of two S items / void surplus on a full day | completion **0.5** / **1.0** |
| V9a–c | comeback day 4 before acting / day 4 completed / day 5 | **1.0** / **1.0** / **1.0** (no dimming) |
| V9d | after a completed comeback, 3 days absent | **0.6355744157043132** |
| V10a / V10b | device A's contract completed / plus B's competing contract | **1.0** / **1.0** (never retracts) |
| V11a / V11b | 14 days off, three half comeback days; day 4 morning / day 4 completed | **1.0** / **1.0** (completion never dims) |
| V11c | …then the morning of day 5 | **0.8048780487804877** (an honest overnight dip, not on completion) |
| V12a–c | an occurrence with weights body .9/heart .1 (d=1), plus a duplicate body .1/heart .9 (d=1.1) | body **0.9** → **0.9** (not lowered); heart **0.99** |
| V14a–c | no finalized day yet / born yesterday (full) / born 2 days ago, both absent | **1.0** / **1.0** / **0.8326394031074023** |
| V13 | property: V(today=0) ≤ V(0.25) ≤ V(0.5) ≤ V(1) for 2,000 random histories | holds |

**Moved to the implementation plan (decision 60):** full entry-level fixtures (raw entries → DerivedState, including corrections, permutations, materialized days, swaps, level transition rows, prompt hash) built on this reference. The reference arithmetic stays the oracle.

## B.9 Open
- The exact visual mapping from Depth and Vitality to the Flame → chapter 03.
- Tracks, units, default levels, Lmin/Lmax and safety limits → chapter 07 (catalog).
- Other members of S(D) (e.g. the Ritual) → chapter 05.
