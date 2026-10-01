# P3 Phase Plan — The Vertical Slice: "The Waking"

*Turn the tested pieces into the real app: the first six weeks of the universe, at final quality, lived by Mathis on his phone.*

**Status:** draft for Mathis's approval · **Written:** 2026-10-01
**Meets:** Part 9 §4 (the P3 gates) · **Builds on:** P2 results (`prototypes/p2-spikes/PIPELINE.md`), the foundation in `app/` (engine, record, living slices)
**Constraints:** AI-only art until Mathis decides otherwise (87) · no paid Apple program (88) · English (90) · safe Paths first (91) · no predetermined goals (92) · Alive, always (93) · style anchors (95) · story through chosen pillars (96) · the integration and depth bar (101) · focus on the world and the app (103)

---

## Part A — For Mathis

### A.1 What you'll have at the end
The real app on your iPhone, where:
1. **You meet your Flame.** It hatches from an ember in the Sanctuary and speaks its **First Words**, then asks what would make your year feel alive.
2. **You choose what to grow,** with the app helping you find it (no fixed goals). Your Flame walks you to a Journey.
3. **Each day, your steps float as calls by the hearth.** Doing one sends light from your Flame into the world, and you see something change *today*.
4. **The world wakes as you live:**
   - **The Sanctuary** brightens from *everything* you do: braziers relight, waterfalls flow, flowers open, the mist lifts.
   - **The Whispering Grove** relights lantern by lantern from your Heart actions.
   - **The other realms** glow faintly on the map as you touch their pillars.
5. **Act I unfolds over about six weeks:**
   - the Lamplighter;
   - your first Encounter;
   - the Grove and its Gathering;
   - your Flame evolving from a **Spark into a Flame** (and asking for a name);
   - the Keepers' counsel;
   - the Book of Your Flame;
   - and finally **Orrin coming to your hearth to forge the Age of Metal**.
6. **Evenings at the Hearth, the Hush when you're away, the Return when you come back.** Never guilt.

### A.2 What it won't have yet (it comes in P4 and later)
- Other realms you can enter (they stay misted on the map).
- Training plans (decision 91).
- An AI Companion (no paid program; curated counsel instead).
- Sync, other people, real Gathering counts, a human composer.

### A.3 What the slice teaches us
Does the universe make you come back *because you want to*, and does it help your real life? You'll live it for about six weeks, and we judge it by Part 9 R9: useful outside the app, easy to skip without guilt, easy to come back to.

