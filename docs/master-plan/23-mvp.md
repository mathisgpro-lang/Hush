# 23 — The MVP

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-10-01
**Based on:** every chapter on the MVP track (03, 04, 05, 06, 07, 08, 12, 28) and the approved foundation (16, 17, 20, 22; decision 66)

---

# Part A — For Mathis

## A.1 What the MVP is for *[Settled, 21, 46]*

**To prove the core loop with real people**, starting with you: a day handed to you → doing real things → the tracking moment → your Flame visibly deepening → wanting to come back tomorrow, for weeks.

It's **not** the end product. It's the smallest version that can answer: *does this make people's growth visible, and do they love it?*

## A.2 Who uses it *[by default]*

| Stage | Who | How | Cost |
|---|---|---|---|
| **0. Feel prototype** | You | Your iPhone, via Xcode and a cable | Free |
| **1. User zero** | You | Your iPhone, the real MVP, for 2–4 weeks | Free (7-day re-sign) |
| **2. Private beta** | You + **5–15 adults you choose** | TestFlight | $99/yr Apple Developer Program |

## A.3 What's in, and what's not *[by default]*

**In the MVP:**

| Area | Included |
|---|---|
| **The birth** | The full first launch: ember, birth, first conversation, first Path, first spark (ch. 08) |
| **The Flame** | Fire and vessel; six pillar motifs and fire colors; a unique seed; the spark-to-vessel growth; touch and hold (ch. 03) |
| **The Sanctuary** | The Stone and Metal Eras in full; Crystal and Light as glimpses; breathing with Vitality (ch. 28) |
| **Growth** | Depth, Vitality with the comeback, Ascent (the 1% number), levels that adapt (ch. 04) |
| **Your day** | Up to 3 Paths, the Spark with swap, the weekly Ritual, free Actions, pause, "Close the day" (ch. 05) |
| **The tracking moment** | Full sensory design: haptics, sound, motion, pillar voices, the special moments (ch. 06) |
| **The Companion** | 7 jobs; plans built on proven skeletons; Q&A with sources; safety referrals; memory you can see and delete (ch. 07) |
| **Path library** | **8 Paths at launch:** Start running (→ 5K/10K/half), Get stronger, Sleep better, Read more, Meditation, Deepen your relationships, Deep work, Time in nature, **plus the Paths for your own goals** |
| **Eras and Relics** | Stone → Metal (the first Transformation ceremony, and the icon change); one earnable fire style (the first Ritual) |
| **Discovery** | The veiled next Era; six Hidden Sparks; the weekly Chronicle |
| **Apple Health** | Reading only: verification and starting levels |
| **Your data** | On your phone plus your private iCloud; export; delete everything; works fully offline |

**Not in the MVP** (all planned for later, and the architecture leaves room for each):
- friends, profiles, sharing and public status;
- brand and expert partnerships;
- frontier AI (Claude, etc.);
- Android, web, iPad, Watch and widgets;
- payments and subscriptions;
- analytics of any kind;
- Seasons, the lore codex and the rest of the Eras;
- more Paths;
- languages beyond English (pending your answer).

## A.4 How it gets built: the milestones *[by default]*

Each milestone ends with something **you try on your phone** (decision 39).

| # | Milestone | You'll be able to… |
|---|---|---|
| **M0** | **Feel prototype** *(throwaway)* | Hold a first Flame, feel the tracking moment and the comeback, and tell me what to change |
| **M1** | The foundation | *(Invisible)* The brain and the permanent record, proven by hundreds of automated tests |
| **M2** | The Flame and the Sanctuary | See your real Flame in the Stone Era Sanctuary, reacting to Vitality |
| **M3** | Your day and the tracking moment | Live a full day: Paths, the Spark, completing, "Close the day," pause |
| **M4** | The birth and the Companion | Experience the birth from zero; get a real plan with sources; ask questions |
| **M5** | Sync and privacy | Use two devices; delete everything; export; go without iCloud |
| **M6** | Apple Health | See your runs verified; start at your real level |
| **M7** | The adventure | The Ritual with a live count, the first Relic, Hidden Sparks, the Chronicle, **the Metal Era ceremony** |
| **M8** | Beta-ready | Everything reviewed, tested and hardened → TestFlight → your circle |

