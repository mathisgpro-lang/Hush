# P2.6 · The big step up (plan, 2026-10-04)

*Source: Mathis: "a whole level up of the app, its fluidity, the mechanism, the fonts, everything… from the intro to the flame, the worlds, the missions… such a big step up". Status: **draft, waiting for approval.***

**The goal:** it should feel like a premium game studio made it. Every screen, motion, sound and word is deliberate, and nothing looks like a default iPhone control.

## 1. A real visual identity (fonts, color, components)
- **Two custom fonts, free (open licence):**
  - a characterful storybook serif for titles and the Book (candidates: *Fraunces* or *Cormorant*);
  - a soft, rounded font for numbers and the interface (candidates: *Nunito* or *Quicksand*).

  Downloading them needs Mathis's yes (name, source and size given first). Today the app uses the system serif.
- **A design system in code:**
  - one set of colors, sizes, spacings, corners and shadows used everywhere;
  - painted panels (parchment, ember-glass, night-glass) replacing today's flat dark cards;
  - one button family: primary gold, secondary outline, quiet text.
- **A painted UI kit from Codex** (panel frames, button plates, badges, dividers, the three bar icons), so buttons and panels feel made from the world's materials.
- **Iconography:** painted icons replace every system symbol that shows (pillars, Keepers, streak, shield, quests).

## 2. Motion: one language, everywhere
- **Motion tokens:** every movement uses a few named springs and durations (tap, sheet, screen, celebration). No default fades.
- **Choreography:** elements arrive one after another (title, then line, then cards), each with a small delay.
- **Shared-element transitions:**
  - a quest object flies from the world into its card, and back;
  - the satchel opens from its icon;
  - the map dive starts from the realm you tapped.
- **The reward moment as a full sequence:**
  1. the object bursts into sparks;
  2. light flies to the Spark;
  3. the Spark reacts (a hop, a glow);
  4. +XP counts up;
  5. the streak flame flares;
  6. the attribute climbs.

  It takes about two seconds, with sound and haptics in sync.
- **Idle life on every screen**, sheets included: drifting embers, a breathing glow.

## 3. Sound and haptics
- **A sound palette from free libraries** (asking before any download): soft taps, page turns, the satchel, the streak flame, the level-up chime, an ambience per world (sea, forest, lake, wind, library, forge).
- **Haptic patterns paired with each sound** (Core Haptics), so the reward is felt as well as seen.
- **Mute and volume in settings.**

## 4. The Flame
- **A properly animated Spark** (Codex parts: body, face pieces, flame tip):
  - eyes that blink and follow your finger;
  - mouth shapes, happy and sleepy states;
  - squash and stretch when it reacts.
- **Expressions tied to what you do:**
  - joy when you complete a quest;
  - pride at a milestone;
  - calm at night;
  - a little worry when your streak is at risk (gentle, never guilt).
- **Tap and hold on the Spark:** it reacts, and a line from it appears.

## 5. The worlds
- **Keepers come alive:** Codex paints each Keeper (Nim and Ro, Ilo, Brakka, Quill, Mossbeard, Orrin) as an animated character placed in its realm. Tap one and it speaks.
- **Restoration you can see:**
  - lights relight with a flare and a sound;
  - each realm has three visible wake stages (Hushed, Waking, Radiant), with more color, life and creatures as it wakes.
- **Weather and ambience per realm** (rain in the Grove, wind in the Highlands, mist on the Stillwater), all in code.

## 6. Missions (quests)
- **A quest object animates in the world:** it glows brighter as you make progress, then bursts when done.
- **Progress made tactile:**
  - hold to count reps or minutes;
  - a timer for timed quests (the Focus timer and meditation built in, Life Reset-style);
  - pages counted with a swipe.
- **The journal:**
  - a painted cover;
  - each realm's quests in its own color;
  - smooth tabs with a sliding underline.

## 7. The introduction
- **Rebuilt with the new identity:** typography, painted panels, motion choreography, sound from the first frame.
- **A cinematic opening:**
  1. a slow camera move over the hushed Sanctuary;
  2. the title appears;
  3. the ember waits.
- **Questions as beautiful cards**, with the Spark reacting to each answer.
- **A personal assessment at the end** ("your strengths, where to start"), as a painted card.

## 8. Quality bar (non-negotiable)
- 60 fps everywhere, including during sheets and transitions, measured on the iPhone.
- Every touch answers within one frame.
- No default iOS look left on screen.
- **Codex reviews the whole app** against this plan before it goes to Mathis.

## Order
1. Identity (fonts, design system, UI kit).
2. Motion tokens and the reward sequence.
3. Sound and haptics.
4. Missions.
5. The Flame.
6. The worlds and Keepers.
7. The introduction last, since it uses everything above.

Codex's art (the UI kit, the Keepers, the Spark parts) is queued at the start, so it's ready when each step needs it.