### A.4 Three decisions for you (asked one at a time after you read this)
1. **Approve this plan?**
2. **Rendering route.** In the tests, the *painted* route (Codex's paintings given real depth, animated with shaders, plus your layered Flame) matched the art you love and ran smoothly. The full-3D comparison isn't built yet. **My recommendation:** build P3 on the painted route now and keep full 3D for later realms if needed. The trade-off: it skips the side-by-side 3D test that Part 9 asked for.
3. **The art decision** (P2's exit): continue AI-only (Codex + me) for P3, accepting some limits (e.g. simpler animation than a professional animator would make), or ask for quotes. My recommendation: AI-only for P3; the results so far support it.

### A.5 Timing (honest)
- **Building:** about 4–6 weeks of my work, in nine build plans, each tested in the simulator and reviewed by Codex. Your part: short check-ins and choosing art.
- **Living it:** about 6 weeks of you using it daily. The phone has to connect for that (decision 100).
- **Before you start living it:** the backup safety check (B.5) must pass.

---

## Part B — For the builders

### B.1 Rendering and architecture (from P2)
- **Route:** painted scenes as **depth reliefs** (Apple Depth Anything V2, decision 102), living shaders (water, waterfalls, wind, the Hush, light spill, restoration), with the **LayeredFlame** on **FluidBody** physics, if Mathis approves A.4 #2.
- **Code moves from `prototypes/p2-spikes/` into `app/` as a new layer**, `app/LifeGamified/Universe/`:
  - `SceneRenderer` (relief scenes);
  - `LayeredFlame` and `FluidBody`;
  - `AliveDirector`;
  - `Restoration` shading;
  - `WorldLife` (wind, creatures);
  - `Strand` (the light from the Flame).

  It's rewritten cleanly with tests where logic exists. SpikeLab stays throwaway.
- **The rule from Part 5 stands:** `Domain` decides what is true; `Universe` only draws it.

### B.2 Act I: every beat (Part 9 §4.1)

| # | Beat | Trigger (Domain, `Journey.step` + additions) | Scene | Assets | Replay |
|---|---|---|---|---|---|
| I | **The Ember → the First Words** | First launch | Sanctuary at dawn; the ember hatches the Spark; Emberspeak script (Part 3 §11); the first question | Sanctuary Stone Age painting + depth ✅; **Spark-stage layer parts** (to produce); glyphs ✅ | Book: "The First Words" |
| II | **The Lamplighter / the first Encounter** | `daysSinceBirth ≥ 1 && activeDays ≥ 1` (step 1) | The Lamplighter appears at the hearth at dawn; the first Encounter creature waits at the Sanctuary's edge (the Spark, R5: declinable) | Lamplighter ✅ (needs layer parts for blink and talk); **first Encounter creature** (to produce) | Book |
| III | **The Grove opens / the Gathering** | `activeDays ≥ 3` (step 2) | The map unveils the Grove; travel there; Nim & Ro greet; this week's Gathering (local, R8) | Grove painting + depth + lantern map ✅; Nim & Ro ✅ (layer parts to produce); map art ✅ | Map |
| IV-a | **Evolution: Spark → Flame** | `CharacterStage.earned(activeDays: 7)` | Evolution ceremony (Part 3 §3), then **naming** (optional) | **Flame-stage layers ✅**; evolution light effect (code) | Book: "The day your Flame became a Flame" |
| IV-b | **The Keepers' counsel** | step 3 (`activeDays ≥ 7`), *the next app open after IV-a* (ceremony queue) | The Lamplighter introduces the Keepers; curated counsel with sources opens | Keeper portraits ✅ (Lamplighter, Nim & Ro, Orrin) | Keepers screen |
| V | **The Book of Your Flame** | step 4 (`activeDays ≥ 10 && daysSinceBirth ≥ 7`) | The Book appears on the Sanctuary shelf; the first page is written from the record | **Book UI** (to produce) | Sanctuary shelf |
| VI | **The Forge at the hearth** | `Journey.metalEligible` (30 active days, total Depth ≥ 60) | **Orrin visits the hearth**; the forge ceremony; the Sanctuary enters the **Age of Metal** | Orrin ✅ (layer parts to produce); **Sanctuary Metal Age painting** (to produce) | Book |

**Assets to produce (Codex, AI-only, anchors as references):**
- Spark-stage layer parts;
- Lamplighter, Nim & Ro and Orrin layer parts (blink, mouth);
- one first Encounter creature (+ layers);
- the Sanctuary in the Metal Age (+ Hushed);
- the Book UI;
- the naming scene frame;
- a hearth close-up for the evening.

### B.3 Discovery without AI (R15; decision 92; Part 9 §4.2)
1. **The first question** (in the First Words): *"What would make this year feel truly alive?"* You can type freely or tap one of six safe interests:
   - *"Be closer to people I love"* (Heart);
   - *"Read again"* (Mind);
   - *"Find calm"* (Spirit);
   - *"Move a little every day"* (Body, gentle);
   - *"Make something / focus"* (Craft);
   - *"Spend time in nature"* (World);
   - plus *"I'm not sure"*.
2. **Matching:** free text is matched on-device against curated keyword lists per interest (simple and transparent).
   - **The Flame confirms:** "It sounds like *being closer to people you love*. Shall we start there?" You can choose **Yes / Something else / I'm not sure**.
   - **A goal the library can't support yet** gets an honest answer: "I can't build that one yet. Here's what's close…", and it's remembered (`Attachment`, H2) for when the AI arrives.
3. **"I'm not sure"** starts a **sampler week**: one gentle step a day from a different interest. On day 7, the Flame asks which one felt good.
4. **Learning without AI:**
   - The app remembers your stated interests, your confirmations, and what you do and return to.
   - **Suggestions change only with your confirmation.**
   - A skip never means dislike.
   - You can correct anything in Settings.
5. **The P3 Journey set** (safe, curated, sourced; R10):

| Journey | Pillar | Where it lives in P3 |
|---|---|---|
| *Lanterns for the Ones You Love* | Heart | **The Grove** (restoration) |
| *The Unread Shelf* (read again) | Mind | Sanctuary + the Library glows on the map |
| *The Clear Water* (calm) | Spirit | Sanctuary + the Stillwater glows on the map |
| *A Walk Each Day* (gentle walking habit) | Body | Sanctuary + the Highlands glow on the map |
| *The Unfinished Work* (focus) | Craft | Sanctuary + the Forge glows on the map |
| *Roots* (time in nature) | World | Sanctuary + the Wilds glow on the map |

### B.4 The pacing fix and worked examples (R2, R3; Part 9 §4.3 and §4.7)
**Pacing, from simulated lives** (`docs/plan-2.0/reference/pacing_simulation.py`, the chapter 04 engine):

| Life | Grove L1 | L2 | L3 | L4 | L5 | Flame | Blaze | Kindled |
|---|---|---|---|---|---|---|---|---|
| Heart focus (1 a day) | day 3 | 14 | 38 | 105 | 272 | 7 | 85 | 538 |
| Heart focus (2 a day) | 2 | 8 | 22 | 55 | 138 | 7 | 60 | 300 |
| Balanced (1 a day, rotating) | 15 | 87 | 279 | — | — | 7 | 113 | — |
| Balanced (3 a day) | 5 | 27 | 83 | 245 | 647 | 7 | 60 | 300 |
| Low frequency (Heart 3/week) | 5 | 31 | 99 | 292 | — | 15 | 234 | — |
| Planned rest (Heart 6/week) | 3 | 16 | 45 | 127 | 332 | 8 | 102 | 659 |
| Pause (3 weeks on, 3 off) | 3 | 14 | 63 | 231 | 649 | 7 | 185 | — |
| Comeback (10, 30 away, daily) | 3 | 45 | 71 | 138 | 305 | 7 | 118 | 571 |

**What it means for P3:**
- **Grove levels 0–3 must be at final quality**; level 4 is reachable by intensive Heart users inside six weeks (day 55 is close), so levels 4–5 exist (the painted route makes every level available).
- **A balanced or non-Heart person would see the Grove barely move.** **Fix (by default):** the **Sanctuary restores from total Depth** across all pillars, using the same six levels. On top of that, each misted realm on the map shows its own **first-light glow** as its pillar's Depth reaches level 1. Every action visibly changes something, whatever you choose.
- Evolution: only Spark → Flame happens in the slice (day 7–15). Blaze is P4+.

**Worked examples:**
1. **Undo right after a threshold.** Heart Depth 14.8 → a 0.4 action → 15.2 (level 2). The lanterns relight *visibly* at once (R3), but the grant `realm:grove:level-2` is written only when the undo window closes (chapter 06). Undo before then: the lanterns fade back, and nothing was granted.
2. **A later correction.** Level 2 was granted at Depth 15.2; a correction a week later removes 1.0 → 14.2. **The level stays** (a grant); progress *inside* level 2 restarts from its floor (15) and shows 0%. The next actions build on from there.
3. **Catalog change.** Thresholds move from v1 to v2 (say L2 = 18). Old grants stand; your restoration keeps the version your realm started with until you've passed the next level under v1 (R2: never moves an old road).
4. **The daily cap.** The 1% Ascent ceiling is reached at 11:00. Later actions still send light (the world restores from Depth, which isn't capped). Height shows **"light stored"** instead of a fake rise.
5. **A multi-pillar action** (a walk with a friend: Body 0.5, Heart 0.5): two strands leave the Flame, one to the Sanctuary/Highlands glow and one to the Grove.
6. **A rest day** on a Journey: the campfire scene in the evening; Vitality is credited at day close; no fake action, no strand.
7. **A replanned Journey:** waypoints have stable IDs; shortening the plan moves only the waypoints ahead; completed ones stay lit.
8. **Full restoration** (Grove level 5): actions still send light; lanterns brighten briefly and Nim & Ro react; no score is invented.

### B.5 Safety and recoverability gates (Part 9 §4.4, §4.5)
- **The allowed-content table** is written per template before that Journey is usable. Each template sets its limits, adaptation rules, stop/skip alternatives and referral wording; Encounters and Gatherings are checked the same way (R10). *A Walk Each Day* is capped at a gentle ramp from WHO activity guidance, with no running or intensity targets.
- **The backup gate (R11), before Mathis lives P3:**
  - export → import round trip in a throwaway install (growth, grants, the Flame's name, settings, Journey revisions, witnessed scenes);
  - a documented re-sign procedure;
  - a restorable copy kept before any migration.

  The current app's record is migrated to the new schema with a tested migration.

### B.6 Character states, ceremonies and replay (Part 9 §4.6)
- **Stages in P3:** Spark (layer set to produce) and Flame (done), sharing one rig contract (part names, pivots, the FluidBody hookup). The Spark has no arms: it catches light with its whole body.
- **Ceremony priority** (one per app open, the rest queued):
  1. the Return;
  2. Evolution;
  3. the Forge;
  4. story beats (I–V);
  5. level-ups.
- **Every ceremony is skippable** after 2 s. Witnessing (`momentWitnessed`) is written when it's seen *or* skipped. **Owning a reward never depends on seeing its animation**: grants come from the engine.
- **A crash mid-ceremony** replays it on the next open (not yet witnessed). Everything is replayable from the Book.
- **Naming is optional,** at most one prompt; it can be done later from the Flame's screen.

### B.7 Accessible routes and the Simple view (Part 9 §4.8, R7)
- Every essential task is **within 2 taps of the Sanctuary**, with labels: complete, undo, correct a past day, backup/export/import, settings, change or pause a Journey, a free action.
- **Simple view:** a plain list with a small animated Flame, the same actions.
- **Quick tap and hold** both complete.
- Glyphs are decorative to VoiceOver.
- Tested with VoiceOver, the largest text size and Reduce Motion **during** P3.

### B.8 The build plans (each written, approved, built with tests, simulator-checked, Codex-reviewed)

**Reordered by decision 105:** first the **app shell**: intro → home (cockpit) → road-style world map → enter a world (the Flame inside, spots to explore) → back. It's built as a full-screen shell in SpikeLab for fast iteration on feel, shown to Mathis, then moved into the real app. The table's plans 1, 3, 4 and 5 are delivered through that shell; plans 2 and 6–9 follow.

| # | Build plan | Contents |
|---|---|---|
| 1 | **Universe layer** | Port and harden from SpikeLab: SceneRenderer (relief, painted scenes), FluidBody, LayeredFlame (rig contract), AliveDirector, WorldLife, Strand; tests for FluidBody and the idle picker |
| 2 | **Domain additions** | `Restoration` (levels from Depth + grants, versioned thresholds), `Realm`, `StoryBeat`, `CeremonyQueue`, Sanctuary-from-total-Depth, map first-light; worked examples B.4 as tests |
| 3 | **Birth and the First Words** | The hatching, the Emberspeak script, the first question, discovery (B.3) |
| 4 | **The Sanctuary home** | In-world calls, the tracking moment with strands, Sanctuary restoration, Evening at the Hearth, the Hush and the Return, the Simple view |
| 5 | **The Grove** | Grove scene + restoration, travel from the map, Nim & Ro, the Gathering (local) |
| 6 | **Journeys catalog** | The six safe templates with limits (B.5), Journey roads and waypoints, the sampler week |
| 7 | **Act I and ceremonies** | Beats I–VI, evolution and naming, the Forge and the Metal Age, replay |
| 8 | **Book, Keepers, settings** | The Book of Your Flame, curated counsel with sources, settings, backup/import, accessibility pass |
| 9 | **Sound v1** | Synthesized/placeholder fire, ambience per scene, the Flame's babble, ceremony stingers (free sources only, licenses logged) |

### B.9 Exit criteria (P3 is done when)
1. Mathis has lived Act I on his iPhone (about 6 weeks) and says the feel is right, and R9's reflections are positive.
2. The integration and depth bar (Part 4 §10) is met in the Sanctuary and the Grove on device recordings.
3. 60 fps on the iPhone 15 with the P2 measurement protocol (full and reduced).
4. Codex review clean; all tests pass; the backup gate passed; the accessibility pass is done.
