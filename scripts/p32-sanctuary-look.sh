#!/bin/zsh
# P3.2 (Mathis, 2026-10-14): the Sanctuary must let you look around again, like the other worlds (decision 164: the
# world keeps going past the screen edges, never a border). Codex's composed stage (decision 170) fills the screen
# exactly, so its look-around range became zero. Codex owns this (visual integration). Re-run safe: skipped once
# docs/plan-2.0/p32-sanctuary-look.md exists. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
DONE=docs/plan-2.0/p32-sanctuary-look.md
[[ -f $DONE ]] && { echo "exists: $DONE"; exit 0; }
"$CODEX" exec -s workspace-write -C "$ROOT" -- "In the Swift app prototypes/p2-spikes/SpikeLab (the Hush game), give the Sanctuary (home, S2View.swift, your 'composedStage' framing from decision 170) its look-around back, exactly like the realms (S3View.swift): the player swipes left/right (and a little up/down) and the world slides, the same range and spring feel as the realms (EdgeSafety.lookAround, panLimit), and NO edge, border or black stripe ever shows at the furthest point (decision 164: the painting must reach past the screen edges, e.g. via overscan or extending the composed background). Keep everything else of your decision 170 composition: the Flame's size, ground anchor, light pool and look, the framing at rest, the quest panel and the 60 fps rule (decision 165: no blurred .shadow over the world). Do not change the quest panel, gestures in Shell/HomeView.swift or any other world. Verify: build for the iOS simulator (xcodebuild -scheme SpikeLab, from prototypes/p2-spikes) and launch with -skipintro -seedjourney -push left, then -push right (test flags that hold the view at its limit), take screenshots and check both edges show world, no stripe. Then write a short report to $DONE (what you changed, the screenshots you checked). Do not commit." < /dev/null > docs/reviews/p32-sanctuary-look.log 2>&1
[[ -f $DONE ]] && echo "done: $DONE" || echo "MISSING: $DONE (see docs/reviews/p32-sanctuary-look.log)"
