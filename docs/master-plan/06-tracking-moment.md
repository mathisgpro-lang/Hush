# 06 — The Tracking Moment

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-10-01
**Based on:** decisions 14, 35, 52, 61, 64 and principle P13 · **Will be tuned by:** the feel prototype on Mathis's iPhone

> This chapter describes a *feeling*. Every number in it is a starting point, and the feel prototype exists to replace these numbers with ones that feel right in the hand.


> **Plan 2.0 update (2026-10-01, decisions 84–92). This block wins over anything below that conflicts with it.** Same hold-to-strike and haptic language. Added (Plan 2.0 Part 1 §6): your Flame **catches the light** and **carries it to the realm**, where it lands as restoration. The full rewrite happens in the P3 build plan.

---

# Part A — For Mathis

## A.1 The goal *[Settled, 14]*

**Checking something off and getting the reward are the same moment**, and it has to be the part people love. It must be:
- **instant:** it reacts in the same frame as your touch, never waiting for anything;
- **short:** about a second and a half, so it never slows your life;
- **felt:** through touch, sound, light and motion together;
- **true:** what you see actually happened to your Flame (P3, honest numbers).

## A.2 The moment, beat by beat *[by default]*

| Time | You feel | You hear | You see |
|---|---|---|---|
| **0 ms: touch** | A firm, soft "press" haptic, like pushing a real button | — | The Action card compresses slightly under your finger |
| **Hold ~250 ms** | A rising haptic hum, gathering energy | A low swell | Light gathers from the fire toward your finger |
| **Release: ignition** | A single crisp "strike" | A clean strike (flint on stone, as the core of the sound) | The card flares and turns into a spark |
| **0.2–0.9 s: the flight** | A light, fading texture | A soft whoosh | The spark arcs from the card into the fire, then from the fire into the vessel, colored by the Action's pillar |
| **~1.0 s: the landing** | A warm, deep "thrum", like a heartbeat | A resonant tone in that pillar's key | The vein, lattice, vine or engraving in the vessel visibly extends |
| **~1.2–1.5 s: settle** | — | A soft tail | The fire briefly brightens, and the day's growth ticks up (e.g. **+0.34%**) |

**Why press-and-hold** *[by default]*: a quarter-second hold makes it a deliberate act, not a careless tap. You *mean* it. It also prevents accidental check-offs. A single normal tap works too, so it's never an obstacle, but it gets the lighter version of the moment.

## A.3 Every pillar has its own voice *[by default]*

The six pillars each have a sound family and a haptic texture, so over time your hands and ears *know* what you just did:

| Pillar | Sound character | Haptic texture |
|---|---|---|
| Body | Deep drum, ember crackle | Strong, grounded pulse |
| Mind | Clear glass chime | Precise, crisp tick |
| Heart | Warm low string | Soft, rounded double beat (like a heartbeat) |
| Spirit | Airy bell, breath | Long, gentle swell |
| Craft | Struck metal, anvil | Two sharp taps, like a hammer |
| World | Wood and water, a bird-like note | A light ripple |

## A.4 The special moments *[by default]*

| Moment | What makes it different |
|---|---|
| **Completing the Spark** | A bigger flare. The spark leaves a brief trail of light across the Sanctuary. You pushed your edge, and the app celebrates it. |
| **Your last Action of the day ("full day")** | After the landing, the fire flares once and a quiet chord resolves. "Day complete. +1%." |
| **The comeback** | The embers catch, flare and roar back up, with a rising haptic crescendo. The one moment that's deliberately *big*. |
| **A Hidden Spark appears** | Morning: a faint shimmer in the Sanctuary, and the Spark card arrives veiled, revealing itself as you touch it. |
| **A Transformation** | The ceremony (chapter 03): the vessel cracks and falls away like a shell, the new material is revealed, and the Sanctuary's era shifts around it. About 8 seconds, once in a long while. |

## A.5 Restraint rules *[by default]*

- **Most moments stay short.** Only the comeback and Transformations are allowed to be long, so they stay special.
- **Nothing blocks you.** You can keep scrolling or leave the app mid-animation; the moment finishes on its own and the result is already saved.
- **Respect the settings:** with the phone on silent, there's no sound, but haptics still play. With Reduce Motion on, light replaces motion. You can turn sound and haptics off in settings.
- **Never cheap:** no confetti, no cartoon stars, no slot-machine effects. The feeling is closer to lighting a real flame than to winning a casino game.

## A.6 Undo *[by default]*

For 5 seconds after completing, a quiet "Undo" appears. After that, mistakes are fixed with "This didn't happen" from the Action (a correction in the record, chapter 17). That's always possible, with no drama.

---

# Part B — For the builders

## B.1 Timing contract
- **Input → first visual and haptic response:** ≤ 1 frame (16 ms at 60 Hz, 8 ms at 120 Hz). The haptic engine is pre-warmed while the Today screen is visible.
- **The record write** (`RecordStore.complete`) happens at release, synchronously on a background actor with the UI optimistic. **It must commit before the landing beat (≤ 900 ms).** If it fails, the animation reverses gracefully and a non-blocking retry appears (this should never happen offline, since writes are local).
- **No network calls anywhere in this path** (chapter 16 §B.8 test).

## B.2 Sensory events (from `Experience.Sensory`, decision 35)

```
SensoryEvent = press | chargeTick(progress) | ignite(pillar) | flight(pillar) | land(pillar)
             | settle(deltaGrowth) | sparkComplete | dayComplete | comeback | hiddenSparkReveal
             | transformation(stage)
```
- Each event maps to theme tokens: a haptic pattern (Core Haptics AHAP, in the theme bundle per stage), a sound asset (per stage and per pillar), and motion curves.
- **Stage changes the palette:** the Stone era's sounds are rawer (stone, wood); the Metal era's are brighter (metal, resonance). This is part of a Transformation "changing the whole app."
- Event → token mapping lives in `Theme`; no feature code references an asset directly (the chapter 16 lint rule).

## B.3 Starting values (tuned by the feel prototype)

| Parameter | Start |
|---|---|
| Hold to charge | 250 ms (a tap under 250 ms = the light variant) |
| Flight duration | 700 ms, ease-out-back, arc height 18% of screen |
| Landing thrum | Core Haptics continuous, intensity 0.8 → 0, sharpness 0.3, 180 ms |
| Strike | transient, intensity 1.0, sharpness 0.9 |
| Undo window | 5 s |
| Sound level | −14 LUFS integrated, per-pillar sounds matched to within ±1 LU |

## B.4 Accessibility
- VoiceOver: "Complete: Morning run" → a single activation (no hold needed). The announcement: "Done. Body grew. Today plus 0.3 percent."
- Reduce Motion: no flight arc; a light pulse travels instead. Haptics unchanged.
- The system haptics setting off → no custom haptics; the app never overrides user settings.

## B.5 Feel prototype scope (a throwaway spike, chapter 22 §A.1)
The prototype must answer, on Mathis's iPhone:
1. Does press-and-hold feel deliberate or annoying?
2. Are the pillar voices distinguishable after one day?
3. Is the landing thrum satisfying without being tiring after 5 completions?
4. Is the comeback big enough?

Output: tuned values for B.3 and a yes/no on each question, logged in the decisions log.
