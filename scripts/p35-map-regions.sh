#!/bin/zsh
# P3.5 (decision 188, Mathis 2026-10-22): Codex reworks the world map, one region per world (design + integration).
# Brief: docs/reviews/briefs/p35-map-regions.md. Re-run safe: skips if the sketch and the region mask both exist.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
[[ -f docs/design/p35/map-regions-sketch.png && -f prototypes/p2-spikes/SpikeLab/Assets/map-regions.png ]] && { echo "already done: p35 map regions"; exit 0; }
mkdir -p docs/design/p35/verification
prompt="$(sed -n '/^---$/,$p' docs/reviews/briefs/p35-map-regions.md | tail -n +2)"
"$CODEX" exec -s workspace-write -C "$ROOT" --ephemeral "$prompt" < /dev/null > /tmp/p35-map-regions.log 2>&1
ls docs/design/p35/map-regions-sketch.png prototypes/p2-spikes/SpikeLab/Assets/map-regions.png 2>&1
