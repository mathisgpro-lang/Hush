# Plan 2.0 · Part 4 — Art, Sound and Feel Direction

*The style guide for everything you see, hear and feel. One family, one world.*

**Status:** draft · **Written:** 2026-10-01 · **Based on:** decisions 75, 79, 82; the original brief's "Overall style"; Mathis's references
**Supersedes:** chapter 12's visual identity (pixel and realistic directions are retired; New York + SF Pro typography remains for readability)

---

## 1. The style in one line

> **A warm, stylized 3D storybook world:** soft shapes, glowing light, rich color, and characters with big feelings. It's *Spirited Away*'s warmth meets *Ori*'s luminous restoration, rendered like a premium animated film, alive in your hand.

**What we keep from the original brief:** the *cockpit* precision (crisp UI, beautiful motion, haptics), *Dune*'s scale and ancient ruins, and the *nature sanctuary*. These are now expressed through a cartoon lens.
**What we left behind:** photorealism (too cold, "4K game vibes") and pixel art (tried and dropped).

---

## 2. Visual pillars

| Pillar | Rule |
|---|---|
| **Warm light first** | Every scene has a warm light source; your Flame is always the warmest thing on screen |
| **Soft shapes** | Rounded forms, no sharp aggression; even ruins have soft edges |
| **Readable at a glance** | Clear silhouettes, strong value contrast between characters and backgrounds |
| **Alive, always** (decision 93) | Your Flame is never a still picture; something is always moving: embers, leaves, water, lanterns, breathing. See Part 3 §12 |
| **Restoration is visible** | Grey (Hush) ↔ color (alive) is the main visual language of progress |
| **One family** | The Flame, the Keepers, creatures and places all share proportions, shading and palette |

---

## 3. Color

### Global palette
| Role | Color | Notes |
|---|---|---|
| Flame core | `#FFD873` golden | Always the brightest value on screen |
| Flame body | `#FF8A2A` → `#F25A1E` | Orange to deep ember |
| Dusk sky | `#3B2F4A` → `#E58A5C` | The Sanctuary's signature gradient |
| The Hush | `#9AA0AE` at 40–70% | Desaturated blue-grey mist, never black |
| UI plates | `#14111C` at 72% | Dark, warm, translucent |
| Text | `#FFFFFF` / `#FFFFFF` at 70% | Over dark plates only |

### Realm palettes
| Realm | Key colors |
|---|---|
| Ascent Highlands | Sunrise orange, sandstone, waterfall teal |
| Library of Embers | Ink blue, parchment gold, lantern amber |
| Whispering Grove | Moss green, lantern gold, dusk violet |
| Stillwater | Night indigo, silver, lotus pink |
| Forge Mountain | Molten orange, bronze, steel blue |
| The Wilds | Meadow green, sky blue, flower accents |

**Restoration grading:** each realm has a *Hushed* grade (desaturated, cool, foggy) and an *Alive* grade (its palette at full saturation). The restoration level (Part 1 §8) blends between them per area, so color literally returns as you live.

---

## 4. Shapes, materials, lighting

- **Characters:** stylized 3D, chunky proportions (big head-to-body ratio), soft subsurface glow, rim light, fluffy fire shader on flames.
- **Environments:** stylized 3D dioramas or 2.5D painted layers (Part 5 decides by realm). Hand-painted textures, soft ambient occlusion, volumetric light shafts, gentle fog.
- **Lighting:** one warm key light (your Flame or the sun), cool fill from the sky, bloom on emissives (lanterns, embers, the core).
- **Particles:** embers, fireflies, pollen, dust motes, sparks. Always soft and never noisy.

---

## 5. UI over the world

