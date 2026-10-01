# Plan 2.0 — The Universe: Overview and Reading Guide

*Start here. One page for the whole vision, then a guide to the eight parts, then what needs your decision.*

**Status:** draft for Mathis's review · **Written:** 2026-10-01 · **Origin:** decision 83 (pause building, plan the full universe before acting)

---

## 1. The vision in one page

**Your real life restores a world.**

You live: you walk, read, call your mother, sit in silence, ship your work, plant a tree. Each real thing becomes **light**. **Your Flame** is a small, warm, living fire character who is *you*. It catches that light and carries it into **the Emberlands**, a world asleep under **the Hush** (a grey mist of forgetting).

Where your light lands, the world wakes up:
- grey paths turn green;
- waterfalls flow again;
- lanterns relight;
- creatures return;
- Keepers wake and teach you.

Over days, your Flame grows bolder. Over weeks, a realm comes back to life. Over months, your Flame evolves (Spark → Flame → Blaze → Kindled) and its form takes the shape of *your* life. Over years, you light the six Beacons, cross the Grey Sea, and reach what lies Beyond the Veil.

- **Your long-term goals are Journeys:** roads through a realm with waypoints and a summit.
- **Your daily surprise is an Encounter:** a creature with a request.
- **The weekly shared challenge is the Gathering:** everyone's lights in the Grove's trees.
- **Your Chronicle is the Book of Your Flame.**

**Nothing in the world can be bought or ground in-app.** The only way to change it is to live. And when you're away, nothing dies: your Flame sleeps as an ember, the Hush settles softly, and your return relights everything.

**Underneath, nothing changes:** the growth engine (Depth, Vitality, the Ascent), the append-only record, privacy (the user holds their data), cited sources and safety. The universe is *how the truth is shown*, never a replacement for it.

---

## 2. The eight parts (reading guide)

| Part | Title | What it answers | Read time |
|---|---|---|---|
| **1** | [The Integrated Experience](01-integrated-experience.md) | How every system (Paths, the Spark, the Ritual, the Companion, tracking) becomes part of the world. A day, a week, a year in the universe. Restoration levels | 15 min |
| **2** | [The World Bible](02-world-bible.md) | The Emberlands: the Hush, the Sanctuary, the six realms and their Keepers, the Grey Sea, the four Acts, seasons, world rules | 20 min |
| **3** | [The Character Bible](03-character-bible.md) | Your Flame: personality, look, evolution stages, pillar shaping, its name, the animation list, how it speaks, the cast | 15 min |
| **4** | [Art, Sound and Feel](04-art-and-sound-direction.md) | The style (a warm, stylized 3D storybook), palettes, the Hush vs. Alive look, UI in-world, music, haptics | 8 min |
| **5** | [Technical Architecture](05-technical-architecture.md) | How to run a 3D world in a private native app: RealityKit, validated by three spikes, with Unity as the fallback | 10 min |
| **6** | [Production](06-production-plan.md) | Who makes what (AIs vs. freelance artists), rough costs, ways to spend less | 8 min |
| **7** | [Roadmap](07-roadmap.md) | Phases P1–P6+, each with a finish line: spikes → vertical slice "The Waking" → MVP → V1 → realm releases | 8 min |
| **8** | [Master-Plan Rewrites](08-master-plan-rewrites.md) | Which existing chapters stay, change or merge; new glossary; what happens to the existing code | 8 min |

**If you only have 15 minutes:** read this page, Part 1 §1–3, Part 3 §1–3, and Part 7's table.

---

## 3. Choices I made by default (decision 63; please review)

| # | Choice | Where |
|---|---|---|
| a | **Names:** the Emberlands, the Hush, the Sanctuary, the Lamplighter, the six realms and Keepers (Brakka, Quill, Nim & Ro, Ilo, Orrin, Mossbeard), the Grey Sea, the Veil. All provisional | Part 2 |
| b | **The story in four Acts:** I The Waking (≈ first 6 weeks, replaces the First Journey), II The Six Beacons (months), III The Grey Sea (year 1–2, community), IV Beyond the Veil (years) | Part 2 §7 |
| c | **Restoration levels** per realm at Depth ≥ 3 / 15 / 50 / 150 / 400 in that pillar | Part 1 §8 |
| d | **Evolution stages:** Flame at 7 active days; Blaze at 60 days + Depth 120; Kindled at 300 days + Depth 800; Beyond after years | Part 3 §3 |
| e | **Your Flame never gives advice;** the Keepers do, always with sources. Your Flame feels, cheers and remembers | Part 3 §7, Part 8 §2 |
| f | **Style:** a warm, stylized 3D storybook (*Spirited Away*'s warmth × *Ori*'s restoration × a premium animated film) | Part 4 |
| g | **Tech:** RealityKit + SwiftUI, but only if three spikes pass on your iPhone 15; otherwise Unity embedded | Part 5 |
| h | **The vertical slice:** the Sanctuary + the Grove + one Heart Journey (*Lanterns for the Ones You Love*), chosen because it needs no health safety work | Part 7 P3 |
| i | **The Ages of the Sanctuary** (Stone → Metal → Crystal → Light) carry the Eras forward | Part 2 |

---

## 4. Decisions that need you (I'll ask them one at a time)

| # | Question | My recommendation |
|---|---|---|
| **1** ✅ | **Answered: approved (decision 85),** plus the First Words (86). Original question: **approve Plan 2.0** as the direction (with any changes)? | Approve, then fix details as we live the slice |
| **2** ✅ | **Answered: AI-only for now (decision 87).** Revisit after the spikes. Original question: **art budget approach:** full 3D everywhere, **3D characters + 2.5D painted realms**, or AI-only for now? | 3D characters + 2.5D realms; V1 with 3–4 realms (Part 6 §3). Vertical slice ≈ $12k–40k with humans; or start with AI-only and decide after the spikes |
| **3** | **When to join Apple's Developer Program ($99/yr)?** It unlocks TestFlight, iCloud sync and Private Cloud Compute | At the start of P4 (the MVP for your circle). Not needed for spikes or the vertical slice |
| **4** | **The app's name.** The world is the Emberlands; the app could carry its own name or the world's | Decide after the vertical slice, when the world has a face |
| **5** | **Beta languages** (English only, or English + French)? | English first; the content catalog is translation-ready |
| **6** | **Decision 70's open items:** (a) a qualified human health reviewer before any Body Journey; (b) narrow the 8-Path launch library to the safe ones first; (c) the $99 before any PCC work (see #3); (d) the Era scope (now answered by the Ages) | (a) yes, in P4; (b) yes: Heart, Mind, Spirit, World first; (c) see #3; (d) resolved |
| **7** | **Your own goals as user zero.** Which Journeys do you want to live first? | Tell me 2–3 real goals; they shape the first Journeys we write |

---

## 5. What happens after you approve

1. Decisions logged, chapters rewritten (Part 8).
2. **P2 starts:** spikes S1–S3 on your iPhone 15, plus Codex concept rounds for the final Flame, the Lamplighter, the Sanctuary and the Grove; you pick.
3. If you agree to the budget, the first artist brief goes out (only with your yes).
4. **P3:** the vertical slice "The Waking", lived by you for ~6 weeks.
