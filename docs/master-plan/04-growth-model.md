# 04 — The Growth Model

**Status:** Part A ✅ approved 2026-09-30 (decision 56) · Part B 🔎 in Codex review · **Last updated:** 2026-09-30
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

**1. Improving the formulas can never lower your Flame.** Over the years we'll improve how Depth is calculated. When we do, if the new formula would give you *less* Depth than you had, you keep what you had and grow from there. Nobody ever opens the app to find their Flame shrank because of our changes. **Correcting your own mistakes, though, is honest:** if you remove something logged by mistake, its Depth goes with it.

**2. Balance is shown, never forced.** There's no penalty and no bonus for balance across pillars. Your Flame's shape simply *shows* it (chapter 03): a deep Body and young Heart look different from the reverse. The Companion may gently suggest a neglected pillar now and then. It never nags, and a specialist's Flame is just as beautiful.

## A.8 What the numbers look like in practice (starting values, tuned after testing)

| Situation | Result |
|---|---|
| You do your full day, every day, for a week | Growth number ×1.07; Vitality full; Depth grows in the pillars you worked |
| You skip one day | Vitality unchanged (the free day); growth +0% that day |
| You're away 3 days | Vitality visibly dimmer |
| You're away 2 weeks | Embers |
| You come back | The comeback moment; full brightness again after about 3 days of showing up |
| You do 6 workouts in one day | The first two count fully, then less and less. Showing up tomorrow is worth more. |

All the numbers in Part B are **starting values**. We'll tune them by feel during the private beta, and every change is versioned so nobody's history is affected unfairly (rule 1).

---

# Part B — For the builders

All functions live in `Domain.GrowthEngine`. They're pure and deterministic (16 §B.3). Parameter values are **rule-set constants** (`RuleSet v1`); changing any value bumps `rulesVersion`. Every formula below must have golden vectors.

## B.1 Inputs per completed Action (after de-duplication and corrections, 17 §B.4, §B.7)

- `pillarWeights: {Pillar: w}` with Σw = 1 (from the catalog/plan item; the Companion may propose, a validator enforces Σ=1, w ≥ 0.1 for any listed pillar).
- `d`: calibrated difficulty = `target / level` for the item's skill track (B.5), clamped to [0.5, 2.0]. For items without a skill track (e.g. "call a friend"), `d = 1.0`.
- `isEdge`: true if it's a Spark, or `d ≥ 1.2`.
- Evidence level is **ignored** by all growth formulas (decision 55).

## B.2 Depth (per pillar p)

For each lived day D and pillar p, order the day's contributing Actions by `(occurredAt, id)` and let k be the Action's index within (D, p), starting at 1.

```
repeatFactor(k)   = 1.0 if k ≤ 2;  0.5 if k = 3;  0.25 if k ≥ 4
consistency(p, D) = 1 + 0.5 × activeDays(p, D−27 … D−1) / 27          // ∈ [1.0, 1.5]
edgeBonus         = 1.2 if isEdge else 1.0
contribution      = w_p × d × repeatFactor(k) × consistency(p, D) × edgeBonus
Depth_computed(p) = Σ contributions over all lived days ≤ asOf.livedDay
```
`activeDays(p, range)` = the number of lived days in the range with at least one contribution to p.

**Formula-change floor (Part A §A.7, rule 1, decision 56):**
- When `rulesVersion` changes, compute under old and new rules at the change instant.
- For each pillar, `legacyOffset(p) = max(0, Depth_old(p) − Depth_new(p))`. Write a `depthAcknowledged` entry carrying the offsets and the new `rulesVersion`.
- `Depth_displayed(p) = Depth_computed_new(p) + legacyOffset(p)`. Offsets accumulate across successive rule changes.
- Corrections change `Depth_computed` normally; offsets are constants. So corrections lower Depth honestly, and formula changes never do.

## B.3 Vitality

```
presence(D)  = 1.0                      if D is a planned rest day in an active plan
             = min(1, completion(D))    otherwise                    // completion from B.4
window       = the 14 lived days ending at asOf.livedDay (today counts as its current partial value)
weights      = w_i = 0.8^i / Σ_{j=0..13} 0.8^j   for i = 0 (today) … 13
freeDay      = in the window, set the lowest presence(D) among days i = 1…13 to 1.0 (one free day)
V_raw        = Σ w_i × presence_i
V            = max(0.15, V_relight)                                   // 0.15 = absolute floor; V ≤ 0.20 is the "embers" state
```

