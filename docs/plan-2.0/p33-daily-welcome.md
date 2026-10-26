# P3.3 · The daily screen (decision 183)

Approved in conversation by Mathis on 2026-10-20 ("Yes lets get to work"). The look: **Codex sketches first**, Mathis approves the sketch, then Claude builds the screen and its logic to match, and Codex checks the result.

**Inspiration:** Finch's daily streak screen. One character, big and centred, with soft rays behind it, a huge number, "DAY STREAK", the week row with today's circle sparkling, one honest line (even for a comeback), one button. Its strength is how little it shows.

## 1. When it appears

- **The first time you open the app each day**, before home. It uses the moment the app already notices for the daily pouch (`Journey.checkIn()`).
- **Not on the day your Spark was born** (the intro just happened), and never during the guided tour.
- Tap anywhere to skip the animation to its end; **"Let's go"** closes it on home with today's quests.
- **Opening the app never counts as a day.** The streak grows only with a real quest (decision 134).

## 2. What it shows (the morning version, "today waits")

**Top: Finch-simple**
1. **Your Flame, alive, big and centred** in the form you chose, in a soft warm light (no rays: Mathis, 2026-10-20). It's a live burning Flame (its own small scene, like the intro's), never a picture (decision 93).
2. **The big number:** the current streak, with **DAY STREAK** under it. Shields appear as small icons beside it.
3. **The week, Monday to Sunday:** lived days lit (small flames), missed days dim, a day saved by a shield shows a shield, future days empty. **Today is a glowing empty ring: it's waiting.**
4. **One story line**, chosen by the streak's state:

| State | Line |
|---|---|
| alive, today not yet lived | "12 days in a row. Day 13 is waiting." |
| a shield caught yesterday | "A shield caught yesterday. Your 12-day flame lives on." |
| yesterday missed, repairable | "You missed yesterday. Two quests today save your 12-day flame." |
| broken (comeback) | "Your 12-day flame is resting. Your best is 21, and your forms are yours forever. Ready to beat it?" |
| no streak yet (day 2, nothing lived) | "Your first flame starts with one quest today." |

**Bottom: "your growth", three bars that slide right.** Each bar shows a faint marker where you were **7 days ago**, and the bright fill grows from it to today. Every morning you watch your real week's gain fill in. Every number comes from the record; nothing is made up to look good.

1. **Next form:** "Kindled in 2 days". The bar runs from the current form's day count to the next form's, filled by the **current streak**, with the next form as a **dark silhouette** at its end (secret until reached, decision 169). When every form is reached: "Every form is yours", full bar.
2. **Flame level:** "Level 6 · +340 XP this week". If the level went up during the week, a "+1 level" badge pops and the bar starts from empty.
3. **Your best skill this week** (the skill that gained the most XP): "Strength · level 4 · +2 levels this week". If no skill grew this week: the skill closest to its next level, "12 XP to Calm 3".

**Then** today's "why it matters" line (the existing 30 `DailyWhy` messages, one per day), and the button **"Let's go · +5"** with an Ember coin: the daily pouch, collected here, its coins flying to the counter on home. **The pouch card leaves home** (the screen replaces it).

**The order of the moment (about 3 s, haptic ticks as in the level-up screen):**
1. The Flame and rays rise in.
2. The number pops in.
3. The week lights up left to right, and today's ring starts glowing.
4. The three bars slide right one after another, their "+" counting up.
5. The quote and the button appear.

## 3. The payoff: your first quest of the day ("today lit")

- The same screen comes back for **about 2 seconds** in its lit version: the number ticks 12 → 13, today's ring fills with sparkles, "Day 13 kept." Then the usual XP cards follow.
- **If that quest reaches a new form**, it doesn't close by itself: the silhouette at the end of the next-form bar turns into the real form, your Flame transforms in the centre, "Your Flame became a Kindled", and "Keep going" closes it. This replaces the small paper card (`RewardBurst` celebration) for new forms. Streak milestones that are not forms (3 / 30 / 66 / 100 / 365 days) show on the same lit screen as its line.
- Later quests that day show only the XP cards, as now.

