# Life Gamified (working title)

A long-horizon self-growth app, built to last years and decades. At its center is **the Flame**, a living representation of the user's soul that deepens as they genuinely grow (like the gem in Opal). The app is both **tracker and Companion**: it hands you your day, builds the plan for any goal, makes each day's invisible 1% progress visible today, and turns growth into lasting, verifiable proof. The aesthetic is Iron Man cockpit × Dune × nature sanctuary. The ambition is millions of users and a profoundly good product.

## Current phase: PLANNING. No code yet.

We are writing the **master plan** before building anything. **Do not write product code, scaffold projects or install dependencies** until the master plan chapters an MVP feature depends on are approved by Mathis. See [docs/master-plan/00-index.md](docs/master-plan/00-index.md) for chapter status and working order.

## Start every session by reading

1. [docs/master-plan/00-index.md](docs/master-plan/00-index.md): where we are and what's next
2. [docs/vision/decisions-log.md](docs/vision/decisions-log.md): every settled decision (**the source of truth**)
3. [docs/vision/conversation-log.md](docs/vision/conversation-log.md): the reasoning behind decisions, session by session
4. [docs/vision/original-brief.md](docs/vision/original-brief.md): Mathis's founding brief, verbatim (the decisions log wins where they differ)

## Who you're working with

**Mathis** is the founder and user zero: solo, **not a developer**, and building entirely with Claude Code and Codex.
- Act as a **thinking partner, not a yes-man.** Push back honestly on tensions and risks, and give a recommendation rather than a neutral list.
- **One question at a time**, preferably multiple choice with your recommended option first and its trade-offs.
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
| **The Flame** | The user's soul; the center of the app. It evolves in **depth and complexity, never size**. |
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

## When building starts (future)

- The architecture foundations (platform, stack, backend, data backbone, security) are designed early and against the **full** vision (decision 23).
- Prefer mainstream, well-documented tech that AI agents build reliably, and a managed backend.
- Build small, well-bounded modules with automated tests; Mathis can't read the code, so the code has to prove itself.
- Two AIs: one builds, the other reviews.
