# Study: Life Reset (66 Day Habit), what Hush should take (2026-10-04)

*Source: Mathis asked for full research on Life Reset (formerly "Rise: Life Reset in 66 Days"), screenshots, and a list of the good things to bring into Hush, with the streak at the core. Status: **list for Mathis's approval.***

**Sources:**
- App Store and Google Play pages, with the reviews pages;
- lifereset.com;
- JustUseApp's review analysis;
- the App Store screenshots, studied one by one (saved in `docs/design/references/life-reset/`).

I couldn't use the app itself: everything sits behind a paid subscription after the onboarding quiz.

## What Life Reset is
- **Positioning:** "Turn your life into a video game", in a dark anime style (Solo Leveling).
- **Reach:** 1.5M+ users, 4.7★ from 13K ratings on iOS, 4.5★ on Android.
- **The promise:** a 66-day program (the habit-formation figure), generated from an onboarding quiz across six areas: sleep, water, exercise, mind, screen time, shower.
- **Business model:** subscription only, $30–60 a year.

## What it does well (the screens)

| Screen | What's good |
|---|---|
| **Day 14 / 66** | One big counter ("DAY 14 / 66") and the streak, trophies and XP at the top. A warm line ("You're doing great. Keep going!"). Tabs: To-dos 7 · Done 1 · Skipped 0. Quests as big illustrated cards, each showing its own streak, frequency, difficulty and progress (0 / 20 reps), checked off with one tap. |
| **Your Rating** | A level (33) with an XP bar ("500 XP to Lvl 34"). Five attributes with big numbers that rise (Wisdom 172, Confidence 207, Strength 330, Discipline 180, Focus 202). You can compare Day 1 against Day 66. |
| **Insight** | A personality class ("ROGUE: your peak days are who you are", shared by 18% of users) with stat bars. Total tasks with a curve against the average. A next suggestion ("120 g protein/day", with Task full / Skip). Before/after on water, wake-up time and screen time. A 7-day course card. |
| **Season** | Monthly seasons with a countdown ("14d 6h"). Ranks (Gold II) and a progress bar to the next one. Unlockable cosmetics (frames, wallpapers). Daily XP against the rank's average. A leaderboard where each friend shows their own streak and goal. |
| **Hero mode** | Your character goes into "battles" and comes back with loot. Reviewers love it, and miss it when bugs break it. |
| **Tools** | Focus timer, guided meditation, book summaries, a workout tracker, a screen blocker, an AI calorie tracker. |
| **Rituals** | A motivational card at the start of each session, collected like a deck. Home-screen widgets for the quests and the streak. A journal with emotions and photos. A "graduation" on day 66. |
| **Hard Mode** | Penalties for missed days (extra push-ups, warnings). |

## What reviewers love, and what they hate

**Love:**
- It feels like a real-life RPG and keeps them consistent.
- Seeing the numbers climb, and the loot coming back from a battle.
- The Discord community, and a developer who answers every review.

**Hate (lessons for Hush):**
- **The paywall after the quiz.** It feels deceptive, and it's the most common complaint.
- **Bugs and lag**, especially lost streaks: "the bug happened which lost my streaks" made people leave.
- **A cluttered interface** ("icons make no sense", "complicated to get to things").
- **Rigid plans** that ramp up mechanically and aren't practical.
- **Hero mode runs out of content** (blank cards, items that do nothing).
- **It doesn't last** ("after a year you realise you don't need the app").

## What Hush should take (the list)

### A. The streak at the core
1. **One prominent streak counter**, always visible at the top of home in every world, next to the Spark (e.g. 🔥 14).
2. **A streak on each quest too** ("9d" on the card), so each habit has its own momentum.
3. **A clear program counter**: "Day 14 / 66", the first arc, with a graduation at day 66 and a big ceremony. In our lore, the Spark's first great step.
4. **Celebrations at milestones** (3, 7, 14, 30, 66, 100, 365 days), each a moment in the world.
5. **The streak in widgets and notifications** ("Your Flame is waiting: 14 days").
6. **Protection, so it never feels like losing it all** (the lesson from their lost-streak complaints, and our non-negotiable):
   - streak shields earned by living, not bought;
   - a one-day repair window;
   - the streak never touches Depth or the world.

   A broken streak dims Vitality; it never erases what you built.

### B. Numbers that climb (instant, visible progress)
7. **Attributes with big rising numbers**, one per pillar (Body, Mind, Heart, Spirit, Craft, World), shown in Your Flame. Each completed quest adds to its pillar with a satisfying count-up.
8. **XP and a level, with a bar to the next level** ("500 XP to level 34"), alongside the Flame's stages: frequent small level-ups, rare big transformations.
9. **Day 1 compared with today** in Your Flame ("you, then and now"), with Codex's growth line.
10. **Before/after on real data** (sleep, steps, screen time, from HealthKit and Screen Time), on the device only.

### C. Quests that feel good
11. **Quest cards with an illustration**, showing their streak, frequency, difficulty and progress (8 / 20 pages). Satchel and journal cards can carry the realm's painting.
12. **Tabs: To do · Done · Skipped**, plus an honest "skip" that doesn't punish.
13. **A next suggestion with a reason**, and buttons to take it or skip it, from the Companion with cited sources.
14. **Progress inside a quest** (reps, minutes, pages), not only done/undone.

### D. Rituals that bring you back
15. **A daily card** when you open the app: a short line from your Keeper (Ilo, Brakka, Quill…), collected in the Book.
16. **Home-screen widgets**: your Spark alive, the streak, today's quests.
17. **A short journal** after a quest: one line on how it felt, optionally a photo, written into the Book.
18. **Seasons**: a season per month with a shared Ritual and a keepsake. In our lore, the weekly Gathering plus the seasons already planned. Cosmetics are earned only by doing; nothing is ever sold.

### E. Feel and onboarding
19. **A personal assessment at the end of the intro** ("your strengths, where to start"), from the intro questions and HealthKit.
20. **A fluid, game-fast interface** (they're praised for it, then criticized for lag). Ours is already measured at 60 fps with instant switching. Keep it that way.

## What Hush should not take
- **A paywall right after the quiz** (their most common complaint, and against decision 87 until launch).
- **Hard Mode penalties and guilt** (against "no manipulation" and "never lose it all"). The ambition can stay as an opt-in "Ascent" challenge with harder quests, never punishment.
- **Leaderboards ranking people by XP.** Status in Hush stays verified and community-first (Plan 2.0), with no comparison of self-reported numbers.
- **A dark, clinical dashboard.** Their numbers live in lists; ours live in a world.

## What Hush already does better
- The progress is a living universe: a Spark that grows, realms that wake, a Book that writes your story. Their reviewers ask for exactly this ("your character should physically evolve", "a storyline").
- No paywall before you've lived it; your data stays on the phone.
- Fast and alive: 60 fps, one interface everywhere.