The interface should feel like **part of the world**, not a layer stuck on top:
- **Calls (today's steps)** are small glowing scrolls or tags floating near the hearth, color-coded by realm. They replace the flat cards.
- **Plates:** dark, warm, translucent, with a thin realm-colored edge and a soft glow on press.
- **Typography:** New York (serif) for names, ceremonies and lore; SF Pro for everything functional; generous spacing; no exclamation marks (chapter 12 voice rules).
- **Icons:** custom, rounded, drawn in the world's style (later). SF Symbols are placeholders.
- **Motion:** spring-based, soft overshoot; transitions are *movement through the world* (stepping out of the Sanctuary gate, the camera gliding over the map), never a hard cut.
- **Accessibility:** every color pair meets WCAG AA; Dynamic Type; Reduce Motion swaps camera moves for fades.

---

## 6. Sound and music

| Layer | Direction |
|---|---|
| **Music** | Warm, acoustic and orchestral-lite (Ghibli-like piano, strings, woodwinds, soft choir in ceremonies). Each realm has its own theme; the Sanctuary's theme is the main motif, varied per Age and season |
| **Ambience** | Per realm: wind and waterfalls (Highlands), pages and fire (Library), leaves and chimes (Grove), water drops and silence (Stillwater), bellows and anvils (Forge), birds and rivers (Wilds). Your Flame's crackle is always near |
| **Your Flame's voice** | Non-verbal vocalizations (giggles, hums, sighs, "hm!", sleepy breaths), recorded or synthesized, cute but never squeaky. Its voice deepens slightly with each stage |
| **The tracking moment** | A strike, a whoosh, then a chime in the realm's key (chapter 06's pillar voices remain) |
| **Ceremonies** | Swells with choir and bells; every ceremony has its own short theme |
| **Silence** | A design tool: the Stillwater and the evening Hearth are mostly quiet |

**Rules:** respect the silent switch (ambient category); everything can be turned off; no sound ever pressures or alarms.

---

## 7. Haptics (the feel)

Chapter 06's haptic language remains and extends into the world:
- **Heartbeat** when you touch your Flame.
- **Charge, strike and thrum** for the tracking moment.
- **Footsteps** (very light) when your Flame travels on the map.
- **A distinct texture per realm** on landing (grounded for the Highlands, crisp for the Library, a soft double beat for the Grove…).
- **Crescendos** for ceremonies (birth, the Return, evolution, Beacons).

---

## 8. Reference boards to produce (Codex, then a human artist)

1. **Style frames** (5): the Sanctuary at dawn with your Flame; the world map; the Highlands Hushed vs. Alive; the Grove Gathering at night; an evolution ceremony.
2. **Character turnaround:** your Flame at each stage, front, side, back and three-quarter.
3. **Keepers lineup:** all six Keepers plus the Lamplighter, to scale, in the same style.
4. **Realm keys:** one key illustration per realm.
5. **UI kit:** calls, plates, buttons and the map UI, in-world.

Codex makes the concepts (one image per call, short prompts). Mathis picks. A human artist then turns the chosen concepts into production assets (Part 6).

---

## 9. Style anchors: approved by Mathis (decision 95)

*Mathis, 2026-10-01: "I absolutely love the evolution concept v2 of the spark towards beyond, and I also absolutely love the Whispering Grove and the other world concepts Codex has designed, those are exactly the kind of world I want this app to feel like."*

| Anchor | File | What it fixes |
|---|---|---|
| **Your Flame's evolution** | `docs/design/character/flame-evolution.png` (v2) | The character's identity across all five stages: the same face, glossy eyes, plush fluffy fire, swirling golden core, glowing markings appearing in the later stages |
| **The character** | `docs/design/character/flame-hero.png`, `flame-expressions.png` | Proportions, materials, emotional range |
| **The Whispering Grove** | `docs/design/world/grove-scene.png` | The world's feel: rich, painterly, luminous, hundreds of warm lights, mist, depth, golden-hour color |
| **The world map** | `docs/design/world/world-map.png` | The Emberlands' layout and grandeur: the Sanctuary in the sea, the Grove, the Stillwater, the floating Library, the Forge, the Veil |

**What this settles:**
- **The world's target is the Grove/map look,** detailed and painterly-rich, not a simplified cartoon. The character and the world become one family through **shared light and palette** (warm key light, golden glow, dusk violets), **not** by simplifying the world.
- **Every new concept is generated with these images as references** (Codex `--image`), so the look doesn't drift.
- **The evolution keeps v2's identity and arc.** The design round adds distinct details per stage (posture, markings shaped by your pillars, the crown at Kindled) on top of v2, so each stage reads as deeper, not just bigger (decision 4).
- **A technical note for spike S2:** a world this rich is demanding on a phone. S2/S3 must show whether it runs fully in 3D, or as painted, layered scenes with live 3D elements (water, lights, mist, creatures) and your live 3D Flame. Either way it must look like these anchors and move (decision 93).
