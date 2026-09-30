# 03 — The Flame

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-09-30
**Based on:** decisions 7, 10–12, 35–36, 40, 51–53, 58, 61, 64 · **Draws from:** chapter 04 (every visual property below is a picture of a number calculated there) · **Art direction:** `docs/design/flame-concepts/`, `docs/design/flame-pillars/`

Items marked **[by default]** were decided under decision 63 and are listed for review in the index.

---

> **Revision note (2026-10-01):** the look is now **pixel art** (decision 77); the realistic concept art is mood reference only. The Flame will later become a **personified companion** with eyes and a mouth that moves around (decision 76), likely merging with chapter 07. The live app renders the Flame in `PixelFlameView` (pixel-fire simulation plus a pixel vessel).


# Part A — For Mathis

## A.1 What the Flame is *[Settled, 61, 64]*

Your soul, made visible: **a living fire held in a crafted vessel.**

| Layer | What it shows | Time | Driven by (chapter 04) |
|---|---|---|---|
| **The fire** (inside) | How you've been living **lately** | Recent weeks | Vitality + which pillars you've been feeding |
| **The vessel** (outside) | Who you've **become** | Permanent | Depth per pillar + your Transformation stage |

## A.2 The fire: how you're living now

- **Brightness and movement = Vitality.**
  - At full Vitality it burns bright and lively.
  - As Vitality falls, it calms and dims.
  - In **embers** it's a low, glowing core. It never goes out.
- **Color = what you've been living lately.** The fire blends the colors of the pillars you've fed over roughly the last four weeks:
  - a month of training and study burns **ember and blue**;
  - a month of family and helping others glows **rose-gold and green**;
  - a balanced life burns with a many-colored **golden heart**.
- **The comeback** (decision 52): the embers catch, flare, and the fire roars back up, with its own sound and haptic. It's one of the app's signature moments.

## A.3 The vessel: who you've become

- **Each pillar weaves its motif into the vessel as it deepens** *[Settled, 64]*:

| Pillar | Motif in the vessel | Fire color |
|---|---|---|
| Body | Ember veins running through the material | Ember orange |
| Mind | A blue crystal lattice | Clear blue |
| Heart | A warm rose-gold inner glow | Rose-gold |
| Spirit | Filaments of white light | White-silver |
| Craft | Engraved geometric patterns | Bronze-gold |
| World | Living green vines | Living green |

- **It grows more intricate every single day you act** *[by default]*. This is how the app makes "invisible progress visible today" (decision 14):
  - each completed Action sends a **spark from the fire into the vessel**;
  - that spark visibly extends a vein, a vine or an engraving line.
  - The change is small but *visible* the same moment. Over months, those small additions become rich, unmistakable detail.
- **No two vessels are alike** *[by default]*. At your Flame's birth, it receives its own unique "seed," which shapes its exact silhouette, where its motifs grow, and how its patterns branch. Two people with identical histories would still have different Flames, the way no two trees are the same.

## A.4 Transformations: the journey of the material *[Settled, 61; thresholds by default]*

The vessel's **material** changes only at big milestones (decision 10). When it does, **the whole app transforms with it**: colors, light, textures, sound palette and haptics (decision 35).

| Stage | Material | Feeling | Reached when *(starting values, by default)* |
|---|---|---|---|
| 1 | **Carved desert stone** | The beginning. Raw, ancient, full of promise. | At birth |
| 2 | **Forged metal** | You've proven you'll show up. | About **6 weeks** of real showing up (30+ active days and enough Depth) |
| 3 | **Crystal** | Clarity: your growth shines through. | About **6 months** (150+ active days) |
| 4 | **Pure light, with orbiting rings** | Rare. You carry something from the future. | About **2 years** (500+ active days) |
| 5+ | *Unknown* | Beyond Light, stages that no one has reached yet. Designed with chapter 28 (the Adventure). | Years and decades |