**Relight (comeback):** if the most recent completed Action was preceded by ≥ 3 consecutive lived days with presence 0 (not counting planned rest), a comeback starts on that day C:
```
V_relight = max(V_raw, relightCurve(n))   where n = days since C with presence > 0, counting C as 1
relightCurve(1) = 0.60,  (2) = 0.80,  (≥3) = 1.00
```
The comeback ends (and plain `V_raw` applies) once `V_raw ≥ relightCurve(n)` or presence is 0 again.
- **Comeback event:** the first Action on day C emits the sensory event `comeback` (chapter 06) instead of the standard completion event.
- Vitality is a function of `asOf` (16 §B.3), so it decays without new entries.

## B.4 Day completion and the growth number

- **The day's set S(D)** = the Path items scheduled for D + the Spark dealt for D (after a swap, the replacement). Chapter 05 may extend S. Rituals and free Actions aren't in S but can fill it (below).
- `completion(D) = min(1, (Σ_{a ∈ S(D) completed} d_a + fill(D)) / Σ_{a ∈ S(D)} d_a)`
- `fill(D)` = Σ `d` of completed non-S Actions that day × 0.5. Extra effort can fill gaps, but at half value, so it can't replace your day.
- If `S(D)` is empty (no plan yet, early days), `completion(D) = min(1, Σ d of completed Actions / 2.0)`.
```
G(D)  = G(D−1) × (1 + 0.01 × completion(D))          G before the first day = 1.00
```
- Days with no activity: completion 0, so G is unchanged. G only decreases through corrections (it's recomputed from the record).
- Display (proposed): `×1.00` with two decimals up to ×100, then whole numbers. The name is TBD (chapter 12).

## B.5 Level and difficulty (skill tracks)

- A **skill track** is a measurable dimension of an item family (e.g. `running.weeklyVolume`, `reading.minutesPerSession`, `strength.sessionLoad`). The catalog defines tracks and units. Items without a track use `d = 1.0`.
- **Initial level L0:** the median of the last 4 weeks of HealthKit history for that track if permitted and available; else the Companion's estimate from the birth conversation, validated into the track's "starting range" table (chapter 07); else the track's default beginner value.
- **Adaptation per track** (evaluated on each completion or skip):
  - 3 consecutive on-time completions with feedback ≠ "too hard" → `L ← L × 1.07`.
  - Feedback "too easy" → `L ← L × 1.07` (at most once per 3 days).
  - 2 consecutive skips of track items, or feedback "too hard" → `L ← L × 0.90`.
  - Clamp each change by the safety validators (e.g. running volume increase ≤ the limit defined in chapter 07).
- **Targets:** plan items get `target = L × stretch`, where stretch is 1.0 for normal items and 1.2–1.3 for Sparks.
- **The feedback prompt** appears at most once per lived day, on ~1 in 5 track completions (1 in 2 during the first 14 days). Never on the comeback Action.
- Levels are local P-class state (stored as `levelUpdated` working data, synced), never H1. A level *derived from HealthKit* is H2 (16 §B.5).

## B.6 Balance
- No balance term in any formula (Part A §A.7, rule 2, decision 56). The pillar Depth vector goes to chapter 03 unchanged.
- **Companion nudge rule (for chapter 07):** a pillar with no contribution for 21+ days *and* a Depth share < 10% may be suggested at most once per 14 days, and never during a comeback.

## B.7 Golden vectors required (minimum set)
1. A single pillar, one Action per day for 30 days: consistency ramps to 1.5.
2. Six Actions in one pillar on one day: repeatFactor sequence 1, 1, 0.5, 0.25, 0.25, 0.25.
3. A multi-pillar Action with weights 0.5/0.5.
4. The edge bonus on a Spark versus `d = 1.25`.
5. Vitality: 1 day off (free day) → V = 1.0; 3 days off → ≈0.66; 14 days off → ≈0.17 (embers); 30 days off → 0.15; a comeback sequence (days 1, 2, 3 → 0.60, 0.80, 1.00).
6. A planned rest day inside a streak.
7. Growth: a full day, a partial day, the fill cap, the empty-S rule, 365 full days → 37.78 (±0.01).
8. A correction voiding an Action lowers Depth and G.
9. A rules change with a lower new formula → offsets keep the displayed value; a later correction still lowers it.
10. The same entry set in shuffled order gives an identical DerivedState.

## B.8 Open
- The exact visual mapping from Depth and Vitality to the Flame → chapter 03.
- Tracks, units, default levels and safety limits → chapter 07 (catalog).
- What else belongs in the day's set S (e.g. Ritual) → chapter 05.
