# 05 — The Daily Loop

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-09-30
**Based on:** decisions 16–17, 52–54, 63, 65 and chapters 03, 04, 28

---

# Part A — For Mathis

## A.1 Your day, at a glance *[Settled, 16]*

When you open the app, your day is already decided, gathered around your Flame in the Sanctuary:

| Layer | What | How many (MVP, by default) |
|---|---|---|
| **Your Paths** | Today's steps on your long arcs | 1–3 Actions a day in total, across **at most 3 active Paths** |
| **The Spark** | One surprise challenge at your edge | 1 a day, with **1 swap** |
| **The Ritual** | This week's shared challenge | 1 a week, done any day that week |

**Why so few** *[by default]*: the app is a way into your life, not a to-do list (P5, "not a distraction"). A day you can actually complete feels better than a list that shames you. As your levels rise, the Actions get *harder*, not *more numerous*.

## A.2 The shape of a day *[by default]*

- **Morning: "Your day is ready."** At most **one gentle notification a day**, at a time you choose (or none). Opening the app shows the Sanctuary waking up and your day around the Flame.
- **During the day: the tracking moment.** Tap an Action when it's done. The spark flies into your vessel (chapter 06). Takes a second.
- **Evening, optional: "Close the day."** A 20-second moment: your day's sparks settle into the vessel, your growth for the day appears (+0.8% today, for example), and the Sanctuary dims gently for the night. There's nothing to fill in.
- **Anything else you did:** "I also did something" lets you log an unplanned Action and pick its pillar. It counts, as a bonus (fill, chapter 04).

## A.3 The Spark *[Settled, 16; details by default]*

- **It's dealt each morning, chosen by the Companion.** It usually leans toward a pillar you haven't fed lately, sits a little above your level, and is sometimes a **Hidden Spark** (chapter 28).
- **One swap a day.** The replacement comes from a different pillar.
- **An unfinished Spark simply fades at the end of the day.** No penalty, no guilt.

## A.4 The Ritual *[by default]*

- **One shared challenge per week**, the same for everyone, done any day that week. You see how many have joined ("41,209 joined").
- **It's a bonus, not an obligation.** It doesn't count against your day if you skip it. Doing it earns growth like any Action, plus that week's time-stamped reward.
- **In the MVP,** the first Ritual also earns the first fire style (chapter 03).

## A.5 Paths *[Settled, 17; limits by default]*

- **You start with one Path**, born with your Flame (chapter 08). Add more with the Companion, up to **3 active** in the MVP.
- **A Path = goal + plan + schedule.** The Companion builds the plan; the schedule decides which days have which steps, and which days are planned rest.
- **Changing a plan** affects future days, never past ones (decision 58).
- **Finishing a Path** is a moment: the Path's goal is marked in your vessel forever (a small permanent mark), and the Companion suggests what could come next.

## A.6 Life happens: pausing *[by default]*

Illness, a trip, a family emergency. You can **pause** (for example "I'm sick", "I'm travelling"):
- **Vitality is protected** while paused. The Flame doesn't dim.
- **No growth is earned** (it's not a planned rest day). That keeps "1%" honest.
- **Up to 14 pause days per 90 days**, so it can't quietly replace showing up.
- **Your Paths reschedule** gently around the pause.

## A.7 Rules the app never breaks *[Settled, guardrails]*

- No streak counters. No "you'll lose everything" warnings. No guilt notifications.
- A missed day is never mentioned as a failure. The next day is simply ready.

---

# Part B — For the builders

## B.1 Dealing a lived day (`Data`, deterministic given inputs)

Triggered at the lived-day boundary (background, best effort) or at the first foreground on D, whichever comes first. It writes one `dayPlanned` (chapter 04 §B.1):
1. **Path slots:** for each active Path, the effective `scheduleIssued` pattern for D's weekday gives the slots. `d` comes from the current level (chapter 04 §B.6). If any active Path marks D as rest and no other Path has slots, set `isPlannedRest = true`.
2. **Spark:**
   - If a Hidden Spark is eligible and `SHA-256(seed ‖ livedDay) mod 7 == 0` → that Hidden Spark (chapter 28 §B.1).
   - Otherwise, choose the pillar with the lowest `recentMix` share (ties → the lower pillar index in the order Body, Mind, Heart, Spirit, Craft, World), then choose the catalog Spark in that pillar that wasn't dealt in the last 30 lived days, using `SHA-256(seed ‖ livedDay ‖ pillar)`.
   - `stretch = 1.25`. Sparks tagged unsafe for the user's context (chapter 07) are excluded.
3. **Ritual:** not part of S(D). The current `ritualId` for the week comes from the catalog.
4. **The cap:** if the Path slots exceed 3, keep the 3 with the highest Path priority (the user's order); the others are deferred to the next day by the schedule's reflow (post-MVP: a smarter reflow).

## B.2 Spark swap
- Allowed if no `sparkSwapped` exists for D on this device.
- The replacement uses the same algorithm, excluding the swapped Spark's pillar. It writes `sparkSwapped` (chapter 04 §B.1).

## B.3 Pause
- `pauseStarted { reasonCode, from: LivedDay }` and `pauseEnded { at: LivedDay }` (P).
- For paused days: `presence(D) = 1` (Vitality protected) and `completion(D) = 0` (no growth), unless the user completes Actions anyway, in which case the normal completion applies and presence = max(1, completion).
- The limit is 14 paused lived days in any rolling 90, enforced at `pauseStarted` (the UI shows the remaining days). Beyond the limit, pausing is refused kindly and the user is offered a Path reschedule instead.
- Add `pausedDays` to the engine inputs. Golden vectors for paused days go in the implementation plan, computed via the reference script (to be extended).

## B.4 Notifications
- At most one local notification per day (the morning "day ready," at a user-chosen time, off by default until the user opts in during onboarding), plus one on the Ritual week start (optional). Local notifications only; no push server in the MVP.
- Copy is from the catalog `voice` and never mentions streaks, losses or missed days (guardrail 1). A validator checks notification copy against a banned-phrases list.

## B.5 Close the day
- Optional. The screen shows the day's completion and the G delta. The animation plays a summary of the day's `sparkToVessel` events. No input required. Writes nothing (purely presentational).

## B.6 Free Actions
- "I also did something": the user picks a pillar (or the Companion classifies free text on-device, tier 1; the text is H2). It writes an `actionCompleted` with `source: free`, `d = 1.0`, `occurrenceKey = free:{entryId}`. It counts as fill (chapter 04 §B.4).

## B.7 Open
- The Path creation dialogue and plan generation → chapter 07.
- The first Path at birth → chapter 08.
- Smarter schedule reflow → post-MVP.
