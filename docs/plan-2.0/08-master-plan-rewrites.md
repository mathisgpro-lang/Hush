# Plan 2.0 · Part 8 — What Changes in the Master Plan

*Plan 2.0 sits on top of the master plan. This part lists, chapter by chapter, what stays, what changes, and what gets rewritten after approval.*

**Status:** draft · **Written:** 2026-10-01
**Rule:** the master-plan chapters stay the **source of the mechanics** (numbers, rules, data). Plan 2.0 is the **source of the universe** (how those mechanics look, sound, feel and are told). Where they conflict, the decisions log decides; after Plan 2.0 is approved, the chapters below are rewritten so there's no conflict left.

---

## 1. The summary

| Chapter | Verdict | What happens |
|---|---|---|
| 01 Vision, mission, principles | **Keep, extend** | Add the universe to the vision ("a living world your real life restores") and one principle: *P-World: the world only changes because of real life* |
| 02 Glossary | **Extend** | Add the universe's terms (§3 below) |
| 03 The Flame | **Rewrite (presentation)** | Depth, Vitality and pillars stay exactly. The vessel and Eras' visuals are replaced by the character (Part 3) and the Sanctuary's Ages (Part 2) |
| 04 Growth model | **Unchanged** | It's the engine of everything. Only adds: restoration thresholds (Part 1 §8) and stage thresholds (`CharacterStage`) as *read-only views* of Depth |
| 05 Daily loop | **Rewrite (presentation)** | Same day structure; told as the morning wake, calls by the hearth, Evening at the Hearth, the Hush and the Return (Part 1 §3) |
| 06 Tracking moment | **Extend** | Same hold-to-strike and haptics; adds your Flame catching the light and carrying it to the realm (Part 1 §6) |
| 07 Companion | **Rewrite (roles)** | The Companion's knowledge, sources and safety stay. It speaks through **the Keepers** (counsel, one per realm) and **your Flame** (feelings, never advice). Decision 70's safety fixes are done here |
| 08 The birth | **Rewrite (scenes)** | Same steps (myth → ember → carving → dawn → first Path → first spark → reveal). The Spark hatches from the ember and **speaks its First Words** (Part 3 §11, decision 86): who it is, the Hush, a glimpse of what lies ahead. Then it asks the first question itself. The myth gets shorter; the Lamplighter appears later, in Act I |
| 12 Identity | **Superseded in part** | Visual and sound direction → Part 4. Voice rules (calm, no exclamation marks, no guilt) and typography stay |
| 16 System architecture | **Extend** | Add the Universe layer, RealityKit, On-Demand Resources (Part 5) |
| 17 Data model | **Small extension** | No new truth for the world. Adds: the Flame's name (an attachment), worn keepsakes and home placement (settings), story beats as `momentWitnessed` keys |
| 20 Security and privacy | **Keep** | Adds: freelancer contracts (no user data ever shared), asset downloads from Apple only |
| 22 Build workflow | **Keep, extend** | Adds the asset pipeline (Codex concept → Mathis → artist → USDZ → app → the phone) and the spike rule |
| 23 MVP | **Rewrite** | The MVP becomes Plan 2.0's P3 + P4 (Part 7): the vertical slice "The Waking", then "The First Beacons" |
| 28 The Adventure | **Merged** | The First Journey (steps I–VI) becomes **Act I: The Waking** (Part 2 §7). The logic (unlock conditions) stays in Domain |
| 29 The Universe | **Replaced by Plan 2.0** | Kept as history; it points to Plan 2.0 |

---

## 2. Details for the chapters that change most

