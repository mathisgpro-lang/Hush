# 08 — The Birth of Your Flame (first launch)

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-10-01
**Based on:** decisions 5, 33, 40, 54, 61, 64 and principles P15–P16 · **Research:** §A.1

---

# Part A — For Mathis

## A.1 What the best apps teach us (research, 2026-10-01)

- **Value before sign-up.** Duolingo runs your first lesson before it asks for an account; deferring sign-up is reported to lift activation by 10–30%. *We go further: there's no account at all* (decision 33).
- **A conversation beats a quiz.** Opal replaced its onboarding questionnaire with a chat you interact with.
- **Birth creates attachment.** Finch starts not with features but with *hatching* your companion, so the whole experience is framed around care from the first minute.
- **Feeling capable in session one** is what brings people back for session two. Personalizing the first session is reported to improve 30-day retention substantially.

Sources: [Appcues: onboarding examples](https://www.appcues.com/blog/best-user-onboarding-examples) · [Retention.Blog: chat-based onboarding](https://www.retention.blog/p/chat-based-onboarding) · [Opal onboarding analysis](https://substack.com/home/post/p-156836749) · [Finch design critique](https://ixd.prattsi.org/2026/02/design-critique-finch-self-care-pet-ios-app/) · [Playio: first-session design](https://blog.playio.co/mobile-game-onboarding-retention)

## A.2 The birth, step by step *[by default]*

**Goal:** within about 3 minutes, you've witnessed your Flame's birth, told the Companion what matters, chosen your first Path, and **done your first real Action**. No forms, no account, no wall of permissions.

**1. Darkness and an ember** (about 20 seconds)
The screen is black. Wind. A faint heartbeat in your hand. One ember glows in the middle. Words appear slowly, one line at a time:
> *Every person carries a flame.*
> *Most never see it.*
> *Here, yours is given a vessel.*

A small line at the bottom: *"Private beta · for adults 18+ · by continuing you accept the beta terms."*

**2. The birth** (about 20 seconds)
*"Touch the ember."* You press and hold. The haptic builds like a rising heartbeat, the ember swells into a living fire, and **raw stone is carved around it, grain by grain**, into your vessel. It's unique from this moment (its seed). Dawn breaks over the Sanctuary around it.
> *It will never be finished. It will never go out.*

**3. The first conversation** (about 1 minute)
The Companion speaks for the first time:
> *Before we begin: what would make this year feel truly alive?*

You type freely, or tap one of the suggestions ("Get fit," "Sleep better," "Read again," "Be closer to the people I love," "Learn something new," "Find calm"…). At most three more short exchanges:
- *What usually gets in the way?*
- *On a normal day, how much time is truly yours?*
- if it's relevant, *Where are you starting from?*

**4. Your first Path** (about 20 seconds)
A card appears, for example: *"Your first Path: Start running → your first 5K. Three short runs a week. Based on: NHS Couch to 5K · WHO guidelines."* Accept it, or adjust it with one tap ("fewer days," "something else").

**5. Let your Flame see what you already do** (optional, about 10 seconds)
*"Apple Health already knows how you move and sleep. Letting your Flame read it means you won't start from zero, and your runs can count automatically. It never leaves your phone."* Allow, or *Not now*. Either way works.

**6. Your first spark** (about 30 seconds)
> *One thing, right now.*

A tiny first Action from your Path's world, doable in a minute: *"Close your eyes. Three slow breaths."*, *"Drink a full glass of water."*, *"Stand, stretch, reach for the sky."* You do it, then press and hold, and **the first spark flies into your vessel. The first line is carved.** Your growth number appears for the first time: **×1.00 → ×1.003.** You've already begun.

**7. When should your day be ready?** (about 10 seconds)
A time picker for the morning notification, or *Not now*.

**8. Home.** The Sanctuary in full, your Flame at its heart, and tomorrow's first Spark veiled and waiting.
> *Your journey starts now.*

## A.3 What we deliberately don't do *[by default]*

- **No account, no email, no password.**
- **No questionnaire, no progress bar of questions.**
- **No permission requests up front.** Each permission is asked only at the moment it makes sense, with a reason.
- **No naming the Flame.** It isn't a pet; it's *you*.
- **No feature tour.** Everything else is discovered by living it (P16).

## A.4 Special cases *[by default]*

| Case | What happens |
|---|---|
| You skip the conversation | Three Path cards to pick from, and you continue |
| No internet / AI unavailable | The on-device AI runs the conversation; if that's unavailable too, the three cards |
| New phone, same iCloud | **No rebirth.** Instead, a reunion: the vessel reassembles from its pieces and the fire relights. *"Welcome back."* |
| You say something alarming in the conversation | The safety rules from chapter 07 apply immediately |

---

# Part B — For the builders

## B.1 State machine

`ember → birth → converse → firstPath → health? → firstSpark → notify? → home`
- The state is persisted after each step (local P setting `birthStep`). A kill or relaunch resumes at the same step.
- **Reunion detection:** on first launch, if iCloud is available, fetch `Meta`. If a current generation exists with `flameBorn`, run the reunion (sync, then animate) instead of `ember`.

## B.2 Entries written

| Step | Entries |
|---|---|
| birth | `flameBorn { seed: 128-bit CSPRNG, bornAt }` (P). The seed feeds chapter 03 B.1. Generation creation (chapter 16 §B.9) runs first if needed. |
| converse | the BirthProfile (H2 attachment), CompanionMemory notes (H2, via the chapter 07 §B.7 validator), `levelSeeded` (H2) |
| firstPath | `pathStarted` + the plan revision (H2) + `scheduleIssued` (P), via the cross-store command (chapter 17 §B.8) |
| firstSpark | `dayPlanned` for today (if not yet dealt) including the "first spark" slot (`kind: spark`, `d = 1.0`, catalog `firstSparks[]`), then `actionCompleted` |
| notify | `Setting notifyTime` |

- **The first day's growth** follows chapter 04 exactly (it's a partial day: the Spark is complete and the Path slots may still be open).

## B.3 Conversation task
- `birth.converse` (chapter 07 §B.1), at most 4 user turns, and at most 90 s of model time in total.
- Suggestion chips come from `catalog.voice.birthSuggestions[]`.
- The mapping from BirthProfile to a template is validated against the template whitelist.

## B.4 Timing and feel
- Steps 1–2 must work fully offline, with zero network. They're the most important seconds in the app.
- Sensory events: `press`, a special `birthCharge` (a rising heartbeat crescendo, ~3 s), `birthCarve`, `ignite`, `land`. These are specified in the theme bundle for stage 1.
- Words appear at ~1 line per 1.6 s, and any line can be skipped by tapping.

## B.5 Tests
- Kill and relaunch at every step → it resumes correctly.
- Offline birth with no AI → the card fallback.
- Reunion on a second device with the same iCloud.
- HealthKit denied → continues without it.
- A safety-flagged answer mid-conversation → the referral shows and the birth can still continue afterwards.