**An honest time estimate:** the AI agents build quickly. The real pace is set by your reviews (1–2 hours a day), the art, and Apple's approvals. **Roughly 2–3 months from M0 to the private beta** is a realistic target, not a promise. M0 can be in your hand within days.

## A.5 What success looks like *[by default]*

**For you (user zero, stage 1):**
- You use it **daily for 30 days without it feeling like a chore**.
- You say the tracking moment is *the part you love*.
- You'd genuinely miss it if it disappeared.

**For the private beta (stage 2, 6–8 weeks):**
- At least **60% of testers still active in week 4.** Most habit apps lose the majority in week one.
- In interviews, most testers describe their progress as **visible**, not just tracked.
- At least **one comeback per tester feels good**, not shameful (we ask).
- **Zero data loss, zero privacy incidents, and zero unsafe Companion outputs** found.

## A.6 What we need, and when *[by default]*

| Need | When | Cost |
|---|---|---|
| Xcode 27 + license | Done ✅ | Free |
| iPhone on iOS 27, Developer Mode on, a cable | Before M0 on your phone | Free |
| **Apple Developer Program** | Before **M5** (reliable iCloud testing), **M6** (the App Review health question) and **M8** (TestFlight) | **$99/yr** |
| The App Review health answer | Before M6 | Free (draft ready) |
| Private Cloud Compute access | Before M4's cloud tasks (on-device works first) | Free (Small Business Program) |
| Cloudflare account for the Relay | M7 | Free tier expected |
| Art | M2 onwards: Codex first; a human artist for the final Flame if needed | Budget to decide |
| Your own goals (user zero) | Before M4 | 5 minutes of your time |

---

# Part B — For the builders

## B.1 Milestone acceptance criteria

| M | Must be true to close it |
|---|---|
| M0 | Runs on device; press-hold-release completion with haptics and sound; the Flame (placeholder art acceptable) reacts; comeback simulation (a debug time-travel control); **the chapter 06 §B.5 questions answered by Mathis**; code deleted or archived and **never merged into `app/`** |
| M1 | `Domain` implements chapter 04 exactly, with all reference vectors V1–V13 ported as tests plus the entry-level fixtures (decision 60); `RecordStore` passes the append-only triggers, corrections, lived-day v2 and the export round trip; ≥ 95% line coverage in `Domain` |
| M2 | `FlameKit` renders from `FlameInputs` deterministically (snapshot tests per seed); `Theme` tokens with no hard-coded values (lint); Stone Sanctuary with Vitality atmosphere; 60 fps on the target device |
| M3 | Dealing (ch. 05 §B.1) and materialization (ch. 04 §B.1); swap; pause; the tracking moment timing contract (ch. 06 §B.1); a no-network test on the path; close the day |
| M4 | The birth state machine with resume; `birth.converse`, `path.plan`, `qa.answer`, `spark.phrase`, `action.classify`; the safety pre-check; **the ch. 07 §B.6 evals pass**; the source registry v1 vetted |
| M5 | CKSyncEngine with the outbox; generation lifecycle; deletion protocol; account isolation; iCloud-off mode; both `HealthFactSyncMode`s; **all chapter 22 §B.4 scenario tests for sync, deletion, accounts and import pass on real CloudKit (test container)** |
| M6 | HealthKit read with the trusted-source allowlist; the suggestion flow for auto-detected workouts; L0 seeding; H2 isolation and the backup-exclusion test |
| M7 | The Relay (App Attest, Ritual join/count, the catalog route); the first Ritual and Relic; Hidden Sparks; the Chronicle; the Stone → Metal ceremony with the alternate icon |
| M8 | The full chapter 22 §B.4 matrix green; Codex review of the whole app; the chapter 20 §B.4 items relevant to TestFlight done (privacy policy, beta terms); crash-free for 7 days of Mathis's daily use |

## B.2 Dependencies
M0 → (feel values) → M2, M3. M1 → everything. M2 ∥ M3 after M1. M4 needs M3. M5 can run in parallel with M4 after M1. M6 needs M5 plus the Apple answer. M7 needs M3 and M5. M8 needs all.

## B.3 Out of scope (explicit, so agents never add them)
Accounts or sign-in, any analytics or third-party SDKs, push notifications (local only), frontier AI, social features, payments, widgets or a Watch app, iPad layouts, localization beyond the string catalog scaffolding.
