# The Introduction, Finch-style (decision 114)

*Replaces the first-minutes storyboard (P2.5 spec B.1) with Finch's proven structure, keeping only our Flame, our lore and our world. Source: Mathis's Finch screen recording (2026-10-02).*

## What we take from Finch
- **One thing per screen:** the Flame centered in the upper half, a short title, one or two lines, and one big button at the bottom. Calm, airy, minimalist.
- **The character is always there and reacts to every choice** (a pose, a look, a giggle).
- **A personal, tactile birth:** choose your ember, warm it, it cracks, light rays burst, it's born.
- **It talks to you in speech bubbles** and asks your name.
- **An immediate small reward** after the first answer.
- **A short guided "learn about you"** with a progress bar, then "preparing your first days" and a starter list.

## What we leave out (our principles)
No account, no paywall or "one-time offer", no streak counter, no fake social proof, no attribution survey.

## Look
- **Minimal, in our palette:** a soft dusk gradient (violet → peach, the style bible tokens) instead of Finch's white, a few drifting embers, lots of space.
- **Type:** an elegant serif for titles; short body text.
- **Buttons:** warm gold, large, at the bottom.
- **The world itself is held back** until the end: the first time you see the Sanctuary is the reward.

## The flow (about 2 minutes)
| # | Screen | You do | The Flame |
|---|---|---|---|
| 1 | **Welcome:** a breathing ember. *"Every person carries a flame."* | **Light your ember** | — |
| 2 | **Choose your ember:** six embers around the center, each a pillar color with one word (Love, Curiosity, Strength, Calm, Craft, Wonder). *"Which light are you drawn to?"* | Tap one; it glows big in the center. **This is the first discovery signal** (decision 92), never a lock-in | — |
| 3 | **Warm it:** *"Hold it close. Keep it warm."* | **Hold** (our core gesture): rising haptics, cracks spread | — |
| 4 | **The birth:** light rays burst, the Spark pops out. *"Your Flame is born."* | Next | Hops, blinks, looks at you |
| 5 | **Hello:** a speech bubble (Emberspeak melting into English). *"…Oh! There you are. I'm your Flame. What's your name?"* | Type your name | Tilts its head, then giggles |
| 6 | **What am I?** *"Nice to meet you, {name}. Do you know what I am?"* Two answers: *"The part of me that's alive"* / *"A little fire that grows when I do"* | Tap one (both are right) | Glows: **"+1 light. Your Flame's first light"** |
| 7 | **Foreshadowing: growing.** *"I'm tiny now. But I'll grow as you grow."* A strip of five silhouettes: Spark (lit) → Flame → Blaze → Kindled → ? (dim). *"It'll take real days. That's the point."* | Next | Looks at the strip |
| 8 | **Foreshadowing: the world.** *"Out there, the world went quiet. Every real thing you do wakes a piece of it."* A small round window onto the misted Emberlands; the realm of your chosen ember glimmers | Next | — |
| 9 | **Mornings:** *"Can I bring you your day each morning?"* | Turn on / Maybe later | Hopeful look |
| 10–12 | **Learn about you** (progress bar, three questions): *What would make this year feel alive?* (multi-select, the six interests) · *On a normal day, how much time is truly yours?* · *Where are you starting from?* | Tap answers | A "?" while it listens; it reacts to each answer |
| 13 | **Preparing:** a ring fills around the Flame. *"Preparing your first days…"* | — | Bounces |
| 14 | **First light list:** a parchment with 3 small first things matched to your answers. *"In a few days, I'll want a name."* | **Let's begin** | — |
| 15 | **The world reveal:** the screen opens into the Sanctuary at dusk; your Flame lands on the stone circle; the first task object waits | Home | — |

## Lore kept
- **Naming waits for the Flame stage** (day 7, Character Bible §5). The intro foreshadows it instead of doing it now.
- The Hush, the Beacons and "a tool, not a cage" come later, as moments in Act I.
EOF
python3 - <<'EOF'
p='/Users/mathis/AI Projects/Hush/docs/vision/decisions-log.md'
new='| 114 | **The introduction follows Finch\'s approach** (Mathis: "look at how Finch did it, follow the same approach but only with our little flame… consistent with the current lore and world… some foreshadowing… keep it simple and minimalist"). Spec `docs/plan-2.0/intro-finch-spec.md`: one thing per screen on a soft dusk gradient; choose your ember (six pillar colors: the first discovery signal) → hold to warm it → cracks → light rays → the Spark is born → a speech bubble asks your name → "what am I?" (+1 light) → foreshadowing of the stages (silhouettes) and of the misted world → morning notifications → three quick questions with a progress bar → "preparing your first days" → a first-light list → the world reveal (the Sanctuary). Left out: account, paywall, streaks, fake social proof, attribution survey. [by default] Naming stays at the Flame stage (lore) and is foreshadowed. Replaces the P2.5 B.1 storyboard. | 2026-10-02 |\n'
s=open(p).read(); s=s.replace('|\n\n**Vocabulary:**','|\n'+new+'\n**Vocabulary:**',1); open(p,'w').write(s)
open('/Users/mathis/AI Projects/Hush/docs/vision/conversation-log.md','a').write('- **Finch intro (114):** Mathis shared a Finch onboarding recording; Claude mapped its structure (one thing per screen, choose and hatch an egg, a talking pet, an instant reward, a short questionnaire, a starter plan) onto our Flame and lore, dropped Finch\'s account, paywall and streak tactics, and added foreshadowing of the stages and the world.\n')
EOF
cd "/Users/mathis/AI Projects/Hush"; git add -A docs && git commit -q -m "Decision 114: the Finch-style introduction spec" && echo ok