### 03 The Flame → "Your Flame"
- **Keeps:** two layers (Depth permanent, Vitality recent); never lost; pillars shape it; it changes in depth and complexity, never size (decision 4); full transformations only at big milestones.
- **Changes:**
  - "never size" now means **the character never just gets bigger as a score**. Its stages change form, posture and markings, and each stage is a milestone ceremony;
  - the vessel moves into the Sanctuary as **the hearth** (the stone hearth's material follows the Ages: Stone → Metal → Crystal → Light);
  - the pillar veins become **pillar markings** on the character from Blaze onward.
- **Mapping:** Vitality → the Flame's mood and glow (joyful → sleepy ember, never sad); Depth → stages (with active days) + realm restoration + the hearth's Age.

### 05 Daily loop
- Morning: your Flame wakes, stretches, and today's calls appear near the hearth (instead of a list of cards).
- During the day: the tracking moment from anywhere (lock screen widget, later); the light flies to its realm.
- Evening: the Hearth (Part 1 §3), with "Close the day" as its in-world name.
- Away: the Hush, the Return ceremony (the comeback relight values from chapter 04 stay exactly).

### 07 Companion
- **Who speaks:** the Keeper of the realm a question belongs to (Brakka for Body, Quill for Mind…), in that Keeper's voice, **always with sources** shown as "from the Keeper's library" with the real citation.
- **Your Flame** never gives advice; it reacts, encourages, and remembers.
- **Safety:** decision 91 and Part 9 R10: gentle curated habits now; training plans disabled until a qualified reviewer approves that content version (P5); never improvised medical, eating or mental-health advice. The combined prescription validator, safety outcome matrix and referral texts (decision 70) apply to every template, Encounter and Gathering.
- **The AI path stays:** curated content first (works offline, on every phone), Apple's on-device model where available, Private Cloud Compute at P5 **if eligible** (Part 9 R13), then a zero-retention provider through the pass-through server.

### 23 MVP
- **Old:** a tracker with the Flame, Paths, the Spark, the Ritual and the Companion.
- **New:** exactly as in **Part 9 §1** (the phase contract): P3 and P4 run on Mathis's phone only, bundled, curated and local; paid-program services arrive in P5. Success criteria (§A.5) stay and add one: *"Testers describe the app as a world they want to return to, not a tracker."*

---

## 3. New glossary terms (chapter 02)

| Term | Meaning |
|---|---|
| **The Emberlands** | The world of the app |
| **The Hush** | The grey mist of forgetting. Not an enemy; it covers what isn't being lived, and lifts when you live again |
| **The Sanctuary** | Your home: the hearth, your Flame, your keepsakes. It grows through the Ages (Stone, Metal, Crystal, Light) |
| **Realms** | Six regions, one per pillar: the Ascent Highlands (Body), the Library of Embers (Mind), the Whispering Grove (Heart), the Stillwater (Spirit), Forge Mountain (Craft), the Wilds (World) |
| **Restoration** | How alive a realm is (levels 0–5), from your Depth in its pillar |
| **Keepers** | One wise character per realm who gives counsel with sources: Brakka, Quill, Nim & Ro, Ilo, Orrin, Mossbeard |
| **The Lamplighter** | The old flame in the Sanctuary; the mentor of Act I |
| **Journeys** | Paths told as quest lines: a road, waypoints, chapters, a summit |
| **Encounters** | Sparks told as creatures with a request |
| **The Gathering** | The Ritual, held in the Whispering Grove |
| **Beacons** | One per realm; relit when the realm is fully restored. Any three open Act III; all six = the optional Full Circle (decision 96) |
| **Keepsakes** | Earned, dated objects (worn, carried, or kept at home). Never sold |
| **Stages** | Your Flame's evolution: Spark, Flame, Blaze, Kindled, Beyond |
| **Acts** | The story's long chapters: I The Waking, II The Six Beacons, III The Grey Sea, IV Beyond the Veil |
| **The Book of Your Flame** | The Chronicle, written as a storybook |

---

## 4. The code that already exists (what happens to it)

| Code | Fate |
|---|---|
| `Domain` growth engine, `Storage` record (67 tests) | **Kept as-is**: the foundation |
| `CharacterStage` (Domain, tested) | Kept; wired into the UI in P3 |
| `World` conditions (Domain) | Kept; extended into `Realm`, `RestorationState`, `JourneyDef` (Part 5 §B.2) |
| The birth flow, Today, the tracking moment, Spark, Ritual, Paths, Chronicle, Forge, Voice, Settings | Kept as working mechanics; their **screens are redesigned** in P3 as in-world scenes |
| `FlameCharacter` v1b (2D) | A placeholder until the 3D character; kept afterwards as the low-power fallback |
| `SanctuaryView`, `WorldMapView`, `LocationScene` | Replaced by the RealityKit scenes after the spikes |
| The dev menu with sandboxed time travel | Kept: it's how we test months of life in minutes |
