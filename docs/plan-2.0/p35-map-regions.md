# P3.5 · The world map, one region per world (decision 188) — SUPERSEDED

**Superseded the same day by decision 189** (Mathis: "a complete redesign" with floating islands and level paths, `p36-map-islands.md`). Codex's job was stopped before it changed any file.

Mathis, 2026-10-22: "rework the world map. Currently, it looks like one single world map with the different titles of the different worlds. I would really want a world map where each world is delimited by some kind of a visual effect so that we can really see the difference between the different worlds, and when the user presses on a world in order to have access to it, the whole thing lights up so that it really shows what's included in the world map for one specific world. Make sure the titles are well incorporated within the boundaries of the world itself, look nice and don't feel like they overlap too much with the world, but at the same time are nicely designed and aesthetically pleasing."

**History to respect:** on 2026-10-14 (decision 170) Codex added bounded *illustrated preview cards* over the map; Mathis had them removed the next day (decision 172, commit 65aa2c9). So the regions must live **in the map itself** (light, borders, the painting), not as cards on top of it.

**Who:** Codex designs and integrates (decision 62, Claude's standing rule: Codex does visual design and its integration). Claude briefs, checks in the simulator, installs on the phone, and reports.

**Brief:** `docs/reviews/briefs/p35-map-regions.md` (run by `scripts/p35-map-regions.sh`, in `resume-codex.sh`).

## Done means
1. Seven regions on the map (Sanctuary, Whispering Grove, Stillwater, Ascent Highlands, Library of Embers, the Wilds, Forge Mountain), each clearly delimited by a visual effect that belongs to the painted world (a luminous border, a band of the Hush's mist between worlds, a subtle tint: Codex's design).
2. Tapping anywhere inside a world selects it: the whole region lights up (its area brightens, its border glows), the rest of the map quietly dims, so you see exactly what belongs to it. The existing card and enter / buy flow follow as today.
3. Each world's name sits on a designed nameplate inside its own region, in a quiet spot that doesn't cover its landmark; readable, elegant, in the game's language (the serif "story" font, champagne / gold, crisp lip, no big blurs).
4. Unchanged: navigation, panning limits, the dive into a world, locked/price states, test flags, the daily screen, home; 60 fps on the iPhone 15; the game-wide saturation (`gameGrade` in `Shaders.metal`, decision 187).

## Steps
1. ⏳ Codex: a sketch of the target look (`docs/design/p35/map-regions-sketch.png`), then the region mask aligned to `map-paint.png`, the nameplate art, the integration, simulator captures (`docs/design/p35/verification/`), a report below.
2. Claude: check in the simulator, Release build, install on the phone, report to Mathis.
