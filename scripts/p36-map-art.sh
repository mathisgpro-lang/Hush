#!/bin/zsh
# P3.6 step 4a (decision 189; Mathis approved the sketches 2026-10-22: "yes I like it… go ahead and build it on the game
# itself now"). Codex paints the map's pieces after its approved sketches, each alone on flat magenta; they are keyed
# into the app's assets at the game's saturation (decision 187: 82%). Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p36; ART=$D/art
ASSETS=prototypes/p2-spikes/SpikeLab/Assets; mkdir -p $ART
REFS=(--image $D/map-islands-start.png --image $D/map-islands-midway.png)
STYLE="Painted EXACTLY in the style of the two attached approved sketches of our game's world map (painterly cel-shaded fantasy, warm light, soft volume, crisp clean silhouette). ONE object ALONE, centred, filling about 85% of a square 1024x1024 image, seen from the same slightly-above three-quarter angle as the sketches, on a perfectly flat pure magenta #FF00FF background. NO text, NO number, NO nameplate, NO stepping stones, NO other island, NO sky, NO clouds behind it, NO glow or light spilling onto the background (crisp edges against the magenta: the game adds the light)."
typeset -A DESC
DESC[sanctuary]="The SANCTUARY floating island from the sketches: a round stone circle with a small glowing fountain in its centre, broken ruined arches and pillars, wisteria and flowers, little candles, waterfalls pouring off its edges, rock and roots hanging below."
DESC[grove]="The WHISPERING GROVE floating island from the sketches: a giant old tree with an autumn canopy full of warm glowing lanterns, a little path and steps at its foot, a waterfall off one edge, rock and roots hanging below."
DESC[stillwater]="The STILLWATER floating island from the sketches: a calm turquoise lake with reeds and willows, a small domed white pavilion with columns at the back, lanterns, waterfalls off its edges, rock and roots hanging below."
DESC[highlands]="The ASCENT HIGHLANDS floating island from the sketches: green hills and a small rocky peak, a windmill with orange pennants, a stone bridge and steps, pine trees, waterfalls off its edges, rock and roots hanging below."
DESC[library]="The LIBRARY OF EMBERS floating island from the sketches: a domed library with tall arched golden windows and purple banners, a few open books floating around it, little trees, rock and roots hanging below."
DESC[wilds]="The WILDS floating island from the sketches: a lush jungle with palm trees and big leaves around overgrown stone ruins, vines hanging off its edges, a waterfall, rock and roots hanging below."
DESC[forge]="The FORGE MOUNTAIN floating island from the sketches: a small volcano with a glowing crater and a thin trail of smoke, a dark stone forge building with a glowing doorway, embers, dark volcanic rock hanging below."
DESC[veil]="The VEIL: a mysterious floating island almost entirely hidden in pale silver-violet mist, only the faint silhouette of tall shapes and a soft cold glow showing through; rock hanging below. It must feel unknown and sealed."
DESC[stone]="ONE small floating stepping-stone tile from the sketches' level paths: a chunky square-ish block of warm sandy stone with a slightly worn top, seen from the same angle, its top face flat and empty (the game draws the level medallion on it), a few tiny crumbs of rock hanging below. Fill about 60% of the image."
DESC[islet]="ONE small distant floating rock islet from the sketches' background: a little chunk of rock with a tuft of grass or a single tree, cool blue-grey from distance, hanging roots. Fill about 60% of the image."
DESC[cloud]="ONE soft drifting cloud bank from the sketches: wispy, layered, pale lavender and soft pink-cream, gently lit from below by warm light, wider than tall (fill about 90% of the width, 40% of the height)."
if (( $# )); then pieces=($@); else pieces=(sanctuary grove stillwater highlands library wilds forge veil stone islet cloud); fi
paint() {   # $1 = piece
  local raw=$ART/$1-raw.png
  [[ -f $raw ]] || "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${REFS[@]}" -- "${DESC[$1]} $STYLE Save it as $raw using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f $raw ]] || { echo "MISSING: $raw"; return; }
  local name=island-$1; [[ $1 == stone ]] && name=map-stone; [[ $1 == islet ]] && name=map-islet; [[ $1 == cloud ]] && name=map-cloud
  python3 prototypes/p2-spikes/tools/magenta_key.py $raw $ART/$name-keyed.png > /dev/null 2>&1 && \
  python3 -c "
from PIL import Image, ImageEnhance
im=Image.open('$ART/$name-keyed.png').convert('RGBA'); a=im.split()[3]
rgb=ImageEnhance.Color(im.convert('RGB')).enhance(0.82)   # the game's saturation (decision 187)
out=rgb.convert('RGBA'); out.putalpha(a)
out.thumbnail((900,900)); out.save('$ASSETS/$name.png')" && echo "done: $ASSETS/$name.png"
}
i=0
for p in $pieces; do
  paint $p &
  (( ++i % 4 == 0 )) && wait
done
wait
