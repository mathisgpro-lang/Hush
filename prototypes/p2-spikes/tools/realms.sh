#!/bin/zsh
# Rebuild every painted realm with its own settings (tools/build_realm.py). Run from prototypes/p2-spikes.
cd "$(dirname "$0")/.."
b() { [[ -f ../../docs/design/realms/$1.png ]] && python3 tools/build_realm.py "$@" 2>&1 | grep -v -i deprec | grep -v fromarray | tail -1 | sed "s/^/$1: /"; }
b stillwater 0.5 0.353 --water-band 0.36,0.58 --water-hue 0.6,0.15 --smooth 0.25 --min-light 12
b highlands 0.5 0.3 --min-light 10 --light-contrast 0.22 --max-lights 150
b library 0.5 0.34 --no-water --min-light 10 --light-contrast 0.18 --max-lights 220
b wilds 0.5 0.42 --water-band 0.4,1.0 --water-hue 0.8,0.13 --smooth 0.35 --min-light 8 --light-contrast 0.2 --max-lights 160
b forge 0.5 0.33 --no-water --min-light 10 --light-contrast 0.15 --max-lights 200
