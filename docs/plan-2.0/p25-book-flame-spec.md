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

## 2. The Book: the story of the place you're in

- **Opens on the world you're standing in.** In the Sanctuary, it's the Sanctuary's pages; in the Grove, the Grove's.
- **Looks like** the satchel's journal: parchment, gold-leaf corners, a ribbon. Swipe to turn pages.
- **One chapter per world.** Each has four pages:
  1. **This place:** what the world is, in a few warm lines, with a painted vignette.
  2. **Its story:** the lore you've found here. Scenes you've seen can be replayed, such as the First Words in the Sanctuary. Pages you haven't found yet stay blank, with a soft hint.
  3. **What lives here:** the characters and spots. In the Grove: Nim & Ro, the Gathering, the quiet pool.
  4. **Your part in it:** what you've woken here, in plain numbers. In the Grove: "118 of 474 lanterns lit". It also says what wakes it next ("each kind word relights a lantern").
- **Locked worlds** have a chapter too: one page, written as a legend ("They say beyond the Highlands…") and what opens them. Never a grey lock screen.
- **Later**, the Chronicle of your weeks (Plan 2.0) becomes the Book's last section, so the story of the worlds and the story of your life live in one book.

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

### The open question: "days in a row"

Plan 2.0 (Part 1 and the intro spec) rules out streak counters. A streak that breaks makes people feel they've lost it all, which breaks a non-negotiable.

**Recommendation:** "This week" (seven flames that start fresh every Monday) plus "Days lived" (never goes down). They give the same pull without the punishment.

## Build order once approved
1. Both sheets in SwiftUI, with the stand-in icons.
2. The texts for the Sanctuary and the Grove.
3. The painted icons when Codex returns.
4. Mathis tries it on his phone.
