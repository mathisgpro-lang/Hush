#!/bin/zsh
# Relaunch any Codex job that was in flight when work paused.
# Called by Claude on "work again" (see CLAUDE.md, "Resume protocol").
# Each job: skip if its outputs already exist, otherwise rerun its saved brief.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"

run_brief() {  # $1 = brief file, rest = expected output files
  local brief="$1"; shift
  local missing=0
  for f in "$@"; do [[ -f "$ROOT/$f" ]] || missing=1; done
  if (( missing )); then
    echo "relaunching: $brief"
    local prompt="$(sed -n '/^---$/,$p' "$ROOT/$brief" | tail -n +2)"
    "$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" < /dev/null > /dev/null 2>&1
    echo "done: $brief"
  else
    echo "already complete: $brief"
  fi
}

run_brief docs/design/briefs/sanctuary.md \
  docs/design/sanctuary/stone-era-bright.png \
  docs/design/sanctuary/stone-era-embers.png \
  docs/design/sanctuary/metal-era-bright.png

run_brief docs/design/briefs/birth-storyboard.md \
  docs/design/birth/01-ember.png docs/design/birth/02-touch.png docs/design/birth/03-carving.png \
  docs/design/birth/04-dawn.png docs/design/birth/05-first-spark.png

run_brief docs/design/briefs/home-screen.md \
  docs/design/home/home-today.png docs/design/home/home-evening.png

run_brief docs/design/briefs/tracking-moment.md \
  docs/design/tracking/storyboard.png

run_brief docs/reviews/briefs/mvp-chapters-review.md \
  docs/reviews/2026-10-01-codex-mvp-chapters.md

run_brief docs/design/briefs/sanctuary-empty-pedestal.md \
  docs/design/sanctuary/stone-era-bright-empty.png docs/design/sanctuary/stone-era-embers-empty.png

run_brief docs/design/briefs/vessel-bodies.md \
  assets/flame/stone/vessel-body.png assets/flame/metal/vessel-body.png

run_brief docs/reviews/briefs/plan-2-review.md \
  docs/reviews/2026-10-01-codex-plan-2.md

run_brief docs/reviews/briefs/p2-plan-review.md \
  docs/reviews/2026-10-01-codex-p2-plan.md

# Style v2 assets (decision 113)
"$ROOT/scripts/style-v2.sh"
"$ROOT/scripts/spark-v3.sh"
"$ROOT/scripts/p25-iter2.sh"
"$ROOT/scripts/realms.sh"
"$ROOT/scripts/p26-art.sh"
"$ROOT/scripts/p26-tod.sh"

# Design & Feel cohesion frames first (decision 106)
"$ROOT/scripts/cohesion-frames.sh"

run_brief docs/reviews/briefs/p3-plan-review.md \
  docs/reviews/2026-10-01-codex-p3-plan.md

# P2 design round (decision 98)
"$ROOT/scripts/design-round-p2.sh"

# style tests (decision 75)
"$ROOT/scripts/style-tests.sh"
