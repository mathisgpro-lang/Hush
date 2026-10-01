# Plan 2.0 · Part 9 — The Phase Contract

*One source of truth for what exists in each phase, the rules settled by Codex's review, and what each phase plan must contain before anything is built.*

**Status:** draft, [by default] under decision 63 (decision 94) · **Written:** 2026-10-01
**Origin:** Codex's independent review, [`docs/reviews/2026-10-01-codex-plan-2.md`](../reviews/2026-10-01-codex-plan-2.md) (24 findings). **Where any other part disagrees with this one, this part wins.**

---

## 1. What exists in each phase (fixes finding 1)

| Capability | P2 · Spikes + design | P3 · "The Waking" | P4 · "The First Beacons" | P5 · Launch | P6+ |
|---|---|---|---|---|---|
| **Audience** | Mathis (tests only) | Mathis only | Mathis; friends try it **on his phone** | Join the paid program; a TestFlight round, then the App Store | Everyone |
| **Install** | Throwaway spike apps | Free signing, re-installed from the Mac every 7 days | Same | TestFlight / App Store | App Store |
| **Your record** | Never touched by spikes | On the phone; iPhone iCloud Backup + **verified** export/import (R11) | Same | + iCloud sync (CloudKit) | Same |
| **Counsel** | — | The Keepers' **curated** counsel with sources | Same | + Apple's cloud AI **if eligible** (R13); curated stays as the fallback | + other providers after review |
| **Usable Journeys** | — | Discovery picks from **several safe Journeys** (R15): *Lanterns for the Ones You Love* lives in the Grove; the others run from the Sanctuary until their realm exists | + gentle Body habits in the Highlands (walks, stretching, sleep); + *The Clear Water* in the Stillwater | + training plans **only after a qualified reviewer approves that content version** (R10) | The full catalog |
| **Scenes at final quality** | Placeholders only | The Sanctuary + the Whispering Grove; other realms misted on the map | + the Ascent Highlands, the Stillwater | + the Library or Forge (3–4 realms) | Realm releases |
| **Story** | — | **All of Act I**, including a **Sanctuary-hosted Forge ceremony** (Orrin visits the hearth) and the Book of Your Flame **kept in the Sanctuary** | Early Act II | Act II continues | Acts II–IV |
| **Gathering** | — | Local: your own lights + scenery, no implied crowd (R8) | Same | Real counts via the Relay | + community |
| **Assets** | — | Everything bundled in the app | Same | Delivery via Background Assets (R12) | Same |
| **Art** | AI-only (decision 87) | Per the art decision at P2's exit | Same | Same | Same |

**The eight-Journey table in Part 1 §5 is the future catalog**, not a phase scope. Superseded recommendations elsewhere (e.g. "the $99 at P4") are void.

---

## 2. Rules settled by the review (by default)

**R1 · Two inputs for the world's look (finding 5).** Every realm area is drawn from two values:
- **`restoration`**, from Depth: what has been rebuilt (geometry, water, inhabitants);
- **`vitality`**, from Vitality: atmosphere (mist, light, saturation).

A highly restored realm during an absence stays rebuilt but misty; a lightly restored realm while you're thriving is bright but sparse. **The Return** plays a temporary foreground mist-lift on your first action back, while the real Vitality climbs as chapter 04 says (about 3 days).

**R2 · Permanent vs. calculated (finding 6).** These are **grants**, written to the existing grant records and never revoked:
- stages;
- Ages;
- finished-Journey landmarks;
- **each restoration level reached** (`realm:<id>:level-<n>`);
- keepsakes.

Calculated (can move): intra-level progress, mood, Height. Rules for edge cases:
- **After a correction** lowers Depth below a granted level, the level stays, and progress inside it restarts from that level's floor.
- **Grants are written when the undo window closes** (chapter 06), so undoing right after crossing a threshold never grants and then revokes.
- **The content catalog is versioned:** thresholds and Journey definitions carry a version, and a Journey keeps the version it started with. A catalog update never moves an old road or removes earned content.

**R3 · Progress mapping (finding 7).**
- **Truth is saved immediately, and the world changes immediately.** Evening at the Hearth only summarizes the day.
- **Height animates only when it really changes.** When the daily 1% ceiling is reached, a distinct "light stored" acknowledgment plays; there's no fake tick.
- **An action that feeds several pillars** sends one colored strand to each credited realm.
- **Rest days** show the campfire scene; their growth is applied at day close with no fake action.
- **Journey waypoints have stable IDs.** A replanned or shortened plan moves only the waypoints still ahead, never completed ones.
- **At full restoration (level 5)**, an action is celebrated (lanterns brighten, the Keeper notices) without inventing a score increase.

The worked examples belong in the P3 plan (§4).

**R4 · Quality modes (finding 11).** Five modes, in order:
1. **Full** scene.
2. **Reduced effects:** fewer particles, no volumetric fog.
3. **Light scene:** a still image of *your current world state*, rendered from the same scene, with the live 3D Flame at lower cost.
4. **Light 2D:** the 2D animated Flame over that state image.
5. **Simple view:** a plain list with a small animated Flame (R7).

