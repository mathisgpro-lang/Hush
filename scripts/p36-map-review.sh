#!/bin/zsh
# P3.6 step 6 (decision 189): Codex reviews Claude's build of the floating-islands map against its sketches and fixes
# what differs. Brief: docs/reviews/briefs/p36-map-review.md. Re-run safe: skips once the plan holds "## Codex review".
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
grep -q "^## Codex review" docs/plan-2.0/p36-map-islands.md && { echo "already reviewed: p36 map"; exit 0; }
prompt="$(sed -n '/^---$/,$p' docs/reviews/briefs/p36-map-review.md | tail -n +2)"
"$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" < /dev/null > /tmp/p36-map-review.log 2>&1
grep -q "^## Codex review" docs/plan-2.0/p36-map-islands.md && echo "review done" || { echo "review MISSING"; tail -3 /tmp/p36-map-review.log; }
