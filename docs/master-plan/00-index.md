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
| 03 | The Flame: Depth, Vitality, visual anatomy, milestone transformations | ⬜ | Decisions 7, 10, 12, 13 |
| 28 | **The Adventure:** the world, the journey, and real game depth (progression, discovery, mystery, meaningful choices) | ⬜ | Decision 40. Added 2026-09-30 |
| 04 | Growth model: pillars, what "1%" means, difficulty matching, evidence | ⬜ | Decisions 13–15; science research needed; settle where finances, adventure/play and home belong |
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

## Working order

**Phase A: Foundation.** 01 → 02
**Phase B: Architecture foundations** (decision 23). A first pass of 16, 17, 20 and 22 that fixes the base everything else stands on:
- platform and tech stack;
- managed backend;
- the core data backbone (a permanent, append-only history of every action, which is what makes decades of proof possible);
- identity and accounts;
- security and privacy baseline;
- the theme engine hook;
- source attribution;
- the AI layer boundary;
- how AI agents build and review the code.

These are designed against the *full* vision's requirements, which are already known well enough. Experience details can then change without reworking the foundation.

**Phase C: Experience.** 04 → 03 → 28 → 05 → 07 → 06 → 08 → 10 → 09 → 11 → 12
**Phase D: Ecosystem and business.** 14 → 15 → 13
**Phase E: MVP definition.** 23
**Phase F: Technical completion.** Finish 16–22 against the defined MVP (18, 19, 21 in full; 16, 17, 20, 22 refined).
**Phase G: Beyond.** 24 → 25 → 26 → 27

Why this order: the foundation is locked early because it's the most expensive thing to change later. It's designed against the whole vision's needs, not the MVP's, so nothing we build early blocks what comes later.
