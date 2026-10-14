# P3.2 · Next iterations (2026-10-14)

One step at a time, done completely (built, checked in the simulator, installed on the iPhone), and ticked only when Mathis agrees it's done. Codex designs wherever new art is needed (the streak screen, the icon, the new Flame, the map). **Claude does no design or visual integration work** (Mathis, 2026-10-14): only logic, rules and plumbing; everything visual goes to Codex.

| # | Step | Status | Notes |
|---|------|--------|-------|
| 1 | Intro: no colour choice, the same Flame for everyone, straight to the egg | 🟡 | "Wake it" goes straight to the egg; it hatches into the same gold Spark for everyone (friends too); why you came now comes from the "What brings you here?" question. |
| 2 | When a round ends, renew it: 7, 14, 30 or 90 days | 🟡 | The round card now offers 7 (again), 14, 30 and 90 days; it suggests one step longer (7 → 14 → 30 → 90). |
| 3 | The Flame loses vitality when quests aren't done: a first loss after 1 day, a second after 3, almost all gone after 7 | 🔄 | **Rule done and tested** (full · dimmed after 1 day · faded after 3 · almost out after 7, never zero, back with the next quest). **Look waits for Codex** (tired poses of the new Flame, the world dimming), no design by Claude (Mathis). |
| 4 | The app icon (the Flame in evidence, by Codex), on the home screen, and the name "Hush"; maybe an icon that changes with the Flame's vitality, like Duolingo | 🔄 | **Name "Hush" done.** The icon waits for Codex. |
| 5 | The daily streak screen on launch (after Finch): the Flame, a new evolution if one was reached, the days of the week | ⬜ | Codex design |
| 6 | **Priority 1.** The Flame as a character in the world, not a sticker: depth, volume, a 3D feel (not necessarily 3D), exactly like Mathis's two reference sheets (`docs/design/p32/ref-sheet-*.png`, a mix of both) | 🔄 | **Codex does the art and the integration** (Mathis). Phase A ✅: the six forms painted (`scripts/p32-flame.sh`), shown to Mathis. Phase B: faces (blink, happy), the intro glimpse as named silhouettes, and the integration in every world (smooth not pixel, light pool and contact shadow on the circle, the world softly in focus behind, worlds unchanged, 60 fps kept). Tired poses for step 3 come from the same art. |
| 7 | The world map: each world clearly delimited (bubbles or islands), readable titles, more space between worlds, unlocking a world feels like a discovery | ⬜ | Codex design |

Legend: ⬜ to do · 🔄 in progress · 🟡 done, waiting for Mathis's OK · ✅ agreed done
