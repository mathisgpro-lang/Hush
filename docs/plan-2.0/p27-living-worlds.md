# P2.7 · Living worlds, real money, a fantasy Flame screen (plan, 2026-10-05)

*Source: Mathis: "the aliveness of every world is just not there… small details everywhere which feel alive, like you're in a lively game and not staring at pictures. This is vital." Plus: points that feel like earning money, a map icon, and the Flame screen redesigned like a Witcher inventory. Status: **approved (decisions 141–142), building.***

## 1. Alive = what is already painted breathes (Mathis, 2026-10-05)

*"It's not so much adding new elements, but making the current ones alive… the books floating with pages turning, the clouds in the back moving, the torches burning and the shades on the ground changing with the fire, the little plants moving in the wind… making things breathe is the core of what we started with the Flame, and it should be like this all throughout the app."*

So the work is not new creatures: it's giving **every painted thing its own life**, as the Flame has.

## 2. How (one engine, every world)

- **Floating things are cut out** of the painting (books, islands, lanterns), with what's behind them filled in, so they really float: they bob, drift, tilt, and books open and close their pages like wings. They sit in 3D at their own depth, so they move against the background as you look around.
- **A life map per world** (`<id>-world-life.png`, made by a tool from the painting and its depth, checked by eye): what is foliage, cloth, flame, cloud.
- **The world shader brings each kind alive:**
  - plants and vines sway, each with its own rhythm, and gusts travel across them;
  - banners and cloth wave, more at the bottom than at the top;
  - clouds drift continuously behind everything;
  - each flame flickers on its own, and its pool of light on the floor, walls and objects flickers and shifts with it, so the shadows breathe;
  - water and waterfalls flow (already there), glossy floors shimmer with the light.
- **Touch** (later in this phase): tapping something makes it answer (a book flutters, a lantern flares, a plant shivers).
- **Budget:** 60 fps measured on the iPhone 15 for every world.

## 3. What breathes where

| World | What comes alive |
|---|---|
| **Library** (first, the benchmark) | the dozen floating books (drifting, pages flapping), the floating castles bobbing, clouds drifting, every hanging lantern and the fireplace flickering with light dancing on the glossy floor, vines and wisteria swaying, the blue banners waving, the globe slowly turning, the waterfalls of the islands |
| **Sanctuary** | braziers and lanterns flickering with moving light pools, wisteria and vines swaying, clouds drifting, the sea and the falls, the rune circle's glow breathing |
| **Grove** | the lantern trees swaying and flickering, leaves and ferns in the wind, light dappling through the canopy |
| **Stillwater** | the lotus swaying on the water, mist drifting, reflections rippling, lanterns flickering |
| **Highlands** | grass and trees in the wind, the windmill turning, flags waving, clouds racing over the peaks |
| **Wilds** | tall grass waves, trees swaying, light shifting through leaves |
| **Forge** | furnaces flickering with their glow on the stone, smoke rising, sparks |
| **World map** | every realm's details breathing from above, clouds and sea, the road's lights |

## 4. Embers that feel like money

- **Always on screen:** an Ember coin and your total in the top bar of every world, next to your streak.
- **Earning feels good:** finishing a quest bursts Embers out of the quest object; they fly into the counter, which counts up with a clink and a haptic (Hay Day and Duolingo style). Streak days and milestones give more.
- **A daily gift:** your first open of the day gives a small pouch of Embers, with a little animation (the daily check-in).
- **Buying a world:** on the map, locked worlds sit in the grey Hush with a price tag. Buying one is a small ceremony: Embers pour out, the mist lifts, the realm lights up, and the camera dives in. Prices allow the first world after about 3–4 days of living.
- **Never sold for money** (decision 81). Later, the same Embers buy Flame equipment and decorations in the shop.
- **Beta (Mathis chose):** worlds locked again so you can feel the loop (Sanctuary and Grove free), with enough Embers in the test data to buy one right away. `-allopen` reopens everything.

## 5. The Flame screen as a fantasy character sheet (Witcher-inventory feel)

- **The frame:** dark carved wood and worn leather with gold filigree, parchment inlays, warm candlelight. Painted by Codex.
- **Centre:** your Spark full-size on a small stone hearth, alive (it breathes and reacts when tapped), with its stage name in a banner.
- **Around it, equipment sockets** (hat, aura, cloak, trinket, companion): ornate empty sockets now, filled later from the shop.
- **Left page, the character sheet:** level in a wax seal, XP as a rune bar, the six attributes as engraved medallions with big numbers (Day 1 → today).
- **Right page, the chronicle:** streak flame and shields, days lived, Embers, the 66-day path drawn as a road.
- **Tabs like a journal's ribbons:** Character · Journey · Friends.
- **The bar icon:** a fantasy emblem that fits the set (for example your Spark inside a small lantern), and the **World icon becomes a folded fantasy map**, in the same painted style as the satchel and the Book.

## 6. Art from Codex (queued for tonight, after its limit resets)

- World icon (folded map), Flame icon (Spark in a lantern), the Ember coin and pouch.
- The character-sheet frame, equipment sockets, the wax seal.
- Clean plates where cut-outs need what's behind them (only if the tool's fill isn't good enough).

## 7. Order

1. **Embers on screen and the buying loop.** Code only, so it can start now; it gives the strongest feeling soonest.
2. **The Library breathing** (Mathis's example), as the bar; then the Sanctuary.
3. **The Flame screen redesign** and the two icons, once Codex's frame and icons arrive.
4. **Life in every realm, then the map**, one world at a time, each measured at 60 fps on the phone.
