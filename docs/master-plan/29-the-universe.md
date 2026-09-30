# 29 — The Universe: your Flame, the world, the lore

**Status:** 📝 Drafted with default decisions (63), for Mathis's review · **Last updated:** 2026-10-01
**Based on:** decisions 40, 64, 71, 76, 79–81 · **Supersedes where they conflict:** the vessel-centered Flame of chapter 03, and chapter 28's Sanctuary-only world
**Importance:** this is **the heart of what the project is**, the creation of a universe (Mathis, 2026-10-01). Every other system (growth, the day, the Companion, rewards, community) feeds into it.

---

# Part A — For Mathis

## A.1 The idea in one paragraph

Inside the app lives a whole world. **Your Flame is you**: a living cartoon character with eyes, a mouth and a personality, who grows up alongside you. Every real thing you do in your life gives your Flame the strength to **travel further into the world**: across the Sanctuary, through the forests, deserts, mountains and skies beyond. New places, whole realms and the story of this world **open only by living**. Days, weeks, months and years of real growth become a journey you can *see*, *enter* and *remember*.

## A.2 Your Flame, the character *[Settled 79–80; details by default]*

**Who it is.** An original little flame spirit: soft rounded shapes, big expressive eyes, tiny arms and feet, a warm glow. It's *yours*: it's born with you (chapter 08), it's shaped by your life, and no two are alike.

**How it feels alive:**

| It… | When |
|---|---|
| Breathes, blinks, flickers, looks around | Always (idle) |
| Smiles, sways, hums | You're living fully (high Vitality) |
| Rests calmly | In between |
| Sleeps as a small ember, with "z"s | You've been away (it never dies) |
| Jumps and cheers | You complete something |
| Leaps with joy, relights | The comeback |
| Reacts to your touch | Tap it (it giggles), press and hold (your story) |

**How it evolves** (the character *is* your growth). Evolution is permanent (Depth), never lost:

| Stage | About when | What changes |
|---|---|---|
| **Spark** | Birth | A tiny ember with big eyes |
| **Flame** | Weeks | Grows, gains flame tips, arms, a first expression set |
| **Blaze** | Months | Taller, more confident, new animations; pillar colors show in its fire |
| **Kindled** | About a year | A distinct form shaped by *your* pillars: a Body-heavy Flame looks different from a Heart-heavy one |
| **Beyond** | Years | Rare forms nobody has seen yet |

The Eras (Stone → Metal → …) become **the world's ages** that you unlock, and your character wears their mark (for example the forged gem after the Forge).

**Personalization, earned never bought (P7):** relics you earn (Ritual rewards, Hidden Sparks, milestones) are things your Flame can wear or carry: a scarf, a lantern, a crown of embers. *"I've had this since week 40 of 2026."*

## A.3 The world *[Settled 81; map by default]*

**The world map.** A living, illustrated map you open from Today. Your Flame stands where you are in your journey. Tap a location to **travel there** (your Flame walks, hops or floats along the path) and **enter it**: a scene you can look around, with things to discover.

**Realms and locations** *(first draft of the geography)*:

| Realm | Feeling | Opens with | Tied to |
|---|---|---|---|
| **The Sanctuary** | Home: ancient ruins, water, green life | Birth | Everything; your hearth |
| **The Whispering Grove** | A forest of lanterns and listening trees | Journey step III (the Others) | Heart, World: the Ritual gathers here |
| **The Library of Embers** | Floating books, quiet light | Mind depth | Mind |
| **The Proving Road** | Paths up into the hills | Body depth | Body |
| **The Stillwater** | A lake that reflects the sky | Spirit depth | Spirit |
| **The Forge** | A glowing workshop in the mountain | Journey step VI (the Forge) | Craft; the first Transformation |
| **The Wilds** | Wide lands, other travellers' lights far away | Months of living | World; later, community |
| **Beyond the Veil** | Unknown | Years | The lore's deepest secrets |

- **Locations open by living, never by paying and never by the calendar alone** (decision 71 principle). Someone who's been away simply arrives later.
- **Each location has:** a scene to enter, things to discover (a hidden object, a character, a fragment of lore), and often the home of certain Sparks and Rituals. The Heart Ritual happens *in* the Grove, where you see other lights gathered.
- **You never see the whole map.** Unexplored regions are covered in mist and revealed as you grow (P16).

**The world moves.** Day and night follow your real time (the lived day), weather drifts, water flows, lanterns flicker, creatures wander, and the world's colors follow your Vitality. When you've been away, the world is quieter and dimmer, **never ruined** (P6).

## A.4 The lore *[by default, first seed]*

> Long ago, the world was full of flames: one for every living person. As people forgot themselves in noise and distraction, their flames dimmed, and the world went quiet and dark. The ruins you walk through were built by those who remembered. **Your Flame is new. Each thing you do in your life gives it the strength to go further, to wake the places that went dark, and to find out what happened here.**

