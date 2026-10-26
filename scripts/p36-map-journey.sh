#!/bin/zsh
# P3.6 (decision 190, Mathis 2026-10-24): Codex reworks the map as a journey (the Flame travels, progress plays out,
# a new painted sky, 60 fps). Brief: docs/reviews/briefs/p36-map-journey.md. Re-run safe: skips once the plan holds
# "## Codex journey pass". In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
grep -q "^## Codex journey pass" docs/plan-2.0/p36-map-islands.md && { echo "already done: p36 journey"; exit 0; }
prompt="$(sed -n '/^---$/,$p' docs/reviews/briefs/p36-map-journey.md | tail -n +2)"
"$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" < /dev/null > /tmp/p36-map-journey.log 2>&1
grep -q "^## Codex journey pass" docs/plan-2.0/p36-map-islands.md && echo "journey pass done" || { echo "journey pass MISSING"; tail -3 /tmp/p36-map-journey.log; }
