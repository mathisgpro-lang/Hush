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
| 28 | **The Adventure:** the world, the journey, and real game depth (progression, discovery, mystery, meaningful choices) | ⬜ | Decision 40. Added 2026-09-30 |
| 04 | [Growth model](04-growth-model.md): pillars, what "1%" means, difficulty matching, evidence | ✅ A / 🔎 B | Decisions 13–15; science research needed; settle where finances, adventure/play and home belong |
| 05 | The daily loop: Paths, Spark, Ritual, the shape of a day | ⬜ | Decision 16; confirm Spark swap rule |
| 06 | The tracking moment: sensory design (haptics, sound, motion, completion) | ⬜ | Decision 14; prototype needed |
| 07 | The Companion: personality, voice, knowledge, plan building, safety limits, cited sources | ⬜ | Decisions 17–19; needs Mathis's own goals |
| 08 | Getting to know you: onboarding without questionnaires | ⬜ | Decisions 5, 40: **the first launch is the birth of your Flame, the start of the adventure**; research pass needed |
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
| 16 | [System architecture](16-system-architecture.md): app, backend, AI, data | 📝 | Decisions 20, 23. **Foundations first (Phase B).** Native iOS/Swift chosen (28) |
| 17 | [Data model](17-data-model.md) | 📝 | **Core backbone in Phase B** |
| 18 | AI systems: Companion, recommendation engine, difficulty matching, cost per user | ⬜ | |
| 19 | The theme engine | ⬜ | Decision 11 |
| 20 | [Security, privacy and compliance](20-security-privacy.md) | 📝 | **Baseline in Phase B.** Health data |
| 21 | Quality and testing strategy | ⬜ | |
| 22 | [Building with AI agents](22-build-workflow.md): the Claude Code + Codex workflow | 📝 | Decision 20. **Phase B** |

### Part V — Roadmap
| # | Chapter | Status | Notes |
|---|---------|--------|-------|
| 23 | **MVP:** Mathis and a small circle on a private beta, proving the core loop | ⬜ | |
| 24 | **V1:** first public App Store release | ⬜ | |
| 25 | Beyond V1: the decade roadmap | ⬜ | |
| 26 | Success metrics | ⬜ | |
| 27 | Risks and open questions | ⬜ | |

## ▶ Where we left off (2026-09-30, end of session 1)

**Mathis's to-dos (whenever convenient):**
1. Accept the Xcode license: in Terminal, `sudo xcodebuild -license accept`, then open Xcode once and let it install its components (iOS 27 platform and simulator).
2. *(Optional, can wait)* Enroll in the Apple Developer Program ($99/yr). It's needed to send the health question to App Review (draft ready: `docs/vision/app-review-question-health.md`) and later for TestFlight. **Not** needed for the free feel prototype on his own iPhone.

**Waiting for Mathis's answer (next session):**
- Chapter 03, question 1: where the pillars show up in the Flame (A vessel / B fire / C both, split by time; recommendation C). Codex renders are in `docs/design/flame-pillars/`.
- Confirm: a planned rest day counts as a full day (+1%, full Vitality).
- Codex round-4 (final) review outcome: `docs/reviews/2026-09-30-codex-r4.md` plus Claude's summary. Only blocking design-level items need Mathis.

**Next up after that:** finish chapter 03 → **feel prototype on Mathis's iPhone (free, Xcode + cable)** → chapters 28, 05, 06, 07, 08, 12 → 23 (MVP) → build.

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

## Working order (updated 2026-09-30, decision 46: MVP first)

**Done:** Phase A (01, 02 ✅) · Phase B foundations (16, 17, 20, 22: Part A ✅, Part B in Codex review)

**Now: MVP planning track**
04 growth model → 03 the Flame → 28 the Adventure (MVP slice) → 05 daily loop → 06 tracking moment → 07 Companion (lean) → 08 the Flame's birth → 12 identity (MVP slice) → **23 MVP definition**

**🔔 Checkpoint when 23 is approved:** remind Mathis to install **Xcode 27** (Mac App Store, free, large) and join the **Apple Developer Program** ($99/yr, approval can take 1–2 days). Then: build plans → coding.

**After the MVP:** 09 (beyond HealthKit), 10 (full reward economy), 11, 13, 14, 15, 18/19/21 in full, 24–27.
