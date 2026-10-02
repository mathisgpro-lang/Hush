# P2.5 · Iteration 2: Mathis's list (2026-10-02)

*Source: Mathis's list of improvements (world map, Sanctuary, the Flame, the introduction). Status: **draft, waiting for Mathis's approval.***

## The order I recommend

| # | Piece | Why here |
|---|---|---|
| 1 | **The Spark**: the new first Flame, a pure spirit | It appears on every screen, so everything else is tuned around it. Codex is already painting concepts. |
| 2 | **The Sanctuary**: sharp and vibrant, the Spark truly part of the world, the day's quests as an inventory | Home is where you spend most of your time. |
| 3 | **The world map alive**: depth, movement, tapping realms, the bird dive | The same pipeline as the Sanctuary, applied again. |
| 4 | **The Whispering Grove**, rebuilt the same way | The first realm the dive lands in. |
| 5 | **The introduction**, rebuilt last | It tours everything above, so it has to come after them. |

## 1. The Spark (the first Flame)

**The problem:** with its arms, legs and plush body, today's character reads as a later stage.

**Concepts (Codex, running now):** four Spark shapes with exactly the same face (eyes, smile, cheeks, colors), but only a small floating spirit of fire:
- A: a teardrop;
- B: a wisp with a trailing flick;
- C: an ember ball with a crown of flames;
- D: a living candle flame.

Codex is also painting the **growth line**: Spark → Flame (today's character) → Blaze → Kindled → Beyond.

**After Mathis picks:**
- Codex paints the chosen Spark in parts: the wisp body, then the face pieces (eyes open and closed, smiles).
- I rig it live:
  - fire flowing up through it;
  - it hovers and bobs, since it has no legs;
  - it blinks, smiles, squints happily;
  - it reacts to touch.
- **Today's character becomes the second stage**. Until then, it's seen only in the evolution preview.

## 2. The Sanctuary

### 2a. Sharp and vibrant, never blurry or grey

**Causes found:**
- The painting is 1,846 pixels tall, but the phone shows it zoomed in on a screen 2,556 pixels tall. Everything is magnified about 1.6×, so it looks soft.
- The haze painted around the cliffs turns white-grey in daylight.
- The depth effect stretches pixels at sharp edges.

**Fixes:**
1. **Double the painting's resolution** with a free super-resolution model that runs on the Mac. That needs one download, and I'll ask first with its name, source and size. The fallback is Codex repainting the world in tiles.
2. **In daylight the painted haze becomes sunlit spray:** warmer and more contrasted, never grey. If that's not enough, Codex paints a cleaner version with less haze.
3. **Less stretching at the edges** of the depth effect.

### 2b. The Flame truly part of the world

**Why it still looks like a layer on top:**
- The world's light doesn't touch it: at night the world turns blue, but the Flame stays fully lit.
- It doesn't touch the ground.
- It's sharper than the painted world around it.
- It's too big.

**Fixes:**
- Spark size: much smaller.
- **The hour lights it too:**
  - a warm rim from the sun at dusk;
  - a cooler cast by day;
  - at night only its own glow.
- **It touches the stones:** a soft contact shadow and a glow pool beneath it, and its light reflected in the rune circle.
- **The same softness as the painting** (no razor-sharp edges).
- **Heat shimmer** above it.
- Now and then **mist, fireflies and petals drift in front of it**. Things passing in front are what make the eye believe it's inside the scene.

### 2c. The day's quests: an inventory (question for Mathis)

**The problem:** tags floating over the world aren't clear.

**Options:**
- **A. A Quest Satchel (recommended).**
  - A satchel icon at the bottom of home. Tap it and a painted parchment journal slides up with today's quests as cards. You pick what you'll do today.
  - Each chosen quest appears in the Sanctuary as a small object waiting for you (a lantern on a brazier, a scroll on the steps).
  - Tap the object to complete the quest: its light flies to your Flame.
  - Clear (one place to choose) and alive (the world holds your day).
- **B. A Quest Board inside the world:** a carved stone tablet in the Sanctuary, tapped to open the same list. Very immersive, but harder to find.
- **C. Keep the floating tags**, redesigned. The least change, but the least clear.

Codex paints mockups of the journal and the in-world objects in the style.

## 3. The world map alive

**The same pipeline as the Sanctuary:**
- depth from Apple's depth model;
- moving water (the sea at the bottom, waterfalls, the lake);
- the forge's fire;
- the library's floating books;
- living layers: a sky whose clouds really drift, and banks of mist between the realms;
- time of day;
- birds.

**Moving around (Clash of Clans style):** drag up and down along the map, pinch to zoom a little, with rubber-band edges.

**Tap a realm:** it glows, and a card shows:
- its name and what it is;
- what opens it;
- your progress there.

**Enter a realm: the bird dive.** The Flame no longer walks the road; *you* fly.
1. The camera lifts.
2. It swoops down toward the realm like a diving bird, clouds rushing past.
3. The realm grows until it fills the screen and becomes the realm itself, in one continuous shot.

Coming back is the same dive in reverse.

**Resolution:** the map gets the same sharpening as the Sanctuary.

## 4. The Whispering Grove

- Codex paints the Grove in the style root: a portrait view plus side panels so it can be swiped, and clean plates for the sky and the water.
- The same pipeline as the Sanctuary.
- Its lanterns relight as your Heart pillar grows (the S3 mechanics already exist).

## 5. The introduction (rebuilt last)

**The hatching in one continuous shot, no cuts:**
1. Hold to warm the ember.
2. Cracks glow.
3. The shell opens softly into light.
4. The small Spark rises out.

**A glimpse of what it will become:** the Spark glows and, for about three seconds, transforms through the stages (Flame → Blaze → Kindled → Beyond), then settles back into a Spark. *"One day, this is who we'll become."*

**A tour of the world**, one line per stop, each skippable:
1. The Sanctuary: home, your quest satchel, your Flame.
2. The camera rises to the world map (the dive in reverse) and shows the Grove: *"our first journey"*.
3. A dive into the Grove for a glimpse.
4. Back home.

**Smooth throughout:** every change is a camera move inside the same world. No cuts, no screens popping in.

## Questions for Mathis, one at a time
1. Approve this plan and its order.
2. How the quests work (2c).
3. Which Spark (when Codex delivers).
4. Permission to download the free super-resolution model (name, source and size given first).

## Rough size
Each item is a few working sessions:

| Piece | Sessions |
|---|---|
| Spark | 1–2 |
| Sanctuary | about 2 |
| Map with the dive | 2–3 |
| Grove | about 2 |
| Intro | about 2 |

Codex's image limits are the main risk to the timeline.
