# Plan 2.0 · Part 10 — The Cohesion Plan: One Experience

*From good foundations that feel assembled to one experience that feels made as a whole: the art, the Flame, the tasks, the movement, the sound, the words, and a tutorial that takes you by the hand.*

**Status:** draft for Mathis's approval · **Written:** 2026-10-01 · **Origin:** decisions 105–106 and Mathis's feedback after trying the shell on his iPhone
**Replaces in order:** P3 build work pauses until this phase ("P2.5 · Design & Feel") is done. P3's scope stays; it's then built *to this spec*.

---

## 1. Where we are: an honest inventory

### What's good and stays (the foundations)
| Foundation | State |
|---|---|
| **The growth engine and record** (Depth, Vitality, pillars, the append-only history) | ✅ Built and tested (67 tests); the truth underneath everything |
| **The universe** (Plan 2.0: the Emberlands, the Hush, six realms, Keepers, Acts, seasons, world rules) | ✅ Planned and approved |
| **The personified Flame** (personality, stages, the First Words, alive-always rules) | ✅ Designed; a living layered Flame works on real physics |
| **Worlds you unlock by living** | ✅ A road map, realms that open by effort, restoration you can see (the Grove relights lantern by lantern) |
| **Actions on six pillars** | ✅ Defined; they send light into the world |
| **The art you love** | ✅ The Sanctuary in the Age of Stone, the world map, the Grove, the First Words frame, the UI kit, the cast |
| **The app shell** | 🔶 The structure exists (intro → home → map → a world → back), but it **feels assembled** |

### What's missing (your words, and what's behind them)
1. **Cohesion.** The Flame, the worlds, the tasks and the UI were each made separately and put side by side. Nothing tells you they belong to one place.
2. **The tasks aren't part of the world.** They're cards on top of it.
3. **It's hard to grasp what the app is about.** There's no guided first session; the intro is long reading, then you're left alone.
4. **The movement is generic.** Screens switch; they don't flow.
5. **It isn't yet high-end:** placeholder icons and fonts, no sound, basic interactions.

---

## 2. What "cohesion" means for this app: ten principles

Every screen, asset and interaction is checked against these. A new element that breaks one doesn't ship.

| # | Principle | In practice |
|---|---|---|
| **C1** | **One artist** | The Flame, the worlds, the UI, the icons and the characters come from **one style bible** made from one chosen style frame (§4). Nothing is generated "on its own" |
| **C2** | **One light** | Each scene's light (dusk gold, night blue, the Hush grey) colors *everything*: the Flame, the UI glows, the particles. The Flame is always the warmest light, and it lights what's near it |
| **C3** | **One place** | There are no "screens". The Sanctuary is a place on the map; the map is the world seen from above; a realm is the map seen up close. Every move is a camera move (§6) |
| **C4** | **Everything is of the world** | Tasks are **objects in the world** (a lantern, a page, a stone…), not cards. Menus are things (the Book is a book on a shelf, the map is the horizon). UI panels look like parchment and ember-glass, never like iOS defaults |
| **C5** | **The Flame is the guide** | It presents your tasks, explains new things the first time they appear, reacts to everything you do, and is how the app talks to you. There's no separate "system voice" |
| **C6** | **One gesture language** | *Hold* gives light (completing anything), *tap* looks closer, *swipe* travels, *pinch out* rises to the map. The same gesture means the same thing everywhere |
| **C7** | **One sound world** | Every interaction has a sound in the scene's musical key; music adapts to the place, the time of day and the Hush. Silence is used on purpose |
| **C8** | **One voice** | Short, warm, never more than two lines at a time; the Flame's voice, the Keepers' voices, the lore's voice (chapter 12 rules) |
| **C9** | **One rhythm** | All motion uses a small set of timing and spring "tokens" (§8), so everything moves with the same personality: soft, weighty, alive |
| **C10** | **Nothing unexplained** | The first time anything appears, the Flame introduces it, in the moment, by doing (§5). Nothing important is hidden behind a menu |

---

## 3. Tasks become part of the world

### 3.1 Each pillar has an object in the world (no more cards)
| Pillar | The task appears as… | Completing it (hold) | Where the light goes |
|---|---|---|---|
| **Heart** | An **unlit lantern** your Flame carries to you | You pour light in; it glows and floats away | The Whispering Grove (a lantern relights in its trees) |
| **Mind** | A **blank glowing page** | The words write themselves in light | The Library of Embers |
| **Body** | A **footprint path** of dull stones | They light up one by one under your finger | The Ascent Highlands |
| **Spirit** | A **still bowl of water** with a candle | The ripple calms and the candle catches | The Stillwater |
| **Craft** | A **cold ember on a little anvil** | It heats from grey to gold | Forge Mountain |
| **World** | A **seed** in a stone pot | It sprouts and blooms | The Wilds |

