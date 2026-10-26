#!/bin/zsh
# P3.3 step 4 (decision 183): the two small painted icons of the daily screen, in the style of Codex's approved sketch
# (docs/design/p33/daily-morning.png): the lit-day flame of the week row and the streak shield. Each alone on flat
# magenta, then keyed into the app's assets. Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p33
ASSETS=prototypes/p2-spikes/SpikeLab/Assets
STYLE="Painted in exactly the style of the attached sketch (warm cel-shaded game painting, golden-orange fire, soft volume, a bright warm core, crisp clean silhouette). ONE small game icon ALONE, centred, filling about 80% of a square image, on a perfectly flat pure magenta #FF00FF background. NO text, NO circle or frame behind it, NO glow or light spilling onto the background (crisp edges against the magenta: the game adds the light). It must read clearly at 28 points on a phone."
typeset -A DESC
DESC[dayflame]="The lit-day flame used in the week row of the sketch: a small round-bottomed flame with two or three lively tongues, orange outside, yellow then near-white at its core, slightly cute and soft. Save it as $D/icon-dayflame-raw.png."
DESC[shield]="The streak shield shown next to DAY STREAK in the sketch: a small heater shield with a polished gold rim and a warm glowing orange-amber ember inside, a tiny highlight on the rim. Save it as $D/icon-shield-raw.png."
typeset -A OUT; OUT[dayflame]=day-flame.png; OUT[shield]=streak-shield.png
if (( $# )); then icons=($@); else icons=(dayflame shield); fi
for i in $icons; do
  raw=$D/icon-$i-raw.png
  [[ -f $raw ]] || "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/daily-morning.png -- "${DESC[$i]} $STYLE Use your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  if [[ -f $raw ]]; then
    python3 prototypes/p2-spikes/tools/magenta_key.py $raw $ASSETS/${OUT[$i]} && sips -Z 160 $ASSETS/${OUT[$i]} > /dev/null && echo "done: $ASSETS/${OUT[$i]}"
  else echo "MISSING: $raw"; fi
done
