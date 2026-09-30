# 28 — The Adventure (MVP slice)

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-09-30
**Based on:** decisions 40, 47, 61, 64 and principles P15–P16 · **Scope:** the full vision in intent, the MVP slice in detail

---

# Part A — For Mathis

## A.1 The promise *[Settled, 40]*

From the first second, it feels like **the start of an adventure**: a breath of fresh air, the birth of something new, the sense that everything is possible. And the game has **real depth, like a real game**: systems that interlock, things to discover, mastery, mystery, meaningful choices.

## A.2 The world: the Sanctuary *[by default]*

Your Flame doesn't float in an empty screen. It lives in **your Sanctuary**: an ancient, half-ruined place of sandstone arches and monumental stone (Dune), reclaimed by water and green life (the nature sanctuary), with faint traces of advanced technology woven into the ruins (Iron Man). Your Flame rests at its heart.

- **The Sanctuary is the home screen's world.** It changes with your Transformations: the Stone era is dusk among raw ruins; the Metal era brings forged braziers and restored stonework; Crystal brings clear water and light through the arches; the Light era is luminous, with the architecture of the future.
- **Its atmosphere breathes with your Vitality:** bright and alive when you're living fully, calm and dusky when you're away, never dark and never ruined by your absence.
- **The words are sparse and mythic, never cheesy.** No wizards, no cartoon mascots. Think of the tone of a great film trailer, not a children's game.

## A.3 The myth, in one paragraph *[by default]*

> Every person carries a flame. Most never see it. Here, yours is given a vessel: raw stone at first, carved by nothing but what you do. Each act of courage, care, effort and discovery shapes it. It will never be finished. It will never go out.

This paragraph is the seed of all the app's language. It's used once at the birth (chapter 08) and echoed in small ways afterward.

## A.4 Why it's a real game: the systems that interlock

Depth in games comes from systems feeding each other, not from a pile of features. Here's how ours connect:

| System | What it gives you | Feeds into |
|---|---|---|
| **Paths** (quests) | Long arcs with a plan, like campaigns | Daily Actions → Depth → vessel motifs |
| **The Spark** (daily adventure) | A surprise challenge at your edge | Edge bonus → faster Depth; unlocks Hidden Sparks |
| **The Ritual** (shared) | The same challenge as everyone, the same week | Belonging; time-stamped rewards |
| **The Flame** (the character) | Visible growth: fire and vessel | Transformations → a new Sanctuary era |
| **Transformations** (eras) | Rare, unforgettable milestones | The entire app's world changes |
| **Discovery** (below) | Things hidden until you've grown enough | New challenges, new horizons |
| **Rewards** | Earned fire styles, vessel forms, titles | Identity; "I was there in 2026" |

## A.5 Discovery: you never see the whole map *[by default]*

1. **The veiled next stage.** Your next Transformation is a silhouette in the mist, and nothing beyond Light is shown to anyone until someone reaches it (chapter 03).
2. **Hidden Sparks.** Rare challenges that only appear once a pillar is deep enough. They're never listed and never announced in advance: the first time one appears, it simply arrives. For example, a deep Spirit may one day be offered *"Watch the sunrise in complete silence."* **MVP: six Hidden Sparks, one per pillar.**
3. **Sanctuary secrets** (post-MVP). Small details in your Sanctuary that appear only after certain feats. Someone may notice a new carving and wonder what it means.

## A.6 The Chronicle: your story, told back to you *[by default]*

Once a week, your Companion writes **a short chapter of your story**, a few lines in the app's mythic voice:

> *Week 40. The embers held through a hard Tuesday. Three dawns on the road; a long call home. Mind grew quiet and sharp. Your vessel carries a new line of blue.*

The Chronicles build up into a book of your life that you can look back on in ten years. It's written on your phone (on-device AI, or from templates if unavailable), stays private, and is H2-class (words).

## A.7 MVP slice vs. later *[by default]*

| In the MVP | Later |
|---|---|
| The Sanctuary for the Stone and Metal eras (Crystal and Light as glimpses) | Full Crystal, Light and 5+ eras |
| The myth paragraph and the voice | A full lore codex that unlocks over time |
| The veiled next stage | Seasons (yearly arcs with their own story) |
| Six Hidden Sparks | Many more Hidden Sparks and Sanctuary secrets |
| The first Ritual and its earned fire style | Global Ritual events and world-changing community milestones |
| The weekly Chronicle | The Chronicle book (year-end, shareable excerpts) |

## A.8 Design work (Codex, decision 62)

Codex produces concept art for the Sanctuary in the Stone and Metal eras, plus the dusky (low Vitality) and bright (full Vitality) atmospheres, using `docs/design/flame-concepts/` as the style reference.

---

# Part B — For the builders

## B.1 Content catalog (chapter 16 §B.10), MVP schema v1

```
Catalog {
  version, signedAt, signature,
  ruleSetEffectiveFrom: [{ livedDay, rulesVersion }],              // chapter 04 §B.1
  sourceRegistry: [ Source ],                                       // chapter 16 §B.4
  tracks: [ { trackId, unit, aggregation: perSession|perWeek, Lmin, Lmax, default, startingRange } ],  // chapter 07
  sparks: [ { sparkId, pillar, text, trackId?, stretch, safetyTags[] } ],
  hiddenSparks: [ { sparkId, pillar, text, unlock: { pillar, minDepth }, oncePerUser: true } ],
  rituals: [ { ritualId, window: "YYYY-Www", pillar, text, rewardId? } ],
  rewards: [ { rewardId, tier: collectible, kind: fireStyle|vesselForm|title, assetRef } ],
  milestones: [ { entitlementKey, stage, condition } ],             // chapter 03 §B.4 (display copy; logic lives in RuleSet)
  sanctuary: [ { stage, assetRefs, atmosphereCurves } ],
  voice: { mythParagraph, chronicleTemplates[] }
}
```
- Growth logic never depends on catalog *text*. Conditions in `hiddenSparks.unlock` are evaluated by `Domain` against DerivedState.
- **Hidden Spark selection:** when dealing a lived day's Spark, if any unlocked, not-yet-dealt Hidden Spark exists for the user, it's chosen with probability 1/7 per day (deterministic: `SHA-256(seed ‖ livedDay) mod 7 == 0`). Otherwise a regular Spark is dealt (chapter 05).

## B.2 The Sanctuary rendering
- A layered 2.5D scene per stage (background, midground ruins, foreground growth), with parallax driven by device motion (disabled under Reduce Motion). The Flame is composited at its center.
- Atmosphere parameters (light level, fog, color temperature) are interpolated from `vitality`. **Minimum light at V = 0.15 is still readable and calm, never dark.**
- All values are tokens from `Theme` (decision 35).

## B.3 The Chronicle
- Generated weekly at the first app open after the lived week ends (Monday boundary). Input: DerivedState deltas for the week plus counts per pillar (P data only; **no H2 text as input** in the MVP).
- Tier 1 (on-device) with a strict length limit. Fallback: `voice.chronicleTemplates` filled with the numbers.
- Stored as an H2 attachment on a P `chronicleWritten { weekId }` entry.
- Must pass the same safety validator family (no medical claims, no shaming language).

## B.4 Open
- Seasons, the lore codex, Sanctuary secrets, stages 5+ → post-MVP (full chapter 28).
- Ritual reward assets → chapter 10 (MVP: one fire style).
