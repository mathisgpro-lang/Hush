# Life Gamified (working title)

A long-horizon self-growth app, built to last years and decades, and **the creation of a whole universe**. At its center is **the Flame**: a personified cartoon character (eyes, a mouth, expressions) that *is* the user and evolves over days, months and years as they genuinely grow. It lives in **an explorable world** (a map of realms and locations, lore) that opens only by living. See [docs/master-plan/29-the-universe.md](docs/master-plan/29-the-universe.md): **the heart of the project.** The app is both **tracker and Companion**: it hands you your day, builds the plan for any goal, makes each day's invisible 1% progress visible today, and turns growth into lasting, verifiable proof. The aesthetic is **cartoon / anime-like** (decision 79): warm, soft, expressive. Not photoreal, not pixel art. The ambition is millions of users and a profoundly good product.

## Current phase: P2.5 · DESIGN & FEEL on the painted 2D route in Swift (decision 112; Unity shelved). Base: prototypes/p2-spikes (SpikeLab app shell). Plan: docs/plan-2.0/10-cohesion-plan.md + p25-design-spec.md.

The foundation is built (`app/`: the growth engine, the record, living slices on Mathis's iPhone). **Nothing new gets built before it's planned and approved by Mathis** ("like we did for the first slice"). **Plan 2.0 (`docs/plan-2.0/`) is now the source of the universe**; the master-plan chapters stay the source of the mechanics, and each opens with a "Plan 2.0 update" block. World vocabulary: Plan 2.0 Part 8 §3. Until launch: no spend (87), no paid Apple program (88), English (90), safe Paths first (91), no predetermined goals (92). See the RESUME HERE block in `docs/master-plan/00-index.md`.

### Earlier phase notes

MVP-first order (decision 46): 04 → 03 → 28 → 05 → 06 → 07 → 08 → 12 → 23. *(Superseded by decision 88: Mathis joins the Apple Developer Program only when the app is basically done, at the start of P5. Remind him then. Until then, everything must work without it.)*


We are writing the **master plan** before building anything. **Do not write product code, scaffold projects or install dependencies** until the master plan chapters an MVP feature depends on are approved by Mathis. See [docs/master-plan/00-index.md](docs/master-plan/00-index.md) for chapter status and working order.

## Resume protocol: when Mathis says "work again"

**"work again"** (or "continue") means: resume everything exactly where it stopped, both Claude's work and Codex's.
1. Run `scripts/resume-codex.sh` **in the background**. It relaunches any Codex job whose outputs are missing (add new jobs to that script whenever a Codex brief is started).
2. Read the **"Where we left off: RESUME HERE"** block in `docs/master-plan/00-index.md` and continue its steps in order, without asking, under decision 63.
3. Tell Mathis in two or three lines what resumed and what's next.

At the start of **every** session (including after a restart), open `docs/master-plan/00-index.md` and follow its **"Where we left off: RESUME HERE"** block exactly: redo any in-flight work listed there, then continue with the next steps. Keep that block current whenever work pauses.

## Start every session by reading

1. [docs/master-plan/00-index.md](docs/master-plan/00-index.md): where we are and what's next
2. [docs/vision/decisions-log.md](docs/vision/decisions-log.md): every settled decision (**the source of truth**)
3. [docs/vision/conversation-log.md](docs/vision/conversation-log.md): the reasoning behind decisions, session by session
4. [docs/vision/original-brief.md](docs/vision/original-brief.md): Mathis's founding brief, verbatim (the decisions log wins where they differ)

## Who you're working with

**Mathis** is the founder and user zero: solo, **not a developer**, and building entirely with Claude Code and Codex.
- Act as a **thinking partner, not a yes-man.** Push back honestly on tensions and risks, and give a recommendation rather than a neutral list.
- **One question at a time**, preferably multiple choice with your recommended option first and its trade-offs.
- **Show documents directly in the chat** (full content, or the changed sections), not just file links. Mathis wants to do everything from the conversation.
- **Explain technical things in plain language.** Never assume coding knowledge. When a technical choice matters, say what it means for the product.
- He thinks big. Respect the ambition, and be honest about scope and sequencing.

## Working rules

- **Log every decision immediately** in `docs/vision/decisions-log.md` (numbered, dated). Move resolved items out of "Open questions."
- **Add a session section** to `docs/vision/conversation-log.md` capturing what was discussed, what was pushed back on and what was decided.
- **Update chapter status** in `docs/master-plan/00-index.md` as chapters progress.
- Chapters are written as `docs/master-plan/NN-name.md`, following the align → research → draft → review → approve cycle.
- Use absolute dates (YYYY-MM-DD).
- Levels of detail: **MVP exact**, **V1 detailed**, **full vision** = intent + principles + architectural hooks.

## Vocabulary (use consistently)

| Term | Meaning |
|------|---------|
| **The Flame** | The user's soul as a **personified cartoon character** (decisions 79–80): eyes, mouth, moods, evolves through stages (Spark → Flame → Blaze → Kindled → Beyond). It's the center of the app. |
| **The World** | The explorable universe (chapter 29): a map of **realms** and **locations** that open only by living, with **lore** found along the way. |
| **Depth** | The permanent layer of the Flame: who you've become. It can never be lost. |
| **Vitality** | The recent layer of the Flame: how you've been living lately. It dims when you're away, never dies, and relights quickly. |
| **Pillars** | Six universal life dimensions: **Body, Mind, Heart** (relationships), **Spirit, Craft** (work and skills), **World** (others and the planet). Names are provisional. |
| **Paths** | Long arcs: a goal + a generated plan + an adaptive schedule. Personal within each pillar. |
| **The Spark** | One surprise daily challenge, matched to the user, for comfort-zone growth. |
| **The Ritual** | The shared daily/weekly challenge everyone does at once (the Wordle principle, rebuilt for this app). |
| **The Companion** | The AI that knows you, provides knowledge, builds plans and cites its sources. **Never call it a "coach."** |

## Non-negotiables

- **The app must never feel blocking.** For any goal, it provides the knowledge and builds the plan.
- **Checking something off and getting the reward are the same moment**, and it must be the part people love.
- **Anything shareable or status-bearing must be verifiably completed.** Self-reported progress stays private.
- **Trust:** guidance comes from credible, cited sources, with hard safety limits. Sensitive areas (medical, eating, mental health) refer people to professionals.
- **No manipulation, no scams.** Rewards are scarce because they took effort, not because of fear of missing out.
- **Users never feel they've lost it all.**
- **The Flame drives the whole app's look** through a theme engine designed in from day one. Full transformations happen only at big milestones.
- **Alive, always** (decision 93): the Flame is never a still picture in the app. It's rendered live everywhere, breathing, reacting to touch instantly, never visibly looping. Every scene always has motion. Concept images are sketches, never what ships.
- **The universe is the core of the project** (decision 81): the personified Flame and the world it explores. The world only moves forward when the user does in real life: no in-app grinding, no paid progress.

## Architecture foundations (Phase B, decisions 28–39)

- **Native iPhone app first, in Swift** (SwiftUI, Metal for the Flame, Core Haptics, HealthKit). Android later as a separate app, so growth rules must stay platform-neutral.
- **The user holds their data** (a core priority, decisions 29–30). Personal data lives on-device and in the user's **private iCloud** (CloudKit); the company holds nothing personal. Delegate everything possible to trusted third parties (Apple sign-in and payments, HealthKit, a zero-retention AI provider). **No account in the MVP.**
- **The record:** an append-only history of Actions; Depth, Vitality and the Flame are always *calculated* from it. Offline-first, exportable, deletable by the user.
- **The Companion's AI:** hybrid. Apple's on-device model for everyday tasks, a cloud AI (provider-neutral) for heavy thinking, through a pass-through server that stores nothing.
- **Theme engine:** nothing hard-codes its look; everything flows from the Flame's state. The Flame = artist-made pieces assembled live.
- **Analytics:** none in the MVP; later only opt-in, anonymous, privacy-preserving.

## Who does what (decisions 39, 62)

- **Design work** (concept art, Flame art direction, imagery, UI mockups, icons, visual identity): **Codex, primarily.** Claude writes the brief from the approved chapter and shows Mathis the result in chat. Save images under `docs/design/`.
- **Codex CLI:** `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex exec` (`-s read-only` for reviews, `-s workspace-write` for image generation). Save review reports in `docs/reviews/`.
- **Specs, planning, building:** Claude Code. **Independent review:** Codex.

## Build workflow (when building starts)

approved chapter → build plan → Claude Code builds with automated tests → runs in the iOS Simulator and checks screenshots → Codex reviews independently → fixes → **Mathis tries it on his iPhone (TestFlight)** → done only when it *feels* right. Mathis has 1–2 hours a day. Prefer well-documented tech that AI agents build reliably, and small, well-bounded modules; Mathis can't read code, so the code must prove itself.
