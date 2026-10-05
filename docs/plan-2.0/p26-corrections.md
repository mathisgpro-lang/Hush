# P2.6 · Mathis's corrections list (2026-10-05)

Everything here is done before any other work, except the items marked *later*.

| # | Item | Status |
|---|------|--------|
| 1 | The same look-around limits in every world as in the Sanctuary | done |
| 2 | Flame colors subtler: the core stays painted, only hints of the ember's color at the rim and tips | done |
| 3 | The intro's evolution glimpse shown in shadow (silhouettes) | done |
| 4 | Coherence: one set of fonts, colors, icon style and sizes; the Flame menu matching the world | done |
| 5 | Bottom bar icons (World, Satchel, Book, Your Flame) as small live animations | done |
| 6 | Opening and closing tabs fluid | done |
| 7 | Time of day redesigned: beautiful, accurate and alive at every hour, never laggy | done |
| 8 | World map truly alive, with depth; more spacious (no realm cut off at the sides) | done |
| 9 | Beta: every world unlocked. Embers earned by living buy the next world (decision 136) | done |
| 10 | Friends: profile, completed challenges, streak, how they're doing (decision 137, sample friends until P5) | done |
| 11 | Onboarding: research the best practices (catalog sites), then rework the intro (keep the hatching, the Flame coming alive, the few setup questions, the evolution in shadow) | done |
| 12 | *Later:* how Finch drives retention and payment, adapted to Hush | later |
| 13 | *Later:* a shop where Embers buy Flame equipment, decorations, worlds | later |

## Notes (2026-10-05)
- **Onboarding research** (Appcues, UXCam, Retention.Blog's Finch teardown, PageFlows): value before anything else (Duolingo's first lesson before signup lifted daily users 20%), the hatching as the emotional hook (Finch), questions as big tappable cards with progress, a personal starter plan with goals already picked (Finch), celebrate the first win, ask for permissions after the value is felt.
- **Intro now:** hatch → name → the evolution in shadow → the world went quiet → 3 questions (the Spark answers each) → *Where you're starting* (first three quests picked) → one quest done together (three guided breaths) → the reward (light, XP, Day 1 lit) → mornings → home.
- **Time of day:** looks from Codex's repaintings (dawn, day; night by hand until Codex's usage limit resets at 21:49, then refitted automatically by `scripts/p26-tod.sh`), a sun clock that follows the seasons.
- **Known:** new realms render black in the simulator only (pre-existing; the Grove renders). To check on the iPhone.
