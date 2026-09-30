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

### Part V — Roadmap
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 23 | [**MVP**](23-mvp.md): Mathis and a small circle on a private beta, proving the core loop | 📝 (defaults) | |
| 24 | **V1:** first public App Store release | ⬜ | |
| 25 | Beyond V1: the decade roadmap | ⬜ | |
| 26 | Success metrics | ⬜ | |
| 27 | Risks and open questions | ⬜ | |

## ▶ Where we left off: RESUME HERE (updated 2026-10-01, end of Mathis's movie break)

**Any new session: read this block first and continue exactly from it.** Standing rule (decision 63): adopt Claude's recommendations by default, log them as [by default], add them to the review table below, and keep moving. Exceptions: spending money, sending anything outside, weakening trust or privacy, reversing Mathis's own decisions.

### 1. State
- Foundation approved (66). MVP-track chapters are drafted with defaults (67).
- The **M0 feel prototype** builds and runs (`prototypes/feel-v0/`, screenshots in `docs/design/prototype-v0/`).
- The **M1a plan** is written and verified (35/35 tests pass in scratch): `docs/plans/2026-10-01-m1a-growth-engine-core.md`. **It waits for Mathis's review and choice of execution method** (the writing-plans handoff). Recommended: Native.
- The Codex review of the MVP chapters is in (70). Its triage follows.

### 2. Claude fixes by default, next (from `docs/reviews/2026-10-01-codex-mvp-chapters.md`)
- **B1:** vessel motifs grow monotonically with *absolute* Depth; relative share affects emphasis only; no growth on zero-credit duplicates (chapter 03 + vectors).
- **B2:** birth identity with three states (recovered / confirmed new / cloud unknown); a provisional local birth that attaches later; one canonical `flameBorn` per dataset; idempotent onboarding commands (chapters 08, 17).
- **B3:** pause as bounded intervals with auto-end; quota from synced P events; **no reason stored in P** (privacy); pause freezes Vitality (doesn't count toward a comeback); paused slots aren't skips; extend the reference vectors (chapters 05, 04).
- **B4, B5:** one scheduler for dealing and materialization; a validator for the **final combined daily prescription**; one engine owns targets; Hidden Sparks use the same safety schema (chapters 05, 07, 28).
- **B6:** a safety outcome matrix; when screening is unknown, withhold personalized health guidance; a minimal H2 "health caution" restriction until cleared (chapter 07).
- **B9, B10, B13:** move class-aware stores, backup exclusion and journals into M1; a bundled validated catalog and seed fixture at M1/M2; curated plan acceptance at M3; `path.adapt` in M4; entry kinds `flameBorn`, `pauseStarted`/`pauseEnded`, `chronicleWritten` into chapter 17 (chapters 23, 17, 28).
- **B11:** durable success drives the landing; 900 ms is a target; Undo = a void correction (chapter 06).
- **B12 (default):** only stage 2 (Metal) is enabled in the MVP; stages 3+ are evaluated once their art ships, granted retroactively if earned, never revoked (chapters 03, 23).
- Deferrable D1–D10 go into the respective implementation plans.
- Then a **targeted Codex re-check** of the fixed chapters.

### 3. Needs Mathis (not decided by default)
1. **Review the M1a plan** and choose the execution method (Native recommended).
2. **B7/B8:** health, training and crisis texts need review by a **qualified person** before real use (cost or contacts). Also, faithful use of NHS Couch to 5K. **And:** keep all 8 launch Paths, or narrow them?
3. **B10:** Private Cloud Compute requires the **$99 Apple Developer Program** (plus the Small Business Program). Authorize when ready; until then, the Companion runs on-device only.
4. **Try the feel prototype on his iPhone** (`prototypes/feel-v0/README.md`), and answer chapter 06 §B.5.
5. The app's name, the beta language(s), and his own current goals (user zero).

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
