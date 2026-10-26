#!/bin/zsh
# P3.6 step 4 (decision 189): the art (scripts/p36-map-art.sh), then Codex builds the floating-islands map in the game.
# Brief: docs/reviews/briefs/p36-map-build.md. Re-run safe: skips the build once Shell/IslandMapView.swift exists and the
# plan holds Codex's report. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
"$ROOT/scripts/p36-map-art.sh"
if [[ -f prototypes/p2-spikes/SpikeLab/Shell/IslandMapView.swift ]] && grep -q "^## Codex report" docs/plan-2.0/p36-map-islands.md; then echo "already built: p36 map"; exit 0; fi
prompt="$(sed -n '/^---$/,$p' docs/reviews/briefs/p36-map-build.md | tail -n +2)"
"$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" < /dev/null > /tmp/p36-map-build.log 2>&1
ls -la prototypes/p2-spikes/SpikeLab/Shell/IslandMapView.swift docs/design/p36/verification 2>&1 | head -20
tail -3 /tmp/p36-map-build.log
