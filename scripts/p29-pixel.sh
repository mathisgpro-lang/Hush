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
