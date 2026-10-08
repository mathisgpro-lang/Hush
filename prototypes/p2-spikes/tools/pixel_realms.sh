#!/bin/zsh
# Rebuild every realm from Codex's pixel art (decision 149). Run from prototypes/p2-spikes.
cd "$(dirname "$0")/.."
b() { [[ -f ../../docs/design/p29/px-$1.png ]] || { echo "$1: no pixel art yet"; return; }
  python3 tools/build_realm.py "$@" --pixel 2>&1 | grep -v -i deprec | grep -v fromarray | grep -E "pixel grid|lights" | tr '\n' ' ' | sed "s/^/$1: /"; echo
  python3 tools/build_life.py $1 --fresh 2>&1 | grep floaters; }
echo '{"flowers": true}' > tools/life/library.json                    # (no cut-outs on pixel art: crisp)
b library 0.5 0.25 --no-water --min-light 10 --light-contrast 0.15 --max-lights 120
b stillwater 0.5 0.315 --water-band 0.38,0.62 --water-hue 0.55,0.2 --smooth 0.3 --min-light 10 --max-lights 80
b highlands 0.5 0.28 --min-light 10 --light-contrast 0.2 --max-lights 80
b wilds 0.5 0.41 --water-band 0.72,1.0 --water-hue 0.55,0.13 --smooth 0.35 --min-light 8 --light-contrast 0.2 --max-lights 80
b forge 0.5 0.31 --no-water --min-light 10 --light-contrast 0.15 --max-lights 120
b grove 0.52 0.317 --water-band 0.8,1.0 --smooth 0.4 --min-light 8 --light-contrast 0.15 --max-lights 140
python3 tools/pixel_shrink.py
