# P2.7 · Living worlds, real money, a fantasy Flame screen (plan, 2026-10-05)

*Source: Mathis: "the aliveness of every world is just not there… small details everywhere which feel alive, like you're in a lively game and not staring at pictures. This is vital." Plus: points that feel like earning money, a map icon, and the Flame screen redesigned like a Witcher inventory. Status: **draft, waiting for approval.***

## 1. Why the worlds still feel like pictures

What moves today is mostly **effects**: water, waterfalls, swaying leaves, fire, mist, a few fireflies. Games feel alive because of three other things we don't have yet:
- **Characters with their own lives:** small creatures that perch, hop, fly off, come back, sleep at night. Each one does something different and is never on a loop.
- **Things that happen:** a fish leaps, a flock crosses, a gust sweeps the trees and leaves fly, a shooting star at night. Small moments every 20–60 seconds, never on a timer you can feel.
- **A world that answers you:** tap a tree and birds burst out and leaves fall; tap the water and it ripples; tap a creature and it reacts; drag across tall grass and it parts.

## 2. The Life system (one engine, every world)

- **Actors:** small painted creatures and objects, each with a behaviour (perch, wander, fly a path, swim, idle, sleep) and random timings, so nothing ever repeats visibly (decision 93). Animated live: wings flap, bodies hop and squash, heads turn.
- **Life spots per world:** perches (arches, branches, rooftops), paths (ground, sky lanes), water zones. Defined per world like today's places.
- **Moving details:** banners and cloth that wave, hanging lanterns that swing, windmill blades, waterwheels, falling leaves and petals, smoke from chimneys, grass waves in the wind. Painted pieces from Codex placed over the painting, or masks the shader already knows how to move.
- **Events:** a director picks one small moment every 20–60 seconds, weighted by world, time of day and weather.
- **Touch:** every tap on the world answers with a reaction, a haptic and, later, a sound.
- **Day and night swap the cast:** butterflies and birds by day; moths, owls and fireflies at night.
- **Budget:** about 20–30 actors on screen, all cheap flat cards; 60 fps measured on the iPhone 15 after each world.

## 3. What lives where (first pass)

| World | Creatures | Moving details | Moments | Touch |
|---|---|---|---|---|
| **Sanctuary** | seagulls perching on the arches and gliding over the sea, butterflies around the wisteria, small fish in the turquoise water, a moth at night | lanterns swinging, wisteria swaying, spray on the rocks | a fish leaps (splash ring), a flock crosses the sun, a shooting star | tap the sea: ripple and fish dart; tap a gull: it flies off and circles back |
| **Grove** | lantern moths, a squirrel running a branch, an owl that blinks at night, fireflies | falling leaves, hanging lanterns, ferns | a gust of leaves, a deer at the edge | tap a tree: leaves fall and birds burst out |
| **Stillwater** | frogs on lily pads, koi under the surface, dragonflies, Ilo the heron | mist drifting, lotus flowers opening | a frog jumps (plop and ripple), koi surface | tap the lake: ripples, koi gather |
| **Highlands** | mountain goats on the cliffs, an eagle circling, marmots | a windmill turning, prayer flags, grass waves | wind gusts across the slopes | tap a goat: it bleats and hops away |
| **Library** | books flying like birds, pages fluttering, Quill the paper owl | floating islands bobbing, glowing motes | a stack of books rearranges itself | tap a book: it opens and flaps off |
| **Wilds** | deer, a fox peeking, butterflies, songbirds | tall grass waves, falling petals | a fox crosses, a butterfly swarm | tap the grass: it parts and butterflies rise |
| **Forge** | sparks, Orrin the salamander, crows on the chimneys | smoke plumes, glowing furnaces pulsing | a hammer strike flashes the whole forge | tap the furnace: it roars and sparks fly |
| **World map** | your Spark travelling the road, boats on the sea, flocks over the realms | clouds, smoke, waterfalls, each realm's own life seen from above | a light runs along the road when you complete a quest | tap a realm: it lifts and glows |

## 4. Embers that feel like money

- **Always on screen:** an Ember coin and your total in the top bar of every world, next to your streak.
- **Earning feels good:** finishing a quest bursts Embers out of the quest object; they fly into the counter, which counts up with a clink and a haptic (Hay Day and Duolingo style). Streak days and milestones give more.
- **A daily gift:** your first open of the day gives a small pouch of Embers, with a little animation (the daily check-in).
- **Buying a world:** on the map, locked worlds sit in the grey Hush with a price tag. Buying one is a small ceremony: Embers pour out, the mist lifts, the realm lights up, and the camera dives in. Prices allow the first world after about 3–4 days of living.
- **Never sold for money** (decision 81). Later, the same Embers buy Flame equipment and decorations in the shop.
- **Beta:** worlds locked again so you can feel the loop (Sanctuary and Grove free), with enough Embers already in the test data to buy one right away. A hidden switch reopens everything.

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
- Creature sheets, each creature in 1–3 pieces on magenta so they can be animated live (body, wings): seagull, butterfly, fish, moth, squirrel, owl, frog, koi, dragonfly, goat, eagle, flying book, deer, fox, crow.
- Moving pieces: banner, hanging lantern, windmill blades, waterwheel, leaves and petals.

## 7. Order

1. **Embers on screen and the buying loop.** Code only, so it can start now; it gives the strongest feeling soonest.
2. **The Life system in the Sanctuary**, to set the bar there first (stand-in sprites until Codex's creatures land).
3. **The Flame screen redesign** and the two icons, once Codex's frame and icons arrive.
4. **Life in every realm, then the map**, one world at a time, each measured at 60 fps on the phone.
