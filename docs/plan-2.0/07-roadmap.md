# Plan 2.0 · Part 7 — The Roadmap

*From the foundation to a universe, phase by phase, each with a clear finish line.*

**Status:** draft · **Written:** 2026-10-01 · **Rule:** nothing gets built before its phase plan is approved by Mathis (session 3 rule)

---

## The phases at a glance

| Phase | Name | Goal | Finish line (in one sentence) |
|---|---|---|---|
| **P0** | Foundation | The truth underneath | ✅ Done: engine, record, living slices, 67 tests |
| **P1** | Plan 2.0 + decisions | Everything planned, nothing guessed | Mathis approves Parts 1–8 and the open decisions |
| **P2** | Spikes + final designs | Prove the tech; lock the look | S1–S3 pass on the iPhone 15; the Flame and the Sanctuary are designed and approved |
| **P3** | **Vertical slice: "The Waking"** | One perfect, fully blended piece of the universe | Mathis lives Act I for 6 weeks and says "this is it" |
| **P4** | MVP: "The First Beacons" | The universe on Mathis's phone (decision 88: no paid program yet) | Mathis lives Act I into Act II for 6–8 weeks; friends try it **on his phone**; success criteria met (chapter 23 §A.5) |
| **P5** | V1: public launch | The Emberlands open to the world | Join the $99 program → iCloud sync, cloud AI, a short TestFlight round on other iPhones → App Store release with the Sanctuary + 3–4 realms, Gatherings, Seasons |
| **P6+** | Realm releases and Acts II–IV | A universe that grows for years | A new realm or season roughly every quarter; Acts III–IV with community |

---

## P1 · Plan 2.0 + decisions (now)
- Mathis reads Parts 1–8 and answers the **open decisions** (Part 0 §4).
- Claude rewrites chapters 03, 05, 12, 23 and 28 around the universe (Part 8).
- Codex reviews Parts 1, 5 and 7 for consistency and feasibility.
- **Finish line:** a decisions-log entry "Plan 2.0 approved", with any changes made.

## P2 · Spikes + final designs (about 2–4 weeks)
| Track | Work | Who |
|---|---|---|
| Tech | S1 character, S2 diorama, S3 restoration in RealityKit on the iPhone 15 (Part 5 §B.7) | Claude, then Codex review |
| Design | Codex concept rounds: the Flame (all stages), the Lamplighter, Nim & Ro, the Sanctuary, the Grove, the world map, the UI kit; Mathis picks | Codex, Mathis |
| Production | **AI-only for now (decision 87):** Codex concepts + free placeholder 3D. No freelancers, no spend. The art budget is revisited after the spikes, with real quotes | Claude, Codex |
| Safety | Decision 70's blocking safety fixes in chapter 07 (combined prescription validator, safety outcome matrix, referral texts) drafted; a qualified reviewer found | Claude, Mathis |

**Finish line:** spikes pass (or the fallback engine is chosen); the Flame and the Sanctuary designs are approved; **Mathis takes the art-budget decision** (decision 87), because P3 at final quality needs it.

## P3 · Vertical slice: "The Waking" (about 6–10 weeks)
**Scope (everything at final quality, nothing more):**
- **Your Flame** (final 3D): Spark and Flame stages, ~12 animations, moods, naming at week 1.
- **The Sanctuary** (final): Age of Stone, the hearth, keepsake shelf, day/night, the Hush at the edges, Evening at the Hearth.
- **The Lamplighter**: Act I story beats.
- **The world map** (final style) with the Grove open at step III and the other realms misted.
- **The Whispering Grove** (final): restoration levels 0–3, Nim & Ro, the Gathering (local count until the Relay).
- **One full Journey** as a quest line: *Lanterns for the Ones You Love* (Heart; safe, no health content).
- Today's calls in-world, the tracking moment in-world, the Return, the evolution ceremony (Spark → Flame), the Book of Your Flame (Act I).
- Music: the Sanctuary theme, the Grove theme. Sound design: the Flame's voice, the core UI.

**Out of scope:** other realms (misted), health Journeys, the Companion AI, sync, social.
**Finish line:** Mathis uses it daily for Act I (~6 weeks) and approves the feel; Codex review clean; 60 fps on the iPhone 15.

## P4 · MVP: "The First Beacons" (about 2–3 months)
- **Realms:** + the Ascent Highlands (Body) and the Stillwater (Spirit), with Brakka and Ilo.
- **Journeys:** + *The Road to the First Summit* (requires the health safety work and the qualified review) and *The Clear Water*.
- **The Flame:** + the Blaze stage design (reached later in the beta), pillar shaping v1.
- **The Forge ceremony** → the Age of Metal.
- **Infrastructure without the $99 program (decision 88):** the record stays on the phone, protected by iPhone iCloud Backup and the in-app export; the Keepers' counsel is **curated content with sources** (no AI yet: the iPhone 15 has no on-device model); the AI layer is built behind a switch and tested later; all realms ship inside the app (no downloads yet); the Gathering is local. The app is re-signed every 7 days from the Mac (free signing).
- **Finish line:** chapter 23 §A.5 success criteria, lived by Mathis, with friends trying it on his phone.

## P5 · V1: public launch (about 3–4 months)
- **Join the Apple Developer Program ($99/yr)** first, then turn on what it unlocks: iCloud sync (CloudKit), Apple's cloud AI (Private Cloud Compute) for the Keepers, realm downloads, the Relay for real Gathering counts.
- **A short TestFlight round (2–3 weeks, a handful of people, other iPhone models):** the app will only ever have run on one iPhone 15, so this catches crashes and slow devices before the public sees them.
- 3–4 realms at release (+ the Library or Forge), Seasons system (the first season), keepsake system complete, accessibility pass, localization (decided in P1), privacy policy, App Store presence, security review.
- **Finish line:** App Store release.

## P6+ · The growing universe (years)
| Rhythm | Content |
|---|---|
| Every season | A Season chapter, a seasonal Gathering, seasonal keepsakes |
| About every quarter | A **realm release** (the remaining realms), new Journeys, new Encounters |
| Year 1 → 2 | Act II completion (all six Beacons), the Kindled stage, **Act III: the Grey Sea** with community features (other travellers' lights, letters, shared Journeys) |
| Year 2+ | Act IV: Beyond the Veil; Android (decision 28); partner Journeys (Strava-verified, decision 3) |

---

## How every phase works (the loop from chapter 22, still valid)
1. Phase plan → Mathis approves.
2. Build plans per feature (writing-plans) → Claude builds with tests → simulator checks → Codex review → fixes.
3. **On Mathis's iPhone** → done only when it *feels* right.
4. Decisions log + chapters updated.

## What could go wrong (and the plan's answers)
| Risk | Answer |
|---|---|
| RealityKit can't carry the look | Spikes first; the Unity fallback; the foundation unaffected |
| Art costs grow | Part 6's trade-offs (2.5D realms, fewer realms at V1); Mathis decides each spend |
| The world distracts from real life | World rules (Part 2 §9): light only from real actions, no in-app grinding; sessions stay short by design |
| Scope explosion | Each phase has a strict scope and a finish line; anything else waits for the next phase |
| Style keeps changing | P2 locks the look with style frames Mathis approves before any production spend |