- The story unfolds as a **journey of chapters**: the First Journey is chapter one.
- **Lore fragments** are found in locations, earned through milestones, and told by the world's characters (for example a keeper in the Library, a smith at the Forge).
- **The Chronicle** (chapter 28) becomes *your* legend within the world's story.

## A.5 Why this keeps people coming back

1. **Visible progress with meaning.** It isn't just a number: your Flame grows and your world opens up.
2. **Curiosity.** What's behind the mist? What's in the next realm?
3. **Attachment.** You care for a character that *is* you; it greets you and cheers for you.
4. **Ownership.** Relics, forms and discoveries nobody else has, earned over years.
5. **Belonging.** Other travellers' lights in the Wilds, and gatherings for Rituals (later, with community).

**Everything stays anchored in real life.** The world only moves forward when *you* do. There are no in-game shortcuts, no grinding inside the app, and no paid progress (P2, P7). The game is *how your real growth is shown*, never a replacement for it.

## A.6 How it gets built (a whole universe, step by step)

This is game-scale, and it needs its own production approach:

| Step | What | Who |
|---|---|---|
| U1 | **Character v1** (live, in the app now): moods, cheering, sleeping, first evolution by Depth | Claude (done, first version) |
| U2 | **Character bible:** the official original design, expression sheet, evolution stages, animation list | Codex concepts → Mathis picks |
| U3 | **World bible:** map, realms, locations, lore chapters, characters | Claude writes, Codex illustrates, Mathis shapes |
| U4 | **The world map v1:** the Sanctuary plus the first unlockable location (the Whispering Grove at step III), tap to travel, enter the scene | Claude builds; Codex paints |
| U5 | **Character animation pipeline:** a rigged character (Rive or SpriteKit) so the Flame can walk, jump and emote smoothly | Claude + Codex; **likely a human animator** for the final quality |
| U6 | **More realms**, each a release event, over months and years | Ongoing |

**Honest note on scale:** a world like this is the work of years, like any real game. The plan grows it **one realm at a time**, each one a moment users look forward to. The first versions will be simpler than the final vision. The foundation (record, growth engine, the character reacting to real life) is already built to carry it.

---

# Part B — For the builders

## B.1 Character model (`Domain`, pure)

```
CharacterState {
  stage: spark | flame | blaze | kindled | beyond          // from Depth + active days (permanent, monotonic)
  mood: joyful | happy | calm | sleepy                     // from Vitality + recent events (transient)
  pillarForm: [Pillar: Double]                              // normalized Depth shares → form variations
  wearing: [relicId]                                        // from owned relics (grants), user-selected
}
```
- **Stage thresholds (v1, by default):** flame at `activeDays ≥ 7`; blaze at `activeDays ≥ 60 && totalDepth ≥ 120`; kindled at `activeDays ≥ 300 && totalDepth ≥ 800`; beyond is TBD in the world bible. Each stage is a grant entitlement (`character:stage-N`), never revoked (chapter 16 §B.3).
- Mood is presentational only, with no record writes.

## B.2 World model (`Domain`, pure)

```
Location { id, realm, unlock: Condition, scene: sceneId, lore: [fragmentId], sparks: [sparkId], ritualHome: Bool }
Condition = journeyStep(n) | pillarDepth(p, ≥x) | activeDays(≥n) | grant(key) | all([Condition]) | any([Condition])
WorldState { unlocked: Set<locationId>, visited: Set<locationId>, current: locationId, fragments: Set<fragmentId> }
```
- **Unlocks are grants** (`location:{id}`), evaluated by `GrantService` from `DerivedState`, and never revoked.
- **Visits and discoveries** are record entries (`momentWitnessed { key: "visit:{id}" | "lore:{id}" }`), so they're permanent and part of your story.
- World content (locations, conditions, lore text, scenes) lives in the **content catalog** (chapter 16 §B.10), so new realms ship without app updates where possible.

## B.3 Rendering approach (first pass)
- **Map and scenes:** layered 2D illustrated scenes (parallax), tappable hotspots, animated with SwiftUI or SpriteKit. SpriteKit is preferred once scenes need walking characters and many moving elements.
- **Character:** v1 is procedural (`Experience/FlameCharacter.swift`). v2 is a **rigged 2D character** (Rive or SpriteKit bones) built from the character bible, with a state machine driven by `CharacterState`.
- The theme engine still drives color and light (decision 35): the world's time of day comes from the lived day, and its mood from Vitality.

## B.4 Next implementation slice (U4)
1. The map screen: the Sanctuary plus the Whispering Grove (locked until step III, misted), with a path between them.
2. Tap to travel: the character walks along the path (a simple tween in v1).
3. The Grove scene: the Ritual gathers here (move the Ritual card into the scene), plus one lore fragment to discover.
4. `Location`/`Condition` in `Domain` with tests, and the unlock → grant → ceremony flow.
