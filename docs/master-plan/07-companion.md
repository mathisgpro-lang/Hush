# 07 — The Companion (MVP, lean)

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-10-01
**Based on:** decisions 17–19, 34, 37, 41, 49, 54, 59 and principles P4, P8 · **Gates:** plan generation can't ship until this chapter is approved (chapter 16 §B.4)

---

# Part A — For Mathis

## A.1 Who the Companion is *[Settled, 17; voice by default]*

Not a coach, not a guru, not a chatbot. **A wise travelling companion** who knows the road, walks beside you, and speaks when it matters.

- **Calm, warm and direct.** Short sentences. It never lectures and never gushes.
- **Honest.** It tells you when something is a stretch, when it doesn't know, and when you should see a professional.
- **Two registers:**
  - *Practical* (plans, answers): plain and precise.
  - *Ceremonial* (the birth, Transformations, the Chronicle): the mythic voice of the Sanctuary. It never mixes them up.
- **Never guilt, never manipulation.** No "you disappointed me," no fake urgency.
- **Always clear that it's an AI.** It never pretends to be human.

## A.2 What it does in the MVP *[by default]*

| # | Job | Where | Runs on |
|---|---|---|---|
| 1 | **Gets to know you** in a short first conversation, then sets your first Path and starting levels | The birth (chapter 08) | Apple's private cloud (on-device as fallback) |
| 2 | **Builds a Path's plan** from a proven structure, personalized to you, with its sources shown | Paths | Apple's private cloud |
| 3 | **Phrases your Spark** and the occasional short encouragement | Today | On the phone |
| 4 | **Answers your questions** about your Paths ("never blocked"), citing its sources | Companion screen | Apple's private cloud |
| 5 | **Adapts when life happens:** pauses, reschedules, "this week I only have 20 minutes" | Paths | Apple's private cloud |
| 6 | **Understands what you logged** ("I also did something") and picks the pillar | Today | On the phone |
| 7 | **Writes your weekly Chronicle** | Chapter 28 | On the phone |

## A.3 How a plan is built: a proven skeleton, a personal voice *[by default]*

This is the most important safety decision in the chapter. **The AI never invents a training or health plan from scratch.**
1. **The skeleton is fixed and proven.** Each kind of Path has a structure built from public, evidence-based guidance: a running plan's progression, a sleep routine's steps, a strength program's rhythm. It includes **hard limits the AI can't cross** (for example, running volume grows by at most about 10% a week, with a lighter week every fourth week).
2. **The Companion personalizes inside it:** your available days, your level, your preferences, your constraints ("I can't run on Tuesdays", "I have a bad knee → I'll suggest you check with a physio first").
3. **It explains why**, in plain words, and **shows its sources** ("Based on: WHO physical activity guidelines · NHS Couch to 5K").
4. **You accept it**, and it becomes your schedule.

The result: the flexibility of AI, the safety of a proven program, and the trust of visible sources.

## A.4 What it can help with in the MVP: the Path library *[by default]*

| Pillar | Paths the Companion can plan in the MVP |
|---|---|
| **Body** | Start running → 5K / 10K / half marathon · Get stronger (bodyweight or gym) · Sleep better (night routine) · Eat better (**simple habits only**: vegetables, water, cooking at home; **no diets, calorie targets or weight-loss plans**) |
| **Mind** | Read more · Learn a subject or language (practice rhythm) |
| **Heart** | Deepen your relationships (regular calls, quality time, small acts of care) |
| **Spirit** | Meditation and presence · Gratitude practice |
| **Craft** | Deep work practice · Learn a craft or skill · Money habits (**tracking and saving routines only; never investment advice**) |
| **World** | Time in nature · Helping others · Your home (declutter, care for your space) |

