#!/bin/zsh
# P3.2 step 6, priority 1 (Mathis, 2026-10-14): the Flame as a painted character, as in his two reference sheets
# (docs/design/p32/ref-sheet-a.png, ref-sheet-b.png), "a mix between the two". Phase A: the six forms, each alone
# on flat magenta, ready to cut out. Re-run safe. Usage: p32-flame.sh [form ...]. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p32
REFS=(--image $D/ref-sheet-a.png --image $D/ref-sheet-b.png)
STYLE="Painted exactly in the style of the two attached reference sheets (soft cel-shaded anime / cartoon painting, warm golden-orange fire, soft volume and highlights, a glowing white-gold core in the chest, big warm brown eyes with highlights, rosy blush, a cute happy face), as a style halfway between the two sheets: the warmer, rounder, more contained flames of the first sheet with the livelier, more detailed flame hair of the second. The character ALONE, full body, centred, facing the viewer, feet at the bottom (it stands on the ground), filling about 80% of the image height, on a perfectly flat pure magenta #FF00FF background. NO stone circle, NO world, NO ground, NO text, NO label, NO glow or light spilling onto the background (crisp edges against the magenta: the game adds the light), portrait 3:4."
forms=(${@:-spark flame blaze kindled radiant beyond})
typeset -A DESC
DESC[spark]="The first form, 'Spark': a small round flame-drop spirit with a single swirl of flame on top, no arms or legs visible, floating just above the ground, exactly like the Spark in the top-left of the sheets."
DESC[flame]="The second form, 'Flame': a small standing fire child with stubby arms and feet and lively flame hair, exactly like 'Flame' in the sheets."
DESC[blaze]="The third form, 'Blaze': taller, arms open wide in a joyful pose, bigger roaring flame hair, exactly like 'Blaze' in the sheets."
DESC[kindled]="The fourth form, 'Kindled': slimmer and taller, graceful, long flowing flames trailing from its arms and sides, calm kind smile, exactly like 'Kindled' in the sheets."
DESC[radiant]="The fifth form, 'Radiant': majestic and luminous, golden-white core, long flowing flame robes, serene smile, exactly like 'Radiant' in the sheets."
DESC[beyond]="The final form, 'Beyond': celestial, flames shading from gold to soft violet and lavender at the tips, a few tiny sparkles, gentle wise smile, exactly like 'Beyond' in the sheets."
for f in $forms; do
  out=$D/flame-$f.png
  [[ -f $out ]] && { echo "exists: $out"; continue; }
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${REFS[@]}" -- "${DESC[$f]} $STYLE Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f $out ]] && echo "done: $out" || echo "MISSING: $out"
done
