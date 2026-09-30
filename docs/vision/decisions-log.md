# Life Gamified — Decisions Log

Running record of what we've agreed during the planning conversation. The full spec gets written from this once the vision is settled.

## Settled

| # | Decision | Date |
|---|----------|------|
| 1 | **Planning order:** vision → core loop (flame + tracking + recommendation) → growth model → reward economy → social → ecosystem → technical architecture. | 2026-09-30 |
| 2 | **v1 scope:** no brand partnerships, no full social network. | 2026-09-30 |
| 3 | **Two kinds of progress:** anything shareable or status-bearing must be verifiably completed. Self-reported progress stays private. | 2026-09-30 |
| 4 | **The app is an engine, not a list.** It learns from choices, achievements and behavior, grows non-linearly, and is different for every person. | 2026-09-30 |
| 5 | **No questionnaire onboarding.** Getting to know the user has to be close to effortless. It needs a dedicated research pass on best-in-class onboarding. | 2026-09-30 |
| 6 | **Shared challenges create community.** Everyone does the same daily/weekly challenge at the same time, which builds belonging (the Fight Club feeling). Status comes from effort within a time horizon, not from being online on the right day. | 2026-09-30 |
| 7 | **The flame evolves in depth, not size.** Its complexity and design change, and the whole app's look changes with it. The structure stays the same (Opal model). | 2026-09-30 |
| 8 | **User zero is Mathis.** The end goal is everyone who wants to feel better, be better, and be a force for good. | 2026-09-30 |
| 9 | **Shared-ritual community (Wordle principle):** the same challenge for everyone in a time window, a result you can share, and presence without a social network. The principle is borrowed; the form will be completely rebuilt for this app. | 2026-09-30 |
| 10 | **Two tiers of visual change.** Transforming the flame and the whole app is reserved for big milestones. Smaller rewards (icons, titles, banners) personalize without restyling the app. | 2026-09-30 |
| 11 | **Theme engine from day one.** The flame's state drives the whole app's look (color, material, light, sound, haptics) through one theming system. It is designed into the architecture, not added later. | 2026-09-30 |
| 12 | **The flame has two layers.** *Depth* is permanent (who you've become) and can never be lost. *Vitality* reflects recent living: it dims when you're away, never dies, and relights quickly. Users must never feel they've lost it all. | 2026-09-30 |

| 13 | **Growth model is a hybrid.** Six fixed, universal pillars: **Body, Mind, Heart** (relationships), **Spirit, Craft** (work and skills), **World** (others and the planet). The path within each pillar is fully personal and chosen by the engine. The pillars give shared challenges, comparison and the AI a common structure. Names are provisional. The pillars are likely the flame's visual anatomy (each contributes its own element/layer). | 2026-09-30 |

| 14 | **Core purpose: make invisible progress visible today.** Real growth (gym, reading, etc.) shows results only after months or years, so people quit before they see any. The app closes that gap by making each day's progress felt and seen that same day. | 2026-09-30 |
| 15 | **"1%" works in layers.** The headline is a compounding growth number that has to be earned: each action's difficulty is matched to the individual, so 1% always means real effort at *your* level. Underneath is real evidence per pillar: measured data where possible, a record of what you did where not. This makes a difficulty-matching engine a core system. | 2026-09-30 |

| 16 | **The daily loop has three layers.** (1) **Paths:** long arcs co-designed with the engine, which set the daily foundation. (2) **The Spark:** one surprise, calibrated challenge per day to push past the comfort zone. (3) **The Ritual:** the shared daily/weekly challenge. You open the app to a day that's already decided. *Default pending confirmation: one Spark swap per day.* | 2026-09-30 |
| 17 | **Never blocked. The app is both tracker and companion** (never called a "coach"). For any goal it provides the knowledge and builds the plan: nutrition guidance for eating better, a training program for working out, a night routine for sleep, a periodized plan for a sub-4 marathon. A Path = goal + generated plan + adaptive schedule that feeds each day. This is the heart of "singularity" and the main part of the app. | 2026-09-30 |

| 18 | **Trust through visible sources.** The Companion's knowledge and plans come from credible, identifiable sources, and users can always see where guidance comes from. Long term, trust is built through expert, nutrition and brand partnerships. The AI personalizes within expert frameworks and hard safety limits; sensitive areas (medical, eating, mental health) have firm boundaries and refer people to professionals. | 2026-09-30 |

| 19 | **v1 knowledge sources:** public, evidence-based sources (health authority guidelines, established training science, peer-reviewed research), always cited. Source attribution is built into the architecture from day one so expert/brand partners can plug in later without a rebuild. | 2026-09-30 |
| 20 | **Builder profile:** Mathis is solo and not a developer. The app is built entirely through AI coding agents (Claude Code and Codex). Consequences: planning and specs have to leave nothing to guess; the stack favors mainstream, well-documented tech that AI builds reliably; the backend is managed rather than self-operated; the code is built as small, well-bounded modules with automated tests; more than one AI is used (one builds, the other reviews). | 2026-09-30 |
| 21 | **Full master plan before any code.** One complete plan covering the entire vision at its most ambitious (length doesn't matter), with nothing left to guess. It includes the MVP and V1 as defined slices of that vision. The MVP is explicitly not the end product. | 2026-09-30 |
| 22 | **Master plan structure:** 27 chapters in 5 parts (see `docs/master-plan/00-index.md`), one document per chapter, with different levels of detail (MVP exact, V1 detailed, full vision as intent + principles + architectural hooks). | 2026-09-30 |
| 23 | **Architecture foundations come early.** Backend and architecture foundations must be right from the start. Right after Part I, a dedicated phase fixes the platform, stack, backend, data backbone, identity, security baseline, theme engine hook, source attribution, AI layer boundary, and the AI-agent build workflow. It is designed against the full vision's requirements, not just the MVP's. | 2026-09-30 |
| 24 | **GitHub later.** The project is a local git repository (started 2026-09-30). A private GitHub copy gets set up after the MVP is built. | 2026-09-30 |
| 25 | **Mission:** "Make everyone's growth visible, turning personal development into a lifelong game, so no one gives up before becoming who they could be." Fun and gamified, centered on personal growth over time. | 2026-09-30 |
| 26 | **Chapter 01 approved.** Vision, the promise to users, principles P1–P14 (including P5 "decide for them, never trap them," P7 "earned, not bought," P14 "the user is never the product"), what it must never be (including "not a distraction": the goal is time living well, not time in the app), ethical guardrails, and success criteria. | 2026-09-30 |
| 27 | **Chapter 02 approved.** Official vocabulary, including **Action** (the single unit of doing), **Spark swap = once a day**, and **the record** (the permanent, append-only history of every Action). | 2026-09-30 |

**Vocabulary:** the AI is **the Companion**. Never "coach."

## Open questions

- v1 cut: the smallest version that proves the core loop, sized for a solo builder working with AI.
- Which Paths the Companion must handle deeply at launch (start from Mathis's own goals).
- Business model: how the app makes money without betraying "no bullshit, no scam."
- Platform (iPhone first vs both) and weekly time available. *(Phase B)*
- Where finances, adventure/play and home fit in the pillars. *(chapter 04)*
- Can purely cosmetic, non-status items ever be sold? *(chapter 14)*
- First public audience for V1. *(chapter 24)*
- Sensitive data: health data privacy, security, app store rules.
- Onboarding design (research pass needed).