- **Why "active days" and not just Depth:** a Transformation should mean time *lived*, not a burst of effort. Nobody can binge their way to Crystal.
- **You always see a veiled silhouette of your next stage** *[by default]*: a shape in the mist, never the whole thing. You never see the whole map (P16). What comes after Light isn't shown to anyone until someone gets there.
- **A Transformation is never taken back** (decision 58 and chapter 16's grant rule). Once your vessel is metal, it's metal forever, even after a year away. Vitality handles the "how are you doing lately" part.
- **The Transformation moment** is a ceremony, not a notification. The fire flares, the old material cracks and falls away like a shell, the new one is revealed, and the app's whole world shifts around it. You'll remember it. (Chapter 06 designs the sensory detail.)

## A.5 Both layers can change: earned variations *[Settled, 61; details in chapter 10]*

Beyond the material journey, both the fire and the vessel can take **earned variations**: special fire styles and vessel forms, won through Rituals, seasons and rare challenges, and showable forever (like the Fortnite skin from 2015).
- They're **always earned, never bought** (P7).
- They change the *style* of your Flame, never its truth. Your Depth, motifs and Vitality always show through.
- **MVP** *[by default]*: the system supports variations from day one (theme engine hook), and the private beta includes **one** earnable fire style, from the first Ritual, to test the feeling. The full catalog is chapter 10.

## A.6 Where the Flame lives and how you touch it *[by default]*

- **It's the center of the home screen**, always. Your day (chapter 05) gathers around it.
- **Touch it:** it responds with a warm haptic pulse, like a heartbeat, and the fire leans toward your finger.
- **Press and hold:** your story unfolds. The vessel slowly turns, and each motif can be tapped to see what built it ("Body: 142 runs, since March").
- **Accessibility:** with Reduce Motion on, the Flame stays alive with gentle light changes instead of motion. VoiceOver describes it in words, for example: "Your Flame: a forged-metal vessel rich with ember veins and blue lattice; the fire burns bright, lately rose-gold and green."

## A.7 What the MVP needs from the artist (or Codex + artist) *[by default]*

- Full art for **Stone** and **Metal** (the stages reachable in the beta).
- **Crystal** and **Light** as veiled silhouettes only (shown as "what's ahead").
- The six pillar motifs, and the fire's six color identities.
- The spark-to-vessel animation, the comeback, and the Stone → Metal Transformation.

---

# Part B — For the builders

## B.1 Inputs (from `Domain.GrowthEngine.DerivedState`, chapter 04)

```
FlameInputs {
  depth:       [Pillar: Double]      // chapter 04 §B.3
  vitality:    Double                 // [0.15, 1], chapter 04 §B.5
  recentMix:   [Pillar: Double]      // share of E(p,D) over the last 28 lived days, normalized to Σ = 1; all-zero → nil
  activeDays:  Int                    // lived days with any completion, all time
  stage:       Int                    // max owned transformation entitlement (B.4)
  variations:  { fireStyle: ID?, vesselForm: ID? }   // owned and selected (chapter 10)
  seed:        UInt128                // from the `flameBorn` entry (P), chapter 08
  comebackN:   Int?                   // 1…3 while a comeback is active (chapter 04 §B.5)
}
```

## B.2 Mapping to render parameters (`Experience.Flame`), RuleSet v1

```
totalDepth      = Σ_p depth[p]
intricacy       = ln(1 + totalDepth / 10)                         // grows forever, decelerating; each Action visibly adds
motifStrength_p = sqrt(depth[p] / max_q depth[q])  if depth[p] ≥ 1.0 else 0     // perceptual scaling; relative within one Flame
fireBrightness  = vitality
fireActivity    = 0.3 + 0.7 × vitality
embers          = vitality ≤ 0.25
fireColor       = Σ_p recentMix[p] × palette[p]     (in linear color space); nil mix → neutral gold
```
- **Per-Action visible increment:** on each `actionCompleted`, the renderer plays a `sparkToVessel` animation toward the motif of the Action's dominant pillar, then renders at the new parameters. The difference must be perceptible (a minimum visual delta per completion is set by the artist's motif growth masks, see B.5).
- **Determinism:** the same `FlameInputs` produce the same frame on every device. Seeded noise only (seeded from `seed`); no wall-clock randomness in shape. Time drives *animation phase* only.

## B.3 Theme coupling (decision 35)
- `ThemeState = themeFor(stage, variations.vesselForm) ⊕ accents(fireColor, vitality)`.
- Stage selects the base token set: background materials, typography weight/texture, sound palette, haptic pattern set.
- The fire adds live accent color and accent intensity, scaled by vitality.
- **All screens read tokens only** (chapter 16 §B.2, rule 2).

## B.4 Transformations (MVP rule set v1, decision 58: rules of their time)

| Entitlement key | Condition (all must hold) |
|---|---|
| `milestone:stage-2` | `activeDays ≥ 30` and `totalDepth ≥ 60` |
| `milestone:stage-3` | owns stage 2, `activeDays ≥ 150` and `totalDepth ≥ 400` |
| `milestone:stage-4` | owns stage 3, `activeDays ≥ 500` and `totalDepth ≥ 1500` |

- These are evaluated by `GrantService` (chapter 16 §B.3). The displayed stage = the max owned. Never revoked.
- The thresholds are rule-set constants. **Tuning during the beta** changes them for future grants only.
- **Sanity check** (to add as a golden vector in the implementation plan, computed with `reference/growth_reference_v1.py`): a user with 2 pillar-actions per day at d = 1 every day reaches stage 2 at day 30 (the active-days bound binds first, since Depth reaches 60 around day 20). Record the computed day in the plan.
- **The Transformation ceremony** plays once per device per entitlement, acknowledged via `milestoneWitnessed` (chapter 16 §B.3).

## B.5 Asset structure (for the art pipeline)
- Per stage: a base vessel mesh or silhouette set (variants selected by `seed`), a material texture set (albedo, normal, emissive), and a crack/reveal mask for the Transformation.
- Per pillar: a motif growth mask (a 0→1 progression field, so `motifStrength` reveals the motif progressively along paths), plus its emissive color.
- The fire: layered noise textures and flow maps, the six palette colors, and an embers-state texture.
- Veiled silhouettes for stages 3–4 in the MVP.
- Source files go in `assets/flame/`, with Codex-generated concept references in `docs/design/`.

## B.6 Performance and accessibility
- Target 60 fps (120 on ProMotion), with rendering paused when not visible. The Flame view's GPU budget is defined in chapter 21. Thermal state `serious` or worse → reduced particle count.
- **Reduce Motion:** static geometry, light-only animation. **VoiceOver:** a generated description from `FlameInputs` (template-based, never an AI call).

## B.7 Open
- Stages 5+ and the lore of the vessel → chapter 28.
- Variation catalog → chapter 10 (the MVP ships one earnable fire style).
- Exact sensory design of the spark, comeback and Transformation → chapter 06.
- The birth of the Flame (`flameBorn`, seed) → chapter 08.
