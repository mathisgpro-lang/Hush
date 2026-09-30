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
    "$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" > /dev/null 2>&1
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

run_brief docs/design/briefs/stone-vessel-assets.md \
  assets/flame/stone/vessel-body.png assets/flame/stone/vessel-rim-light.png assets/flame/stone/fire-core.png \
  assets/flame/stone/ember-core.png assets/flame/stone/veins-body.png assets/flame/stone/veins-mind.png