How modes are chosen:
- **Separate inputs:** thermal pressure, Low Power Mode, user choice. Reduce Motion changes motion *style*, not quality.
- **Hysteresis:** step down after 5 seconds below target, step up only after 60 seconds stable.
- **Every mode** supports completing, undoing and navigating, shows true progress, and keeps the Flame animated (decision 93).

**R5 · No fear of missing out (finding 14).**
- **Acts advance only by lived progress, never by the calendar.** Part 1's "one Act a year for everyone" is removed.
- Seasons change the **atmosphere** on the calendar, but seasonal stories and keepsakes **stay earnable later**. A keepsake records when and in which season you earned it; it never creates permanent exclusion.
- **Encounters can be declined neutrally.** A creature's wellbeing never depends on your answer, and requests stay around or come back.
- No countdowns, and no notifications about expiring content. A long absence pauses nothing you'd lose.

**R6 · No guilt (finding 13).**
- **Life outside the app counts, even unrecorded.** The Hush is the world forgetting, never a measure of your worth.
- Lines rewritten: the Lamplighter's welcome, the fox Encounter, Orrin's motto (Parts 1 and 2).
- Return dialogue is welcoming, with no debt.
- The absence scenes get reviewed with people who take long breaks, not only daily enthusiasts.

**R7 · World-first, never world-only (finding 15).** This replaces "no tabs, no menus".
- Every essential task has a **labeled route within 2 taps from the Sanctuary**, plus a plain-list **Simple view**. That covers completing, undoing, correcting a past day, backup/export/import, settings, changing or pausing a Journey, and a free Action.
- **Quick tap and hold both complete.**
- Emberspeak glyphs are decorative to VoiceOver; the text is readable at once in accessible mode.
- **Accessibility is tested during P3** (VoiceOver, the largest text, Reduce Motion), not deferred to P5.

**R8 · An honest Gathering (finding 21).** While it's local, the Grove's lights are **your own lights plus scenery**; nothing implies a live count of other people. Before any social feature, a separate **shareable view** shows only verified fields, with consent; your private world is never exposed because it renders locally.

**R9 · An honest number, and success beyond retention (finding 24).** Height is described as **a record-based game measure of your consistency**, never "you're 37% better". The formula is unchanged. Success also needs voluntary in-app reflections: *Is this useful outside the app? Can you skip without guilt? Was coming back easy? Do challenges fit you?* "I felt obliged to keep my Flame alive" counts as a **failure signal**, even if retention is high. No analytics needed.

**R10 · Safety content (finding 12; reconciles decision 91).**

| Category | Status |
|---|---|
| Curated gentle habits with sources and limits (walks, stretching, sleep routine, reading, calm, relationships, nature) | **Allowed now** |
| Training plans (running, strength) | **Disabled until a qualified reviewer approves that exact content version** (planned for P5) |
| Medical, eating or mental-health advice | **Never improvised**; referral only |

