# Master Plan — Index

The complete plan for the entire vision, with the MVP and V1 defined as slices of it. **No code is written until the chapters an MVP feature depends on are approved.**

## Levels of detail

| Horizon | Level of detail | Who it's for |
|---------|-----------------|--------------|
| **MVP** | Exact: every screen, rule and data field. Nothing left to guess. | The AI agents that build it |
| **V1** | Detailed: features, behavior and architecture are defined; the fine details get sharpened just before building. | Planning the public launch |
| **Full vision** | Intent, principles and architectural hooks, precise enough that nothing built early blocks it later. | Keeping the long-term direction |

The plan is a living document: when reality teaches us something, the relevant chapter is updated and the change is logged in [decisions-log.md](../vision/decisions-log.md).

## How each chapter gets made

1. **Align:** a conversation, one question at a time.
2. **Research** where needed.
3. **Draft:** Claude writes the chapter as `NN-name.md` in this folder.
4. **Review:** Mathis reviews it and asks for changes.
5. **Approve:** the status becomes ✅ below.

Status key: ⬜ not started · 💬 in discussion · 🔬 research · 📝 drafted, awaiting review · ✅ approved

## Chapters

### Part I — Foundation
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 01 | [Vision, mission and principles](01-vision-mission-principles.md): why, for whom, what it must never be | ✅ | Approved 2026-09-30 |
| 02 | [Glossary](02-glossary.md): Flame, Depth, Vitality, Pillars, Paths, Spark, Ritual, Companion… | ✅ | Approved 2026-09-30 |

