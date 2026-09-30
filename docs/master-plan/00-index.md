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
| 12 | Visual and sound identity: cockpit × Dune × sanctuary | ⬜ | Original brief, "Overall style" |

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
| 23 | **MVP:** Mathis and a small circle on a private beta, proving the core loop | ⬜ | |
| 24 | **V1:** first public App Store release | ⬜ | |
| 25 | Beyond V1: the decade roadmap | ⬜ | |
| 26 | Success metrics | ⬜ | |
| 27 | Risks and open questions | ⬜ | |

## ▶ Where we left off: RESUME HERE (updated 2026-09-30, before Mathis's macOS update / restart)

**Any new session: read this block first and continue exactly from it.** Standing rule (decision 63): adopt Claude's recommendations by default, log them as [by default], add them to the review table below, and keep moving.

### 1. Work that was in flight at shutdown (redo these first)
- **Codex jobs:** run `scripts/resume-codex.sh` in the background; it relaunches every unfinished Codex job.
- **Sanctuary concept art (Codex):** check `docs/design/sanctuary/` for `stone-era-bright.png`, `stone-era-embers.png`, `metal-era-bright.png`. If any are missing, rerun the brief in `docs/design/briefs/sanctuary.md` (in the background), then review the images and show them to Mathis (SendUserFile, render).
- **The two remaining Codex blockers** (`docs/reviews/2026-09-30-codex-r5.md`). Fix both in chapter 04 Part B **and** the reference script (`docs/master-plan/reference/growth_reference_v1.py`), add vectors, run it:
  1. **Duplicates must preserve per-pillar contributions.** Replace "highest d × edge wins" with: for each occurrence, the effective contribution **per pillar** = the max over its duplicates of `w_p × d × edge`. Adding a duplicate can then never lower any pillar. Add Codex's counterexample (Body 0.90 → 0.11) as a vector.
  2. **Comeback brightness must never drop on completion.** After partial comeback days, completing day 4 fell from 1.00 to 0.79. Fix: once a comeback completes, carry a relight floor that starts at R(3) = 1.0 and decays only through finalized days with presence below 1 (define it precisely), so a completion never lowers displayed Vitality. Add vectors for half-completed comeback days 1–3, then day 4 fully completed (≥ the previous value), and morning versus post-completion values.
  - Then run one **targeted** Codex check of those two items only (decision 60). When it passes, mark Phase B (16, 17, 20, 22) and chapter 04 Part B **approved** in the table below and in their status lines.

### 2. Next chapters (MVP track, with defaults)
06 tracking moment → 07 Companion (lean) → 08 the Flame's birth → 12 identity (MVP slice) → **23 MVP definition**. Each: draft with defaults, add to the review table, commit; send design work to Codex (decision 62). Show Mathis the Part A content in chat (memory: show content in chat).

### 3. Mathis's to-dos (outside the app)
1. **macOS update to 26.6 or later** (in progress at the time of writing) → then the App Store updates **Xcode to 27** → in Terminal, `sudo xcodebuild -license accept` → open Xcode once to install components (the iOS 27 simulator).
2. Update the iPhone to **iOS 27** (Settings → General → Software Update).
3. *(Optional)* Apple Developer Program ($99/yr): only for the App Review health question (draft: `docs/vision/app-review-question-health.md`) and TestFlight. Not needed for the free feel prototype.

### 4. After chapter 03 is settled: the feel prototype
A free, throwaway spike on Mathis's own iPhone (Xcode 27 + cable + Developer Mode): the Flame (first version), completing an Action with haptics, sound and the spark into the vessel, and the comeback. Labeled throwaway; it informs chapters 03 and 06.

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