What every template carries:
- **Every template defines** its limits, adaptation permissions, stop/skip alternatives and referral wording.
- **The same checks cover Encounters and Gatherings,** and combined demand across Journeys.
- **"Safe" pillars still get alternatives:** relationship prompts never assume a safe family contact ("someone you trust", or options that don't involve contacting anyone); calm and outdoor tasks have indoor and seated options.

**R11 · Your record is recoverable before it matters (finding 20).** Before P3 stores real weeks of use:
- **Document** the stable re-sign procedure.
- **Verify the export → import round trip** in a throwaway install: growth, grants, the Flame's name, settings, Journey revisions, witnessed scenes.
- **Explain** what an ordinary iPhone backup includes.
- **Keep a restorable copy** before any migration.
- **Never fix a signing problem by deleting the real app.**

**R12 · Asset delivery (finding 18).** Until P5, everything is bundled. At P5, evaluate **Background Assets** (Apple documents On-Demand Resources as deprecated from iOS 27). Logging always works when a realm package is absent.

**R13 · The launch AI path (finding 17).** Paying Apple isn't enough on its own: Private Cloud Compute requires eligibility (the Small Business Program, an assigned entitlement, supported distribution). At P5, test a real request on the target phone, plus unavailable, offline and quota-exhausted cases. Curated counsel stays as the fallback. **"A plan for any goal" is promised only after that test passes.**

**R14 · Two kinds of evidence (finding 16).**
- **Founder evidence (P3–P4):** Mathis living it, and friends' impressions on his phone.
- **External evidence (P5):** TestFlight on other phones, with gates for crashes, offline conflicts, sync, restore, deletion, AI unavailability and download failures. The TestFlight round is a **minimum of 2–3 weeks, extended whenever a gate fails**.
- Chapter 23's week-four retention criterion is measured only if TestFlight runs at least 4 weeks; otherwise R9's reflections replace it.

**R15 · Discovery without AI (finding 3; decision 92).** The P3 discovery flow:
1. Your Flame asks the first question.
2. You answer freely or tap one of **several safe interests**.
3. A curated match suggests a Journey, which **you confirm or change**.

Rules around it:
- **"I'm not sure"** leads to a gentle sampler week.
- **A goal the library can't support yet** gets an honest answer ("I can't build that one yet; here's what's close") and is remembered for later.
- **What's remembered:** your stated interests, your confirmations, and what you do and return to.
- **A skip never means dislike,** and never gives permission to switch your life goal. Suggestions change only with your confirmation, and you can always correct them.

---

**R16 · Your pillars, your story; balance as a friendly reminder (finding 4, decision 96).**
- **The story advances through the pillars you choose.** Act III opens once **any three Beacons** are relit. A Beacon relights when its realm is fully restored; a finished Journey leaves its own landmark. Lighting **all six** is the optional **Full Circle**: a special scene and a keepsake, never required. Kindled isn't required for any Beacon.
- **Quiet pillars come back now and then, as an invitation, never an obligation.** In the world, that's:
  - a **Keeper's visit** from a realm you haven't touched lately: *"Brakka stopped by. The Highlands remember your footsteps. A short walk, someday?"*;
  - an occasional **Encounter** from that realm, always with a tiny 2-minute version;
  - a quiet realm stays **gently misted on the map**, visible and never alarming;
  - your Flame's **balanced look** (Part 3 §4) stays something to admire, never a warning.
- **Limits:**
  - at most **one balance reminder a week**, and the same pillar at most **once every 4 weeks**;
  - **in the app only, never a notification**;
  - it never affects Depth, Vitality, the story or any reward.
- **Two calm answers, always:**
  - **"Not now"** quiets it for 4 weeks;
  - **"Not for me"** stops reminders for that pillar until you turn them back on in Settings. It never asks why (an injury, a disability, a season of life are nobody's business).
- **Wording:** an invitation, never a deficit. "The Highlands remember you", never "you've neglected your body". Body reminders offer only gentle habits (R10).

## 3. The P2 phase plan must contain (gate before P2 approval)

1. **A feature checklist tied to the installed Xcode and iOS versions** (finding 8):
   - **S1:** representative fluffy-fire coverage, facial changes during body animation, rig blending, embers, and every aliveness criterion (decision 93).
   - **S2:** the expected scene density with SwiftUI controls on top.
   - **S3:** restoring a visible object, flowing water and inhabitants, not just tint, driven by both R1 inputs in all four low/high combinations.

   Unsupported effects and their substitutes are recorded and **shown to Mathis**. A simpler look never counts as a pass without his seeing the difference.
2. **A measurement protocol** (finding 9):
   - total-app memory, steady and peak, including scene transitions;
   - texture budgets;
   - a repeated 30-minute scenario (loading, completions, ceremonies) with frame times and stalls, after the phone warms up;
   - background/foreground and memory-pressure tests;
   - fixed conditions for battery (brightness, sound, power mode).

   Results come for **both full and reduced quality**. Today's numbers are targets to validate, not established limits.
3. **The exit decision on art** (finding 19):
   - one representative **end-to-end asset trial**: concept → rig, animation and material → on the phone, with source files, licenses, a reproducible export, the time it cost, and a playable sound sample;
   - an **asset acceptance checklist**;
   - a **no-spend continuation** with its quality compromises stated plainly;
   - the schedule re-estimated against Mathis's 1–2 hours a day.

   No freelance outreach or paid trial without Mathis's yes.
4. **The fallback route**, per Mathis's decision on finding 10.

## 4. The P3 phase plan must contain (gate before P3 approval)
1. **Every Act I beat** with its exact engine trigger, scene, required assets and replay location (finding 2).
2. **The discovery flow** (R15) and its full set of safe Journeys (finding 3).
3. **Worked examples** for R2 and R3: undo just after a threshold, a later correction, a catalog change, the daily cap, a multi-pillar action, a rest day, a replanned Journey, full restoration (findings 6–7).
4. **The allowed-content table per template** (R10).
5. **The backup gate passed** (R11).
6. **Character states per stage**, ceremony priority, skip, crash/resume and replay, with **owning a reward kept separate from seeing its animation** (finding 22). The Spark catches light with its whole body (it has no arms yet); naming stays optional.
7. **A pacing report from simulated lives:** specialist, balanced, low-frequency, planned rest, pause and comeback histories, run through the real engine, showing when each threshold is reached and what content exists then (finding 23). Calendar labels are illustrative; real growth is never capped to fit the content schedule.
8. **Accessible routes and the Simple view** (R7), tested with VoiceOver, the largest text and Reduce Motion.

## 5. Open for Mathis
- ~~Beacons (finding 4)~~: answered by decision 96 (R16).
- **The fallback engine (finding 10):** Unity is a second, untested architecture, not a ready fallback.