## 4. What it will never do

- No guilt, no countdown timers, no "you'll lose everything".
- A broken streak never hides your best streak or your forms ("users never feel they've lost it all").
- Self-reported numbers stay private: this screen is only for you.

## 5. A fix along the way

"N more days until the next form" (level-up screen) counts from the **best** streak. After a break that's wrong: with a best of 10, a current streak of 2 and Kindled at 14, it says 4 days when the truth is 12. A form is reached when the **current** streak hits its day count (only then can the best streak pass it), so both screens will count `next.days − current`.

## 6. How it's built (Claude, after the sketch is approved)

- **The numbers, `DailyReport`** (pure, no screen, `Shell/DailyReport.swift`): built from the Journey's deeds at a given moment. It holds the streak state, the week row, the story line, the three bars (each a value 7 days ago and now), the quote and the pouch. "7 days ago" = everything lived before the start of the same day last week, so the week's gain = the last 7 days including today.
- **The screen, `DailyWelcome`** (`Shell/DailyWelcome.swift`): drawn to Codex's approved sketch, reusing `XPBar`, `XPHaptics`, `SparkBurst` and the coin flight. The Flame is its own small live scene (`HeroRig` with the chosen form, as `IntroFlameStage` does), so the world behind can pause while it's open.
- **Wiring:** `ShellModel` decides when it shows (first open of the day, not the birth day, not during the tour). Home shows it above everything, and its button collects the pouch. The first quest of a day triggers the lit version before the XP cards. A new form uses the lit version's reveal instead of `RewardBurst`.
- **Test flags:** `-welcome` (show it now, whatever the day), `-welcomestate alive|shield|repair|broken|first`, `-welcomelit`, `-welcomeform` (with `-seedjourney` or on the current progress). The **Next day** test button shows it each time, like a real morning.
- **Checks:** a logic self-check of `DailyReport` over seeded histories (alive, shield, repair, broken, level-up within the week, every form reached, the best-vs-current form fix); simulator captures of every state compared to the sketch; 60 fps on the iPhone during the animation; then Codex reviews the screen against its sketch.

## 7. Steps

