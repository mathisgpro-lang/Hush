# The World, the Book and Your Flame (the home bar), spec draft (2026-10-03)

*Source: Mathis (2026-10-03): design the World map, Book and Flame icons. The Book tells everything about the world you're in. The Flame sums up where you are in your journey. Status: **approved 2026-10-03 (decisions 128–129)**. The Book is written as you live (§2 rewritten by decision 129).*

## 1. The three painted icons

They are painted in the same style as the satchel, by Codex, on a magenta background. Codex is blocked until 2026-10-07 20:15; the job is queued in `scripts/p25-iter2.sh`.

| Icon | What it is |
|---|---|
| **World** | A small rolled map tied with a cord, with a tiny glowing compass rose. A badge glows when something new waits out there. |
| **Book** | A thick leather tome with an ember-glass clasp and a ribbon. Its clasp glows when a new page has been written. |
| **Your Flame** | The Spark itself, as a little round medallion: it *is* you. It is never a generic flame symbol. |

Until Codex delivers, the bar uses stand-ins from the art we already have:
- the Spark's face for **Your Flame**;
- a round crop of the map for **World**;
- the scroll prop for **Book**.

## 2. The Book writes itself as you live (decision 129)

- **It starts almost empty.** Page one is written the night your Spark is born, using your name and your ember.
- **Every page comes from something you really did, on that day**, in the story's voice and with your words in it:
  - your first quests;
  - each day lived (its page fills up as the day goes on);
  - the first time you saw the Emberlands;
  - the first time you entered the Grove;
  - each lantern your kindness relit.
- **Chapters are the worlds you've been to**, in the order of the road. It opens on the world you're in, at the latest page.
- **The last page is always blank:** "The next page is yours to write."
- **Built:** `Shell/Journey.swift` (the record, kept on the phone) and `Shell/BookView.swift` (the parchment book).
- **Later:** the scenes you've seen (the First Words) can be replayed from their pages, and more moments write pages (naming the Flame, each new realm, the weekly Gathering).

## 3. Your Flame: where you are in your journey

It opens as a full sheet with the Spark large and alive at the top. It reacts when you open it.

| Part | What it shows |
|---|---|
| **Stage** | "Spark · day 5". A strip of the five stages: yours glows, the next is a silhouette with how close it is. |
| **This week** | Seven little flames, Monday to Sunday, lit on days you did something real. Missed days are simply unlit; the week starts fresh. |
| **Days lived** | The total number of days you've lit. It only grows. |
| **Your six lights** | The six pillars (Body, Mind, Heart, Spirit, Craft, World), each with its level and a short glowing bar. Its realm's name sits beside it (Heart, the Whispering Grove). |
| **Vitality** | How bright you've been lately, in one sentence ("Bright: you've lived 5 of the last 7 days"). |
| **Next** | One line about the next milestone ("In 2 days, I'll want a name"). |

### Settled: no "days in a row" (decision 128)

Plan 2.0 (Part 1 and the intro spec) rules out streak counters. A streak that breaks makes people feel they've lost it all, which breaks a non-negotiable.

**Recommendation:** "This week" (seven flames that start fresh every Monday) plus "Days lived" (never goes down). They give the same pull without the punishment.

## Build order once approved
1. Both sheets in SwiftUI, with the stand-in icons.
2. The texts for the Sanctuary and the Grove.
3. The painted icons when Codex returns.
4. Mathis tries it on his phone.
