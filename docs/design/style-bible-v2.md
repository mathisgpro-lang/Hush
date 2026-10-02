# Style Bible v2 — "Living light in a painted world" (decision 113)

*The root of all visuals from now on. Root frame: `docs/design/cohesion/D-luminous.png` (with `B-painterly.png` as its sibling).*

## The one idea
The world is a rich, warm, painterly illustration at golden dusk. **Your Flame is painted into it as living light**: same brushwork, same palette, softer edges, glowing from within. It's the warmest, clearest thing on screen, and it lights what's near it.

## Rules
1. **Every image is generated with the root frame as a reference** (Codex `--image docs/design/cohesion/D-luminous.png`), plus the specific source (the Flame's parts, a place) when needed.
2. **The Flame's look:** round plush body of soft fire, a tall soft flame crest (not separate spiky tongues), big glossy brown eyes with highlights, rosy cheeks, a small smile, a bright swirling core in the chest, warm glow bleeding into the surroundings, soft painterly edges (no hard outline).
3. **Scale at home:** the Flame sits in the middle of the stone circle, about **1/6 of the screen height**, as in the root frame.
4. **Light:** dusk gold key light from the low sun (right); violet-pink sky fill; the Flame adds a warm orange pool on the stones around it. Shadows are soft and warm, never black.
5. **Palette tokens:** sky violet `#7E6A9E`, sunset pink `#E8A08C`, gold `#F2B85C`, ember `#FF8A3D`, Flame core `#FFF1C2`, sea teal `#2E9AA0`, stone `#D8C3A0`, moss `#7C8A3A`, wisteria `#9A7CC0`, the Hush grey-blue `#9AA0AE`.
6. **Detail density:** rich but with **one focal point** (the Flame on the circle). Edges of the frame get softer and less detailed (a vignette of detail), so it reads like a game screen, not a poster.
7. **UI materials:** ember-glass plates (dark, warm, translucent) with gold hairlines; parchment for reading; glowing runes for progress; custom icons in the same soft-gold brushwork. Fonts: a display serif (Cormorant Garamond) and Inter for small text (Google Fonts, free).
8. **Motion and sound** follow the P2.5 spec (`docs/plan-2.0/p25-design-spec.md`).

## Assets being remade in this style
- `docs/design/v2/sanctuary-home.png`: the root frame's world **without** the Flame (the empty glowing circle), for the live home scene.
- `docs/design/v2/rig/`: the Flame as separate layers in this style (body + crest, a soft flame crest in 3 pieces, eyes, mouths, cheeks) on flat magenta, for the live rig.
- Then: the six task objects, the map and the Grove retouched toward this style, the UI kit.
