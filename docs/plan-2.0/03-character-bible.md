# Plan 2.0 · Part 3 — The Character Bible

*Your Flame: who it is, how it looks, how it lives, how it grows with you for years.*

**Status:** draft · **Written:** 2026-10-01 · **Based on:** decisions 76, 79–82, Mathis's reference images (style inspiration only; the design is original)
**Inspirations (spirit, never copied):** Calcifer (*Howl's Moving Castle*) for a fire with attitude and heart. The soot sprites (*Spirited Away*) for tiny lives with big feelings. Pokémon for evolution you're proud of. Tamagotchi and Finch for a companion you care for. Baymax (*Big Hero 6*) for a soft, huggable, caring presence. Pixar for emotional readability with very few lines.

---

## 1. Who your Flame is

**Your Flame is you: the part of you that's alive.** Not a pet you feed, not a mascot that sells you things. It's a small living fire that grows when *you* grow.

| Trait | Expression |
|---|---|
| **Warm** | It's always glad to see you. Always. |
| **Brave, a little clumsy** | It tries things, trips, laughs, tries again |
| **Curious** | It looks around, points at things in the world, wants to go further |
| **Honest** | When you're away, it's sleepy, never sad or guilt-tripping |
| **Proud of you** | It cheers for every real thing you do, big or small |
| **Growing** | Its personality deepens with its stage: from a babbling spark to a wise, radiant companion |

**What it never does:** beg, cry because you left, shame you, sell you anything, pretend to be human.

---

## 2. The look (the final target: stylized 3D, decision 82)

**Silhouette:** a round, plush body of soft fluffy fire, with flame hair rising from the head (the tallest tongue in the center), short stubby arms and legs. It reads instantly as "a little fire person" at any size, even as a tiny icon.

| Element | Design |
|---|---|
| **Body** | Plush, fluffy fire texture (like fur made of flame), soft volume, subsurface glow |
| **Core** | A golden glow in the chest, brightest at the center, pulsing gently like a heartbeat |
| **Flame hair** | 3 to 7 tongues depending on the stage, moving constantly, the center one tallest |
| **Eyes** | Large, glossy, dark amber-brown, with two highlights (a big and a small one); the main emotional instrument |
| **Brows** | Soft, slightly darker flame strokes, very expressive |
| **Cheeks** | Rosy blush that brightens when it's happy or shy |
| **Mouth** | Small; it opens wide only for joy or surprise |
| **Limbs** | Stubby, rounded, with a soft flame fuzz at the edges |
| **Light** | It lights its surroundings: the ground glows warm where it stands |
| **Embers** | A few tiny embers always float up from it, more when it's happy |

**Colors:** a base of warm orange to golden yellow. The fire's tint shifts slightly toward the pillars you've been living lately (chapter 03 §A.2): ember orange for Body, a blue glint for Mind, rose-gold for Heart, silver-white for Spirit, bronze for Craft, green-gold for World. It's subtle, a tint and never a costume.

**Rendering:** a stylized 3D model (toon or soft-PBR shading with rim light) rendered in real time in the app (Part 5), with fluffy fire done through a fur and flame shader, plus particle embers.

---

## 3. Evolution: your Flame grows up (permanent, decision 80)

Stages are **earned by time lived** (active days) **and Depth**, and are never revoked (Domain `CharacterStage`, already built and tested).

| Stage | Earned at (v1) | Look | Personality | New abilities |
|---|---|---|---|---|
| **Spark** | Birth | Tiny, round, enormous eyes, 3 small flame tips, no arms yet (little nubs), wobbly | Babbles, curious about everything, falls over | Wakes, sleeps, cheers |
| **Flame** | 7 active days | Taller, real arms and legs, 4 tips, more expressive | Playful, brave, chatty | Walks the world, waves, points at things, **chooses its name** (see §5) |
| **Blaze** | 60 active days + Depth 120 | Confident posture, 5 tips, a brighter core, first **pillar markings** (soft glowing patterns shaped by your strongest pillars) | Determined, funny, protective | Runs, leaps, carries keepsakes, visits Keepers alone |
| **Kindled** | 300 active days + Depth 800 | A radiant form; markings complete; a unique silhouette shaped by *your* life (§4) | Wise, warm, calm, still playful | Lights Beacons, guides younger flames (Act III) |
| **Beyond** | Years | Unknown, revealed only to those who arrive | — | — |

**The evolution ceremony** (once per stage):
1. Your Flame glows brighter and brighter, then is wrapped in light, with a swelling haptic and music.
2. Silhouette transformation (a Pokémon-style reveal, slower and gentler).
3. The new form opens its eyes, looks at itself, then at you, and smiles.
4. The Lamplighter or a Keeper says one line.
5. A keepsake: *"The day your Flame became a Blaze. 14 March 2027."*

---

## 4. Your life shapes its form (pillar shaping)

At **Blaze** and **Kindled**, your Flame's markings and form reflect *your* life's shape, from its Depth per pillar. Two people's Kindled Flames never look the same.

| Strongest pillar | Markings and form traits |
|---|---|
| Body | Ember-orange streaks like muscle lines; a sturdier stance |
| Mind | Fine blue patterns like script or circuitry; a slightly taller head flame |
| Heart | Rose-gold heart-shaped core glow; softer, rounder form |
| Spirit | Silver-white halo-like flame crown; a calm floating posture |
| Craft | Bronze geometric patterns; little forged ornaments |
| World | Green-gold leaf-like flame tips; tiny flowers that bloom on it in Thaw |

The **top two pillars** blend; the others add faint accents. **Balance** has its own look: a harmonious, many-colored core (P9: balance is shown, never forced).

---

## 5. Its name

- **At Spark, it has no name**: it's simply *your Flame*.
- **At the Flame stage (week 1)**, a small scene: your Flame tries to say something, can't quite, and looks at you. *"It wants a name."* You name it (optional; you can skip and keep "your Flame").
- From then on, the Keepers and the Lamplighter call it by that name. The Book of Your Flame is titled with it.

---

## 6. Behaviors and animation set (the production list)

### Idle (always)
breathe · blink · flame-hair flicker · look around · glance at you · stretch · yawn (morning) · sit by the hearth (evening) · sleep curled (night, embers)

### Reactions
cheer (arms up, hop) · proud pose (full day) · catch the light (tracking moment) · throw the light toward a realm · giggle (tapped) · surprised (an Encounter) · determined (Body) · curious head tilt (Mind) · warm hug-self (Heart) · peaceful closed eyes (Spirit) · focused squint (Craft) · caring gesture (World)

### Moods (from Vitality)
joyful · happy · calm · quiet · sleepy ember. Transitions are always slow and gentle.

### Movement (from the Flame stage)
walk · hop · run (Blaze) · float (Spirit-shaped) · travel along roads on the map · enter and leave places

### Ceremonies
birth (from an ember: Spark hatching) · the Return (waking from the Hush) · evolution (per stage) · the Forge · Beacon lighting · Birthday

### Rules
- **Every animation is short and interruptible** (it never blocks the user).
- **Reduce Motion:** the Flame stays expressive through the face, eyes and glow instead of big movements.
- **VoiceOver:** every state has a spoken description ("Your Flame is cheering").

---

## 7. How it speaks

- **Mostly without words**: faces, gestures, sounds (a small warm "hm!", a giggle, a sleepy sigh). It's expressive like Pixar shorts.
- **When it uses words** (short speech bubbles, never walls of text):
  - **Spark:** single words ("Oh!" "Again!" "Warm…").
  - **Flame:** short phrases ("We did it!" "Where next?").
  - **Blaze and Kindled:** short, wise, playful sentences, sometimes referencing your journey ("Remember the first summit? Look how far.").
- **Never:** advice (that's the Keepers' job, with sources), guilt, or pressure.

---

## 8. The cast (other characters)

| Character | Who | Personality | Role |
|---|---|---|---|
| **The Lamplighter** | An ancient, dim, hooded flame in the Sanctuary | Wry, gentle, patient, hopeful | Mentor of Act I, lore-teller, welcomes the Return |
| **Brakka** (Body) | A stone tortoise with a mountain on her back | Patient, immovable, warm | Body counsel, Highlands Journeys |
| **Quill** (Mind) | A living-paper owl | Curious, playful, forgetful | Mind counsel, keeps the Book |
| **Nim & Ro** (Heart) | Twin lantern-fireflies | Chatty, affectionate, finish each other's lines | Heart counsel, host the Gathering |
| **Ilo** (Spirit) | A silver heron who whispers | Serene, mysterious | Spirit counsel, the Stillwater |
| **Orrin** (Craft) | A soot salamander smith with spectacles | Gruff, secretly proud | Craft counsel, the Forge ceremony |
| **Mossbeard** (World) | A walking forest giant with birds in his beard | Slow, funny, enormous heart | World counsel, the Wilds |
| **Encounter creatures** | Foxes, owlets, hedgehogs, koi, moon moths, automatons… | Each with a tiny story | Carry Sparks (requests) |
| **Legendary beings** | One per realm, very rare | Majestic | Carry Hidden Sparks |

**All of these share the same style** as your Flame (stylized 3D, soft, expressive), designed as one family.

---

## 9. What your Flame can wear and carry (keepsakes, earned only)

- **Worn:** a scarf from the Long Light Gathering, a lantern from your first Grove Journey, an ember crown from the Forge, flowers from Thaw.
- **Carried:** a tiny book (100 days of reading), a walking stick (the First Summit).
- **Displayed at home:** everything else.
- **Rule:** only one or two items at a time on the Flame; the rest live in the Sanctuary. Every item says when and how it was earned. **Nothing is ever sold** (P7).

---

## 10. From today's v1 to the final character

| Today (v1b, procedural, decision 82) | Final (stylized 3D) |
|---|---|
| A 2D vector shape drawn in code | A modeled, rigged 3D character |
| 4 moods, a cheer, sleep | Full animation set (§6) |
| Flame tips from Depth | Stages, pillar shaping, markings |
| A flat gradient | Fluffy fire shader, subsurface glow, rim light, particles |

**Production path:** Part 6. The short version: Codex concept art → a final design approved by Mathis → a 3D artist models and rigs it → an animator makes the animation set → it plugs into the app's character state machine (Part 5).