- **Today's tasks sit around your Flame on the stone circle** as these objects (3 at most), softly lit, gently moving. Your Flame glances at the next one.
- **Tap an object:** the camera leans in, and a parchment unfolds from the object with what to do (one or two lines, plus the source when there's guidance: "Based on: WHO 2020").
- **Did it in real life? Hold the object** (about 1 s, the chapter 06 tracking moment):
  1. a rising haptic and sound;
  2. light flows from your finger into it;
  3. it ignites;
  4. your Flame cheers and catches the light;
  5. it flies **toward its realm on the horizon**, and a far point of light flares there.
- **The day's progress is shown in the world, not as a number:** the circle's runes glow one by one; at the end of the day, Evening at the Hearth gathers them.

### 3.2 Journeys, Encounters and the Gathering as world objects
- **A Journey** is a road in its realm with waypoints. Today's step is the object at your circle; the road shows on the map.
- **An Encounter** (the daily Spark) is a **creature that arrives** at the Sanctuary's edge with its request. You can accept, or wave goodbye (R5).
- **The Gathering** (weekly) happens at the Grove's stone circle; a glowing invitation appears on the map.

### 3.3 One interaction for "doing"
Hold to give light, everywhere. Tap only looks closer or opens. Undo is always available: a fading light trail you can tap within a few seconds (chapter 06).

---

## 4. Art direction for cohesion

### 4.1 The cohesion test (running now)
Codex generates the Flame **inside** the Sanctuary in one image, four ways:
- **B** — the Flame painted in the world's painterly style;
- **D** — the Flame as a luminous spirit of light inside the painting;
- **C** — both as a hand-painted classic animated film;
- **A** — both as a soft 3D diorama (for comparison only).

Mathis picks one (or a mix). **That frame becomes the root of everything.**

### 4.2 The style bible v2 (made from the chosen frame)
- **Palette tokens:** dusk gold, ember orange, Hush grey-blue, night indigo, and realm accents, with exact values.
- **Rendering rules:** brushwork, edge softness, detail density (less over-detail: one clear focal point per scene, so it reads like a game, not a poster), shadow and glow rules.
- **The Flame in scenes:** scale (about 1/6 of the screen height at home), rim light from the scene, ground light, reflection rules.
- **UI materials:** ember-glass panels, parchment, carved stone; **custom icons** in the same brushwork (no SF Symbols); a **free display font** with character (e.g. *Cormorant* or *Fraunces*, Google Fonts) plus a clean reading font.
- **Asset recipes:** how every future image is generated (always with the style frame and palette as references), so new realms automatically match.

### 4.3 Re-making the existing art to match
Once the frame is chosen:
1. The Flame's layered parts are regenerated in that style.
2. The Sanctuary, the map and the Grove are re-touched or regenerated toward the frame (less "too good", more readable).
3. The UI kit is redone as world materials.
4. The task objects (§3.1) are designed.

---

## 5. The tutorial: "The First Minutes" (taken by the hand)

**Principles:** do, don't read · at most two short lines at a time · the Flame shows, you act · total about **90 seconds** · everything else is taught just in time over the first week.

### 5.1 Storyboard (each beat: what you see → what you do → what you feel)
| # | Beat | You see | You do | Time |
|---|---|---|---|---|
| 1 | **The ember** | Darkness, wind, one pulsing ember. One line: *"Every person carries a flame."* | Touch and hold. The haptic heartbeat rises, the ember brightens, and light cracks out | 6 s |
| 2 | **The hatching** | A burst of light; the Sanctuary dawns around a tiny Spark on the circle | Watch | 4 s |
| 3 | **Hello** | The Spark blinks, finds you, babbles in Emberspeak. Line: *"…Oh. There you are. I'm your Flame."* | Tap the Flame. It giggles: you learn the Flame reacts to you | 6 s |
| 4 | **Your first light** | The Flame brings a small object: a candle bowl (Spirit). *"Light is what I'm made of. Let's make some."* Parchment: "Three slow breaths." | Do it for real, then **hold the bowl**: you learn *hold = give light*. The light flies into the Flame, and it grows a little brighter | 20 s |
| 5 | **What matters to you** | The Flame looks at you: *"What would make this year feel alive?"* Six interest stones appear around the circle | Tap one (or "not sure"). The Flame takes it: *"Then we start there."* | 10 s |
| 6 | **The horizon** | The camera **rises** from the Sanctuary, and the Emberlands appear below: misted, grey, with one realm (your interest's) glimmering | You learn *pinch / World = rise to the map*. The Flame, small on the map: *"Out there, the world went quiet. We'll wake it, one light at a time."* | 15 s |
| 7 | **Back home** | The camera dives back to the circle. Your first task object waits there | You learn where your tasks live | 6 s |
| 8 | **The promise** | *"Come back tomorrow. I'll have something for you."* The Flame yawns, content | Free to explore | — |

**Total ≈ 70–90 s.** The longer lore of the First Words (the Hush, the Beacons, "a tool, not a cage") is **spread over Act I** (days 1–7) as short moments, so nothing is lost.

### 5.2 Just-in-time teaching (days 1–7)
| When | The Flame teaches |
|---|---|
| First time the map opens on its own | How to travel (tap a realm, the road, the zoom) |
| First Encounter (day 2) | Creatures can ask things; you can say no |
| The Grove opens (day 3) | Exploring a world (glowing spots, going back) |
| First evening | Evening at the Hearth (the day's light settles) |
| First absence | The Hush, and the Return ("nothing was lost") |
| Day 7, evolution | Stages; naming |
| Day 10 | The Book |

- **Coach marks are diegetic:** the Flame points, looks or walks toward the thing. A soft glow pulses on the target. No grey overlays with arrows.
- **Replay:** "Show me around again" in Settings.

---

## 6. Navigation: one continuous world

| Move | Gesture or button | What the camera does |
|---|---|---|
| Home → World map | Pinch out, or the horizon button | Rises straight up from the Sanctuary; clouds pass; the Sanctuary becomes its island on the map. **The same place, seen higher** |
| World map → a realm | Tap the realm | Your Flame walks the road (the camera follows); at the realm, the camera **dives** through a cloud or light layer into the realm scene |
| Realm → a spot | Tap a glowing spot | Glides and leans toward it (as now, refined) |
| Realm → map / home | Pinch out, or back | Reverse: rises out of the realm through the cloud layer |

**Technical recipe:** each transition is a choreographed camera move plus a **masking layer** (drifting clouds, a light bloom, falling leaves in the Grove). The switch between painted scenes happens behind the mask, so it reads as one continuous flight. This is the standard technique in high-end mobile games.

**Always visible "where to go":**
- a soft light trail on the road toward anything new;
- the target realm glimmers on the horizon from home;
- one small ember counter of tasks left today;
- no red badges.

---

## 7. Sound (high-end needs it)

| Layer | Content | Free source |
|---|---|---|
| Ambience per place | Sanctuary: sea, wind, distant falls, braziers. Grove: leaves, chimes, night insects. Map: high wind | freesound.org (CC0), Sonniss GDC free bundles, Pixabay sound effects |
| Music | A gentle main motif (piano, strings, soft choir), variations per realm and for the Hush | CC0/royalty-free libraries (Pixabay Music, freesound); later a composer (paid, optional) |
| The Flame's voice | Emberspeak babble: short pitched syllables, giggles, hums | Synthesized and processed from CC0 voice samples |
| Interaction sounds | The hold (rising tone), ignition, the light flying, the Flame catching it, the camera rising (wind swell), task objects (each pillar has its own timbre) | CC0 libraries + synthesis |
| Rules | Respect the silent switch; mixed so music ducks under the Flame and the tracking moment; every sound tagged with its license | — |

---

## 8. Motion, haptics, and the feel tokens

- **Springs:** `soft` (UI, response 0.5 s, gentle bounce), `weighty` (Flame and objects, more mass), `snappy` (taps, 0.25 s). Nothing linear; nothing faster than 0.15 s, and no camera move slower than 1.2 s.
- **Easing for cameras:** a slow start, a gentle overshoot-free stop (cinematic).
- **Haptics (Core Haptics patterns):**
  - the heartbeat (touching the Flame);
  - the rising charge (the hold);
  - ignition;
  - landing;
  - the rise (camera to the map);
  - an arrival "thump" in a realm.
- **Never block:** any animation can be skipped by tapping; ceremonies queue (B.6 of the P3 plan).

---

## 9. Free third-party resources to bring in

| Need | Free resource | Notes |
|---|---|---|
| **Art generation** | Codex (current plan), **Google Gemini** (AI Studio key, free tier; image limits to verify), Microsoft Designer / Bing Image Creator (free) | Mathis creates the accounts; keys are stored in the Mac's Keychain, never in chat |
| **Character animation, premium-app style** | **Rive** (free plan; the tool Duolingo uses for its characters; open-source iOS runtime) | Best path to Duolingo-grade character animation. The editor is a visual tool, so animating there well needs a human hand: you, a learner, or later a freelancer. AI can prepare the parts and the state-machine design. Evaluate first |
| **UI micro-animations** | **Lottie / LottieFiles** (free animations + open-source player) | For small UI touches (sparkles, check marks), restyled to our palette |
| **Fonts** | Google Fonts (Cormorant, Fraunces, EB Garamond, Inter) | Free for commercial use |
| **Sound** | freesound.org (CC0 filter), Pixabay audio, Sonniss free GDC bundles | Licenses logged in `docs/design/sound/LICENSES.md` |
| **Depth and layering** | Apple Depth Anything V2 (already in use) | Local, free |
| **3D** | Blender (installed) | For later 3D needs |
| **Feedback** | Friends trying it on your phone; free usability-test scripts | Free |
| **Independent review** | Codex | As now |

**Free-only rule:** anything with a cost is listed and decided by Mathis (decision 87).

---

## 10. The high-end quality bar (commercial-grade checklist)

A screen or flow is "done" only when:
1. It follows C1–C10.
2. **No placeholder anything:** no SF Symbols, no system fonts as display type, no grey default sheets.
3. Every interaction has **animation + haptic + sound**.
4. **No screen switch without choreography** (§6).
5. At most **two lines of text** on screen at once (except the Book and counsel).
6. **First-time explanation** exists, given by the Flame.
7. 60 fps on the iPhone 15; no visible loading (prepared during transitions).
8. Mathis tries it on his phone and says it *feels* right; a friend understands it without help.

---

## 11. The phase: P2.5 · Design & Feel (before P3 continues)

| Step | Work | Deliverable (shown in chat) | Who |
|---|---|---|---|
| **D1** | Cohesion test → **style bible v2** | 4 frames → Mathis picks → `docs/design/style-bible-v2.md` + palette, fonts, UI materials | Codex/Gemini, Claude, Mathis |
| **D2** | **Experience storyboards** | Illustrated storyboards (generated frames) for: the first minutes (§5), a normal day (§3), traveling (§6), Evening at the Hearth, the Return | Claude + image generation, Mathis reviews |
| **D3** | **Interaction, motion and sound language** | Tokens (§8), haptic patterns, a sound list with free sources picked, task objects designed (§3.1) | Claude, Codex for object art |
| **D4** | **The feel slice** | The shell rebuilt to spec, **only the first minutes + one normal day + travel to the Grove**, but at the high-end bar (§10): new style, task objects, continuous camera, the tutorial, sound | Claude builds, Codex reviews |
| **D5** | **On your phone** | You try it; we iterate until it *feels* right; one friend tries it without help | Mathis |

**Exit (definition of done):**
- D4 meets the §10 bar.
- Mathis approves the feel on his phone.
- A friend understands the app in the first two minutes without explanation.

Then **P3 resumes**: the rest of Act I, built on this spec and moved into the real app with the real record.

**Timing (honest):** D1–D3 ≈ 3–5 days (art generation is the bottleneck: Codex limits, Gemini once set up). D4 ≈ 1–2 weeks. D5 depends on iterations.

---

## 12. Risks and honest notes
- **AI-only art has a ceiling** for perfectly consistent character animation. Rive plus a human animator is the proven path if we hit it. It's free to try; a freelancer would be paid (Mathis's call).
- **Re-making art means some current images will be replaced,** even ones we like, so everything matches. The chosen frame decides.
- **Free sound and music libraries are good but generic;** custom sound design is a later, optional investment.
- **Image-generation limits** will keep pacing the art; Gemini as a second source reduces this.

## 13. Decisions for Mathis (one at a time)
1. Approve this plan and the P2.5 phase.
2. The cohesion direction (when the four frames arrive, after 17:04).
3. Whether to try Rive for the Flame's animation (a free account, yours).
4. The Gemini key (when you're ready; storage steps given in chat).