1. ✅ Codex sketched four frames (`scripts/p33-daily-sketch.sh` → `docs/design/p33/daily-*.png`): morning, lit, comeback, new form. Two painted icons (`scripts/p33-daily-icons.sh` → `Assets/day-flame.png`, `streak-shield.png`).
2. ✅ Claude (2026-10-20): `DailyReport` (`Shell/DailyReport.swift`), the streak walk's day marks and last-ended length (`Progression.walk`), `Progression.formProgress` (the form-days fix, also used by the level-up screen) and `DeedOutcome.firstOfDay`. Proved by `-dailycheck` (`Shell/DailyReportCheck.swift`): 57 checks pass in the simulator. The "when it shows" wiring and test flags come with the screen (step 4).
3. ✅ Mathis approved the morning sketch ("lets go", 2026-10-20), then asked: **no rays** behind the Flame (a soft warm light instead).
4. ✅ Claude built `DailyWelcome` (`Shell/DailyWelcome.swift`) to the sketches and wired it (ShellModel `daily`, `planDaily`, `dailyStage`; HomeView `dailyLayer` and the lit trigger: the quest whose streak goes up). Every version captured in the simulator: `docs/design/p33/verification/` (`all-states.png`). Installed on Mathis's iPhone 2026-10-20 (sequence 14324); the phone was locked, so the on-device launch and fps measurement are still to do.
   - **The live Flame:** its own small RealityKit view with the chosen form (`DailyFlameStage`), prepared during the launch. A new RealityKit view takes seconds to draw its first frames (simulator: 3.5 s at launch, ~5 s mid-session; a second one in the same session: 41–47 ms), so the morning screen opens under the launch veil and plays when it lifts, and on days without one an invisible warm-up view draws behind the veil for 6 s. The moment waits for the Flame's first frames before anything rises in.
   - Test flags: `-welcome` (your real numbers), `-welcomestate alive|kept|shield|repair|comeback|first|allforms|almostform`, `-welcomelit`, `-welcomeform`, `-welcomelitlater` (lit, mid-session), `-dailycheck`, `-perf` (prints the Flame's first-frame timings). The Next day test button shows the morning screen like a real morning.
4b. ✅ Mathis's phone test (2026-10-20): no lived-day flames and a streak stuck at 1. His record showed **no quest saved** in that session (only the Next day presses), so each new day was a fresh start; in the simulator the full flow works (tick → Next day → tick: 2; day 3 reveals the Flame form). Fixed on the way: the lit row kept yesterday's title; the reveal said "Your Flame became a Flame" (now from the form it grew from); the warm-up view can never catch a touch and stops once a daily screen was seen; the morning lines now say what to do ("One quest today makes it 13"). New check of his exact flow: 61 pass. Installed 14332 (phone locked: not launched).
5a. ✅ Codex's review (`docs/reviews/2026-10-20-codex-daily-screen.md`, after its usage limit reset): the direction works, streak maths correct (incl. repair days); 6 MUST-FIX, all fixed the same day: (1) a new calendar day while the app stays open or in the background now brings the check-in, quests, pouch and morning screen (`ShellModel.refreshDay`, on foreground and at midnight); (2) the lit screen's numbers and the form shown before the quest are fixed at completion (`DailyShow.lit(… from:)`), so a real unlock reads "Your Blaze became a Kindled"; (3) the form bar is one honest scale, 0 → the form's day count (as "12 / 14" says), never jumping back during a restarted streak, and after a restart this week there's no ghost from the old streak; (4) no pressure: repair "keeps your 4-day streak going. Your forms and progress stay either way.", comeback quote "Your progress is all still here.", and four lines of the daily "why" pool replaced (no "37 times better", "Don't break the chain", "Hard days count double", "never miss twice"); (5) the world rests under the opaque screen (`restUnderDaily`), the warm-up runs once per app run (`model.dailyWarmed`), the moment waits up to 3 s for the Flame and a tap always skips; (6) every form fits with room above its fire (the Spark was clipped). Nice-to-haves done: NOW LIT 10 pt inside its card, lit Flame centred with its light under its feet. Not done: the outlined "1" label (kept from the approved sketch). 64 checks pass; full flow replayed in the simulator. Installed 14340 (phone locked).
4c. ✅ **Decision 184 (Mathis, 2026-10-21): coming to the app lights the day.** His second test: Next day three times, no quest, and the streak stayed at 1 (his record held no quest). He wants each new day he comes to count. Built: a day's first open counts for the streak (`Progression.walk(checkIns:)`; an open counts one, each quest one, so coming back + one quest repairs a missed day); `Journey.checkIn` returns what the open did (`CheckInOutcome`: a new form, a milestone, with their Book pages); the morning screen is `DailyShow(before:after:from:evolvedTo:milestone:)` and plays the lighting (number +1, today NOW LIT, the form reveal on opening) before the bars; the short lit screen only follows the quest that repairs a missed day. Fixed on the way: "Let's go" could be pushed below the screen mid-session (the screen now lives in its own layer above home). 76 checks pass (incl. his flow: three opens = 3 and the Flame form). Simulator: the real first open of 2026-10-21 lit 4 → 5; Next day → 6 → 7 with the Blaze reveal. Installed 14472 (phone locked: not launched).
5. ⏳ Codex reviews the result against its sketches (`docs/reviews/briefs/p33-daily-review.md` → `docs/reviews/2026-10-20-codex-daily-screen.md`); fixes; Mathis tries it on his phone; 60 fps check on the device.