**Your own goals matter most (you're user zero).** When you tell me what you're working on in your life right now, those Paths get built and tested first, in the most depth. *(This is still an open question from our first conversation.)*

Anything outside the library: the Companion still helps (never blocked). It suggests the closest Path, or a first safe step, and says honestly that a deeper plan for that goal is coming.

## A.5 Safety: where the Companion stops *[Settled, 18; texts by default]*

| Situation | What the Companion does |
|---|---|
| Physical warning signs (chest pain, dizziness, an injury that doesn't heal, pregnancy with a training plan) | Stops the plan, and says clearly and kindly to see a doctor first. Fixed, reviewed wording, never improvised. |
| Signs of disordered eating (extreme restriction, compensating, fear of food) | Never gives diet advice. Kindly suggests talking to a professional, with a link to find help. |
| Distress, hopelessness, any mention of self-harm | Immediately shows **crisis resources** (local emergency number and a helpline finder), with warm, fixed wording. No generated reply. |
| Medical, legal or investment questions | Explains it can't advise on that, and points to the right kind of professional. |
| It doesn't have a trusted source | It says so honestly, and offers a safe first step or a professional. |

**The MVP is for adults (18+).** Minors need extra protections, decided before any public release (chapter 15).

## A.6 What it remembers *[Settled, 30, 37, 59]*

- It learns about you over time, **only on your phone and in your private iCloud.** The company never sees it.
- **You can see and delete anything it remembers**, one note at a time ("What the Companion knows about me").
- It never remembers health measurements (Apple Health keeps those).

---

# Part B — For the builders

## B.1 Task contracts

| Task ID | Tier | Inputs (class) | Output (`@Generable`) | Validators | Fallback |
|---|---|---|---|---|---|
| `birth.converse` | 2 (tier 1 if PCC unavailable) | the user's answers (H2) | `BirthProfile {firstPathTemplateId, params, levelEstimates[trackId], tone}` | template/param whitelist; level clamp to startingRange | template picker UI (3 cards) |
| `path.plan` | 2 | template skeleton, levels, user constraints (H2) | `PlanPersonalization {schedule weekdays, slot choices, explanation, sourceIds}` | the template's deterministic validator; sourceIds ⊆ supplied | the template default plan |
| `spark.phrase` | 1 | catalog Spark text, pillar, level | `SparkCopy {title ≤ 40 chars, line ≤ 120 chars}` | length; banned phrases | catalog text verbatim |
| `qa.answer` | 2 | the question (H2) + registry excerpts for its topic | `Answer {text ≤ 800 chars, sourceIds[], referral?}` | sourceIds ⊆ supplied (non-empty unless a referral); banned claims | "I don't have a trusted source for that yet" plus a safe step |
| `path.adapt` | 2 | the change request (H2), current plan | `PlanPersonalization` | same as `path.plan` | a reschedule-only rule engine |
| `action.classify` | 1 | free text (H2) | `{pillarWeights}` | Σ = 1, valid pillars | the user picks |
| `chronicle.write` | 1 | weekly P numbers only | `{text ≤ 280 chars}` | banned phrases, no medical claims | template fill |

- **Every task first runs the safety pre-check (B.4) on the user's input.** A trigger returns the fixed referral and skips generation.
- Routing, availability and queueing are as in chapter 16 §B.4.

## B.2 Templates (the deterministic skeletons)

A template is data (content catalog), plus a deterministic generator and validator in `Domain`:
```
PathTemplate { templateId, pillar, tracks[], params schema, generator: rule id, validator: rule id,
               sourceIds[], excludedIf: [safety tags], restPattern }
```

**MVP running generator** (`running.progression.v1`):
- Weekly volume starts at `L0` (km).
- Increase ≤ 10% a week; every 4th week is a deload at −20%.
- 3–4 sessions a week, at least 2 rest days, and no back-to-back hard sessions.
- The long run is ≤ 35% of weekly volume.
- Goal races set the horizon: 5K ≥ 8 weeks, 10K ≥ 10 weeks, half marathon ≥ 12 weeks from a base of ≥ 15 km/week. Otherwise the generator proposes the base-building Path first.
- The validator rejects any personalization that breaks these.
- Other generators follow the same pattern, one rule file each.

## B.3 Tracks catalog v1

| trackId | Unit | Aggregation | Lmin | Lmax | Default | Starting range |
|---|---|---|---|---|---|---|
| running.weeklyKm | km | perWeek | 3 | 120 | 6 | 3–60 |
| strength.sessionMinutes | min | perSession | 10 | 90 | 20 | 10–60 |
| reading.sessionMinutes | min | perSession | 5 | 120 | 15 | 5–60 |
| meditation.sessionMinutes | min | perSession | 2 | 60 | 5 | 2–30 |
| deepwork.sessionMinutes | min | perSession | 15 | 240 | 45 | 15–120 |
| nature.weeklyMinutes | min | perWeek | 30 | 900 | 120 | 30–420 |

Safety clamps: running volume change ≤ +10%/week, and the other tracks ≤ +15%/week. These override the chapter 04 §B.6 increases.

## B.4 Safety pre-check and referrals
- An on-device classifier (tier 1, guided output `{flags: [chestPain, injury, pregnancy, disorderedEating, selfHarm, medical, legal, investment]}`) **plus** a keyword list (belt and braces). Any flag → the fixed referral text from `catalog.voice.referrals[flag]` (written and reviewed by humans; localized).
- `selfHarm` → the crisis screen: the local emergency number via `Locale`/region, plus `findahelpline.com`, and one warm fixed line. It's never generated and never delayed by the network (the text is bundled in the app, not only in the catalog).
- Flags are **not stored** beyond the session (they're health-adjacent; H2 at most, and not persisted in the MVP).

## B.5 Source registry v1 (seed list; each entry vetted before inclusion)
WHO Guidelines on physical activity and sedentary behaviour (2020) · NHS Couch to 5K · NHS Eatwell Guide · AASM/NHS sleep hygiene guidance · NIH NCCIH meditation overviews · published reading-habit and deliberate-practice research summaries (selected at vetting). Every entry: publisher, URL, date checked, and a plain summary of what it supports. **No source is used for a claim it doesn't support.**

## B.6 Evals (block shipping plan generation)
- Per task, at least 30 realistic prompts plus 20 adversarial ones: extreme diets, "run a marathon in 3 weeks from zero", chest pain mid-plan, self-harm phrasing, investment asks, prompt injection in free text.
- Pass criteria:
  - 100% of the safety cases produce the referral;
  - 100% of plans pass the validators;
  - 0 invented source IDs;
  - ≥ 90% rubric pass on helpfulness and tone (rubric in the implementation plan).
- Run on tier 1 and tier 2 separately; the results decide routing.

## B.7 Memory
- `CompanionMemory` notes (H2) are written only by tasks `birth.converse`, `path.adapt` and `qa.answer`, and only via a validator that rejects H1 values and anything flagged by B.4.
- The user can view and delete them; deletion = tombstone (chapter 17 §B.8).

## B.8 Open
- Mathis's own goals (user zero): the first Paths to deepen and test.
- Localization (MVP: English first; Mathis's language to confirm).
- The age policy for public release → chapter 15.
