#!/bin/zsh
# Pixel-art references (Mathis, 2026-10-07: "pixelize the whole game"). Native pixel art, to compare with the live
# pixel filter. Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
PX="as genuine high-quality pixel art (like Eastward, Sea of Stars, Stardew Valley at its best): a crisp pixel grid with no blur, no anti-aliasing, no gradients, a limited harmonious warm palette of about 32 colours, clean readable shapes and dark outlines where useful, cozy and alive"
gen $D/px-sanctuary.png "Redraw the attached island sanctuary scene (same composition: the stone circle in the centre, ruined arches, waterfalls, the sea, the sunset sky) $PX. Portrait phone format." prototypes/p2-spikes/SpikeLab/Assets/world-paint.png
gen $D/px-spark.png "Redraw the attached cute fire spirit character $PX, as a small game sprite about 48 pixels tall shown large and centred, on a perfectly flat pure magenta #FF00FF background." docs/design/spark-v3/spark-a-teardrop.png
gen $D/px-library.png "Redraw the attached magical floating library scene (same composition) $PX. Portrait phone format." prototypes/p2-spikes/tools/originals/library-world-paint.png
# The whole game in pixel art (decision 149): every realm, the map, the Spark's frames, the props.
REF=docs/design/p29/px-sanctuary.png
STYLE2="in EXACTLY the same pixel-art style as the second attached image (same pixel size, palette approach, outlines, light): $PX"
for r in grove stillwater highlands library wilds forge; do
  gen $D/px-$r.png "Redraw the first attached scene (same composition and places) $STYLE2. Portrait phone format." ../../docs/design/realms/$r.png $REF
done
gen $D/px-map.png "Redraw the first attached fantasy world map (same composition: every realm in the same place, the winding road, the sea of clouds, the floating library) $STYLE2. Tall portrait format." prototypes/p2-spikes/SpikeLab/Assets/world-map.png $REF
SPK=docs/design/p29/px-spark.png
gen $D/px-spark-blink.png "Redraw the attached pixel-art fire spirit EXACTLY (same pixels, size, position, colours, magenta background) but with its eyes closed in a gentle blink (two small curved lines). No other change." $SPK
gen $D/px-spark-happy.png "Redraw the attached pixel-art fire spirit EXACTLY (same pixels, size, position, colours, magenta background) but very happy: eyes closed in happy upside-down arcs (^ ^) and a bigger open smile. No other change." $SPK
gen $D/px-props.png "Four small pixel-art game objects in a row with space between them $STYLE2: a glowing lantern, a rolled scroll with a red ribbon, a glowing crystal, a golden flower bud. On a perfectly flat pure magenta #FF00FF background." $REF $REF