### Part II — The Experience
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 03 | [The Flame](03-the-flame.md): Depth, Vitality, visual anatomy, milestone transformations | 📝 (defaults) | Decisions 7, 10, 12, 13 |
| 28 | [**The Adventure**](28-the-adventure.md): the world, the journey, and real game depth (progression, discovery, mystery, meaningful choices) | 📝 (defaults, MVP slice) | Decision 40. Added 2026-09-30 |
| 04 | [Growth model](04-growth-model.md): pillars, what "1%" means, difficulty matching, evidence | ✅ | Decisions 13–15; science research needed; settle where finances, adventure/play and home belong |
| 05 | The daily loop: Paths, Spark, Ritual, the shape of a day | ⬜ | Decision 16; confirm Spark swap rule |
| 06 | [The tracking moment](06-tracking-moment.md): sensory design (haptics, sound, motion, completion) | 📝 (defaults) | Decision 14; prototype needed |
| 07 | [The Companion](07-companion.md): personality, voice, knowledge, plan building, safety limits, cited sources | 📝 (defaults) | Decisions 17–19; needs Mathis's own goals |
| 08 | [The birth of your Flame](08-the-birth.md): onboarding without questionnaires | 📝 (defaults) | Decisions 5, 40: **the first launch is the birth of your Flame, the start of the adventure**; research pass needed |
| 09 | Verification: private vs. verified progress, integrations | ⬜ | Decision 3 |
| 10 | Rewards and milestones: two tiers, titles, icons, big transformations, scarcity rules | ⬜ | Decisions 6, 10; rewards psychology research needed |
| 11 | Community: the Ritual, collective presence, profiles, friends, sharing | ⬜ | Decisions 6, 9 |
| 12 | [Visual, sound and verbal identity](12-identity.md): cockpit × Dune × sanctuary | 📝 (defaults; the app name is Mathis's call) | Original brief, "Overall style" |

### Part III — Ecosystem and Business
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 13 | Partnerships and ecosystem: experts, brands, nutrition, integrations | ⬜ | Decision 18 |
| 14 | Business model: making money without betraying the purpose | ⬜ | Not yet discussed |
| 15 | Trust, privacy, safety and legal | ⬜ | Health data |

### Part IV — Technical
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 16 | [System architecture](16-system-architecture.md): app, backend, AI, data | ✅ | Decisions 20, 23. **Foundations first (Phase B).** Native iOS/Swift chosen (28) |
| 17 | [Data model](17-data-model.md) | ✅ | **Core backbone in Phase B** |
| 18 | AI systems: Companion, recommendation engine, difficulty matching, cost per user | ⬜ | |
| 19 | The theme engine | ⬜ | Decision 11 |
| 20 | [Security, privacy and compliance](20-security-privacy.md) | ✅ | **Baseline in Phase B.** Health data |
| 21 | Quality and testing strategy | ⬜ | |
| 22 | [Building with AI agents](22-build-workflow.md): the Claude Code + Codex workflow | ✅ | Decision 20. **Phase B** |

### Part VI — The Universe (the heart of the project)
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| P2.0 | [**Plan 2.0**](../plan-2.0/00-overview.md): the universe planned end to end (8 parts) | ✅ direction approved (85) | Decisions 84–92; Codex review running |
| 29 | [**The Universe**](29-the-universe.md): your personified Flame, the world map, realms, lore | 📝 (defaults) | Decisions 79–81. U1 (character v1) is built. Next: U2 character bible, U3 world bible, U4 map v1 |

### Part V — Roadmap
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 23 | [**MVP**](23-mvp.md): Mathis and a small circle on a private beta, proving the core loop | 📝 (defaults) | |
| 24 | **V1:** first public App Store release | ⬜ | |
| 25 | Beyond V1: the decade roadmap | ⬜ | |
| 26 | Success metrics | ⬜ | |
| 27 | Risks and open questions | ⬜ | |

## ▶ Where we left off: RESUME HERE (updated 2026-10-01 morning, PLAN 2.0 APPROVED as direction, decisions 84–86)

**Plan 2.0 is written:** `docs/plan-2.0/00-overview.md` (start there) plus Parts 1–8. **Building stays paused** until Mathis approves it (decision 83 rule).

**Next steps, in order:**
1. ✅ All seven Plan 2.0 questions answered (decisions 85–92).
2. ✅ Older chapters aligned: each affected chapter (01–08, 12, 16, 17, 20, 22, 23, 28, 29) now opens with a **"Plan 2.0 update" block** that overrides anything conflicting below it. The full prose rewrites of 03/05/06/07/08/23/28 happen inside the **P3 phase plan and its build plans** (that's when every detail gets pinned down for building).
3. ✅ Codex review triaged (decision 94) → **Part 9, the Phase Contract** (wins over the other parts). Style anchors approved (95). Beacons (96) and the fallback (97) answered by Mathis.
4. ▶ **P2 IN PROGRESS** (approved, decision 98; plan `docs/plan-2.0/p2-phase-plan.md`, revised after Codex's review). Blender 4.5.14 LTS installed at `/Applications/Blender.app`. **In flight:** the design round (`scripts/design-round-p2.sh`, relaunched by `resume-codex.sh`). **Next:** `prototypes/p2-spikes/PIPELINE.md` (pinned versions) → step-0 pipeline probe (Blender → USDZ → phone) → the SpikeLab app with the HUD → S1. Original gates (Part 9 §3): spikes S1–S3 (RealityKit on the iPhone 15, throwaway, in `prototypes/`, placeholder 3D only) + the design round (Codex concepts: the Flame's stages with **distinct forms, not just size**, the Lamplighter, Nim & Ro, the Sanctuary with the hearth, the Grove, Emberspeak glyphs, the UI kit). Mathis approves the P2 plan before anything is built.
5. Constraints until launch: no spend (87), no paid Apple program (88), English (90), safe Paths first (91), no predetermined goals (92).

**Any new session: read this block first and continue exactly from it.** Standing rule (decision 63) applies, with its exceptions.

### 1. State: building in living slices (decisions 72–74)
- **Real app:** `app/LifeGamified.xcodeproj` (iOS 26+, team SX845VA92A, bundle `com.mathis.lifegamified`) plus `app/Packages/Core` (`Domain`, `Storage` with GRDB; **67 tests pass**: `cd app/Packages/Core && swift test`).
- **Built and verified in the simulator:**
  - the birth (resumable);
  - Today (Codex layout);
  - Flame + Sanctuary (Vitality crossfade, Metal tint after the Forge);
  - the tracking moment;
  - Spark from day 2 with swap; Hidden Sparks;
  - weekly Ritual (step III); add Paths (step IV); Chronicle (step V); the Forge ceremony (step VI) → Metal Era;
  - Undo; Close the day; unlock moments; journey sheet;
  - fire ambience;
  - dev menu (long-press the date → time travel in a sandbox; delete everything).
- **Demo launch arguments (simulator only):** `-demoBirth`, `-demoAdvance N`, `-demoLive N`, `-demoWitness`, `-demoForged`.
- **Install on Mathis's iPhone:** open `app/LifeGamified.xcodeproj`, pick "Mathis's iPhone", press ▶. The free signing expires every 7 days.

### 2. In flight (Codex art queue restarted 2026-10-01 07:01)
- **`scripts/style-tests.sh`** (called by `scripts/resume-codex.sh`) is the Codex art queue for the cartoon universe:
  - `docs/design/character/flame-hero.png`, `flame-expressions.png`, `flame-evolution.png`: the U2 character bible, original design;
  - `docs/design/world/sanctuary-empty.png`: copy it to `app/LifeGamified/Resources/sanctuary-cartoon.png`, then set `SanctuaryView` to anchor at the bottom so the character stands on the pedestal;
  - `docs/design/world/world-map.png`: the background for `WorldMapView`, with the node positions in `WorldCatalog` matched to the painting;
  - `docs/design/world/grove-scene.png`: the image for the Grove in `LocationScene`.
- **Current app state:** the cartoon character v1b (`Experience/FlameCharacter.swift`, a placeholder until the final stylized 3D character, decision 82); the world map v1 (`Features/WorldMapView.swift`, `Content/WorldCatalog.swift`, `Domain/World.swift`); the cartoon Sanctuary (style test B, which still has a painted vessel hidden behind the cards). `PixelFlameView` and `FlameView` are unused fallbacks.

### 3. Older "next" list (superseded by Plan 2.0 Part 7; kept for reference)
- **U2 character bible** (Codex, after the usage reset): an original cartoon flame, an expression sheet, evolution stages. Mathis picks.
- **U3 world bible** + **U4 world map v1** (the Sanctuary + the Whispering Grove at step III, tap to travel, enter the scene).
- Real sound design (the current sounds are synthesized placeholders).
- The Companion slice: needs the chapter 07 safety fixes (decision 70) and the $99 program for Private Cloud Compute (Mathis's iPhone 15 has no on-device model).
- Sync (iCloud) slice.

### 4. Needs Mathis
- Live with Slice 1 on his phone; share what feels good or off.
- From decision 70: a qualified reviewer for health and safety content; keep or narrow the 8-Path library; $99 before Private Cloud Compute.
- The app's name; the beta language(s); his own goals (user zero).

## 📋 Decisions to review (made by default under decision 63; any can be reversed)

| # | Decision | Where |
|---|---|---|
| 65 | A planned rest day counts as a full day (+1%, full Vitality) | ch. 04 |
| 03-a | Every completed Action visibly adds to the vessel (a spark flies from the fire into the vessel and extends a motif) | ch. 03 §A.3 |
| 03-b | Each Flame gets a unique seed at birth, so no two vessels are alike | ch. 03 §A.3 |
| 03-c | Transformation thresholds: Metal ≈ 6 weeks (30 active days), Crystal ≈ 6 months (150), Light ≈ 2 years (500); stages 5+ unknown | ch. 03 §A.4 |
| 03-d | Your next stage shows as a veiled silhouette; nothing beyond Light is shown until someone reaches it | ch. 03 §A.4 |
| 03-e | MVP includes one earnable fire style (from the first Ritual) | ch. 03 §A.5 |
| 03-f | Flame at the center of home; touch = heartbeat haptic; press and hold = your story | ch. 03 §A.6 |
| 03-g | MVP art: Stone + Metal in full, Crystal + Light as silhouettes | ch. 03 §A.7 |
| 06-a | The tracking moment is ~1.5 s: press → charge → ignition → a spark flies into the vessel → a warm heartbeat thrum → growth ticks up | ch. 06 §A.2 |
| 06-b | Press-and-hold (¼ second) makes it a deliberate act; a quick tap still works with a lighter version | ch. 06 §A.2 |
| 06-c | Each pillar has its own sound and haptic "voice" (Body drum, Mind chime, Heart string…) | ch. 06 §A.3 |
| 06-d | No confetti or casino effects, ever; only the comeback and Transformations are allowed to be big | ch. 06 §A.5 |
| 06-e | 5-second Undo, then "This didn't happen" as a correction anytime | ch. 06 §A.6 |
| 07-a | The Companion's voice: a wise travelling companion; calm, warm, direct; practical versus ceremonial registers | ch. 07 §A.1 |
| 07-b | **Plans = a proven fixed skeleton + AI personalization inside hard limits**; the AI never invents a health or training plan from scratch | ch. 07 §A.3 |
| 07-c | The MVP Path library (running, strength, sleep, eating habits, reading, learning, relationships, meditation, gratitude, deep work, craft, money habits, nature, helping, home) | ch. 07 §A.4 |
| 07-d | No diets, calorie targets or weight-loss plans; no investment advice | ch. 07 §A.4 |
| 07-e | Fixed, human-written referral texts for warning signs; a crisis screen for self-harm, never AI-generated | ch. 07 §A.5 |
| 07-f | The MVP is for adults (18+) | ch. 07 §A.5 |
| 08-a | The birth: darkness → the myth lines → touch the ember → stone carved around your fire → a first conversation (≤4 exchanges) → first Path → optional Apple Health → **a first real Action within ~3 minutes** → home | ch. 08 §A.2 |
| 08-b | No account, no questionnaire, no upfront permissions, no feature tour; the Flame isn't named (it's you) | ch. 08 §A.3 |
| 08-c | New phone = a reunion ("Welcome back"), never a rebirth | ch. 08 §A.4 |
| 12-a | Names: growth number = **Ascent**; Transformations = **Eras** (Stone, Metal, Crystal, Light); collectibles = **Relics** | ch. 12 §A.2 |
| 12-b | Fonts: New York (ceremonial) + SF Pro (UI), both free and built into iPhone | ch. 12 §A.3 |
| 12-c | Pillar colors and Era palettes (starting hex values) | ch. 12 §A.4 |
| 12-d | Voice rules: sparse, no exclamation marks, banned guilt words (streak, fail, missed, lost…) | ch. 12 §A.6 |
| 12-e | The app icon follows your Era (alternate icons, opt-out possible) | ch. 12 §A.7 |
| 23-a | Three stages: feel prototype (free) → user zero (free) → private beta with 5–15 adults you choose (TestFlight, $99) | ch. 23 §A.2 |
| 23-b | The MVP scope list, and **8 launch Paths** (running, strength, sleep, reading, meditation, relationships, deep work, nature) plus your own goals | ch. 23 §A.3 |
| 23-c | Milestones M0–M8, each ending with something you try on your phone; roughly 2–3 months to the private beta | ch. 23 §A.4 |
| 23-d | Success: you use it daily for 30 days and love the tracking moment; ≥ 60% of testers active at week 4; zero data loss, privacy or safety incidents | ch. 23 §A.5 |
| 71 | **The First Journey:** the first ~6 weeks unfold in 6 steps (Ember → Spark → the Others → the Voice → the Chronicle → the Forge / Metal Era), unlocking the app progressively | ch. 28 §A.8 |
| ❓ | **Needs Mathis:** the app's final name (candidates: Ignis, Hearth, Sanctum, Vessel, Emberlight); the beta language(s) | ch. 12 §A.2, §A.6 |
| 28-a | The world is **your Sanctuary**: Dune-like ruins reclaimed by nature, with traces of future tech; it changes with each Transformation era and breathes with Vitality | ch. 28 §A.2 |
| 28-b | The myth paragraph: *"Every person carries a flame…"*, the seed of the app's voice (mythic, sparse, never cheesy) | ch. 28 §A.3 |
| 28-c | **Hidden Sparks**: rare challenges that appear only when a pillar is deep enough (six in the MVP) | ch. 28 §A.5 |
| 05-a | A small day: 1–3 Path Actions + 1 Spark; at most 3 active Paths in the MVP; Actions get harder, not more numerous | ch. 05 §A.1 |
| 05-b | At most one gentle notification a day (opt-in), optional 20-second "Close the day" in the evening | ch. 05 §A.2 |
| 05-c | The Ritual is weekly and a bonus: it never counts against your day | ch. 05 §A.4 |
| 05-d | **Pause** (sick, travelling): Vitality protected, no growth earned, up to 14 days per 90 | ch. 05 §A.6 |
| 05-e | Finishing a Path leaves a small permanent mark in your vessel | ch. 05 §A.5 |
| 28-d | **The weekly Chronicle**: a few mythic lines of your week, written on your phone, building a book of your life | ch. 28 §A.6 |

## Working order (updated 2026-09-30, decision 46: MVP first)

**Done:** Phase A (01, 02 ✅) · Phase B foundations (16, 17, 20, 22: Part A ✅, Part B in Codex review)

**Now: MVP planning track**
04 growth model → 03 the Flame → 28 the Adventure (MVP slice) → 05 daily loop → 06 tracking moment → 07 Companion (lean) → 08 the Flame's birth → 12 identity (MVP slice) → **23 MVP definition**

**🔔 Checkpoint when 23 is approved:** remind Mathis to install **Xcode 27** (Mac App Store, free, large) and join the **Apple Developer Program** ($99/yr, approval can take 1–2 days). Then: build plans → coding.

**After the MVP:** 09 (beyond HealthKit), 10 (full reward economy), 11, 13, 14, 15, 18/19/21 in full, 24–27.
