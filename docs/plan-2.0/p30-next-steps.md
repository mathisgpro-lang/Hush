# P3.0 · Next steps: the game loop, daily and long term (plan, 2026-10-09)

*Sources: Mathis's handwritten notes (2026-10-09: "Important adds", "World map"), the competitive analysis (`competitive-analysis.md`), and his direction that choosing actions, tracking and the streak are the heart of the app. The subscription in the notes is **not** applied ("I don't want to make people pay immediately"). Status: **draft, waiting for approval.***

## 1. Daily: why open Hush every day

1. **Your day, framed as your Flame's needs.** The quest board reads "Your Flame needs this to feel good today", followed by today's quests. The quests are the same as now; only the framing is more personal.
2. **A line from your Flame every morning.** It's based on the last days' completions:
   - "Three days in a row! I feel taller."
   - "We missed yesterday. One small thing today and I'm warm again."

   It's written from your real record, never generic.
3. **An immediate reward on every tick:**
   - the Flame reacts happily, with a hop and its happy face;
   - coins fly to your counter;
   - every few days kept, a streak saver drops (earned, see §3).
4. **Something new every day:**
   - the Flame's line;
   - one rotating "surprise" quest (the Spark);
   - now and then a rare find (a Book page, a cosmetic, a Keeper's line).
5. **The Flame's state outside the app:**
   - **A home-screen widget (recommended as the main one):** your Flame, alive and dim or bright with its vitality, plus your streak and quests left. It updates silently and always shows.
   - **The app icon:** it can change with the Flame's state, but iOS shows a "You have changed the icon" pop-up every time, so changing it daily would feel broken. Recommendation: change it only at evolutions (3, 7, 14, 30, 90 days), where the pop-up becomes a small celebration.

## 2. Long term: why keep coming back for months

1. **The streak, protected.** Shields and a one-day repair window are already in the code. On screen, a lost streak should sting gently, never crush.
2. **The Flame evolves with the streak:**

   | Stage | Reached at |
   |---|---|
   | Spark | (start) |
   | Flame | 3 days |
   | Blaze | 7 days |
   | Kindled | 14 days |
   | Radiant (new) | 30 days |
   | Beyond | 90 days |

   - Each evolution is a big moment: a full transformation, the app icon changes, and a Book page is written.
   - **Evolutions are never taken away** (Depth: "users never feel they've lost it all"). A broken streak only dims the Flame (Vitality), and the next evolution counts from your best streak.
   - This replaces the 66-day arc as the main ladder. The 66 days can stay as a "graduation" milestone between Radiant and Beyond.
3. **A visible goal at all times.** For example, "180 more coins to unlock the Stillwater", shown on home and on the map.
4. **Weekly worldwide challenges.** Everyone does the same challenge in a week (the Ritual), and completing it engraves a badge on your profile forever.
   - These need a small server (shared challenge, counts) and the paid Apple program for iCloud, so they come at P5.
   - The challenge itself and the badge can be built now and work offline.
5. **The Hall of achievements, set in stone.** A place in the Sanctuary where every milestone is carved: evolutions, streak records, worlds opened, weekly badges. Somewhere to come back to and be proud of.
6. **Two kinds of progress, clearly separated:**
   - **Streak-based:** the Flame's evolutions.
   - **Coin-based:** new worlds and streak savers.

## 3. World map (notes: "floating worlds, PvZ roadmap-like, Flame reborn or a funny travel")

- **Floating worlds:** each realm is its own floating island in the sky, joined by a glowing road, like the Plants vs Zombies map: one clear path, world after world, with locked islands still in mist and their price shown.
- **Unlocking a world is a moment:**
  - the coins pour in, the mist lifts;
  - then your Flame **travels there with a funny little animation**: a hop along the road, a ride on a book, a puff of smoke;
  - and it is **reborn on the new island's circle**.
- Codex paints the floating-island map in the same pixel style.

## 4. Money (no subscription)

- **No paywall, no subscription, no trial** (Mathis). The whole game stays free.
- **From the notes: buying coins** at 2.99 CHF ("just enough to save your streak"), 9.99 CHF and 29.99 CHF.
- **Decided (151): buying coins will be added later (P5), not now.** Its exact shape is decided when it is built, since it touches earlier decisions:
  - decision 81: no paid progress;
  - decision 141: coins never sold for money;
  - decision 134: shields earned by living, never bought.

  Coins buy worlds and streak savers, so selling coins means selling progress and selling "not losing". That is the most profitable pattern (Duolingo sells streak freezes), and also the one most often called manipulative.
- **Possible options:**
  - **A. Two currencies (recommended):**
    - **coins** are earned only by living and buy worlds and streak savers, as now;
    - **gems** are bought with money and buy only cosmetics (Spark outfits, decorations, island skins). Never progress, never streak protection.

    Clean and fair, and it still earns. Finch earns over $30M a year selling joy, not protection.
  - **B. Your notes as written:** coins can be bought and spent on anything. Most revenue, but against decisions 81, 134 and 141, with a manipulation risk.
  - **C. Middle ground:** coins can be bought, but streak savers are capped (for example 2 a month) and worlds always need some coins earned by living.
- All paid features need the paid Apple program (P5) to sell in-app purchases. Until then they're designed and built, but not live.

## 5. The core loop (as discussed: choosing actions, tracking, the streak)

1. **A real quest library** across the six pillars:
   - each quest has steps, a "why", and levels from easy to stretch;
   - plus your own custom quests.
2. **A picker that knows you:**
   - it uses your Day 1 rating, your weakest pillar, your history and what you skipped;
   - a quest skipped three times is swapped for an easier version, never shamed.
3. **Tactile tracking:**
   - built-in timers for focus and breathing;
   - counters for reps and pages;
   - Apple Health for steps and workouts, so some quests tick themselves.
4. **Reminders:** one at your chosen moment, plus an evening nudge only when the streak is at risk.

## 6. Order of work (proposal)

1. **The core loop and the streak:** §5, then §2.1–2.3 (evolutions at 3/7/14/30/90, a goal always visible). Plus the daily layer from §1: the Flame's needs, the daily line, the immediate reward.
2. **The widget:** the Flame's vitality on the home screen, plus the icon changing at evolutions.
3. **The floating-world map,** the travel and the rebirth animation (§3), with Codex's art.
4. **The Hall of achievements, and weekly challenges** (offline first) (§2.4–2.5).
5. **Shop** for cosmetics bought with earned coins. Buying coins with money comes later (decision 151, P5).
6. **Sound, polish, a Codex review, then TestFlight with real users.**
