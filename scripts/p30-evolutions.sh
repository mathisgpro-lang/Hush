#!/bin/zsh
# The Flame's evolutions in pixel art (decision 152): Spark (have) → Flame (have) → Blaze → Kindled → Radiant → Beyond.
# Each is drawn from the stage before it, in the pixel Spark's exact style. Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29; A=prototypes/p2-spikes/SpikeLab/Assets
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in EXACTLY the pixel-art style of the attached pixel images (same pixel size relative to the body, crisp grid, no anti-aliasing, the same warm palette approach, dark outline, the same cute face with big eyes and blush), a game sprite shown large and centred, on a perfectly flat pure magenta #FF00FF background, no text"
gen $D/px-stage-blaze.png "The third evolution of this fire spirit: older and stronger than the second attached image, a bigger roaring body of flame with swirling flame 'hair', small flame arms, a confident happy face, $STYLE." $A/stage-blaze.png $D/px-stage-flame.png $D/px-spark.png
gen $D/px-stage-kindled.png "The fourth evolution of this fire spirit: wiser and taller than the second attached image, a calm noble flame being with a small crown of golden embers and a warm glowing heart in its chest, kind eyes, $STYLE." $A/stage-kindled.png $D/px-stage-blaze.png $D/px-spark.png
gen $D/px-stage-radiant.png "The fifth evolution of the fire spirit in the attached images: radiant and majestic, its flame now golden-white at the core with soft rays of light around it, small floating ember orbs circling it, a serene joyful face, $STYLE." $D/px-stage-kindled.png $D/px-spark.png
gen $D/px-stage-beyond.png "The final, legendary evolution of the fire spirit in the attached images: a luminous celestial flame being, flames shading from gold to soft violet and starlight at the tips, a halo of tiny stars, wise gentle eyes, the most beautiful form, $STYLE." $A/stage-beyond.png $D/px-stage-radiant.png $D/px-spark.png
