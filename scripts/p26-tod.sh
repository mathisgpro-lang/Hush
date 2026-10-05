#!/bin/zsh
# Time-of-day references (corrections list #7): the Sanctuary at dawn, day, dusk and night. Re-run safe. In resume-codex.sh.
# In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; SPARK=docs/design/spark-v3/spark-a-teardrop.png; D=docs/design/p26
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in exactly the painterly luminous style of the first attached image (warm golden light, soft painted detail, cozy fantasy)"
PROP="Centered, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text, no letters."
# 4. Time of day (corrections list): the Sanctuary repainted at four hours, used as the colour-grading reference for every world.
PAINT=prototypes/p2-spikes/SpikeLab/Assets/world-paint.png
TOD="Repaint the attached island scene EXACTLY (same composition, every shape, building, tree and rock in the same place, same framing and size), changing ONLY the lighting and colours to"
gen $D/tod-dawn.png "$TOD early dawn: a soft pink-peach sky low on the horizon fading to cool lavender above, long gentle shadows, sea pale rose-blue, lanterns still faintly glowing, a light morning mist. Painterly, beautiful, calm." $PAINT
gen $D/tod-day.png "$TOD a clear bright midday: crisp warm sunlight, saturated but soft colours, blue sky with a few white clouds, sparkling turquoise sea, short shadows. Painterly, beautiful." $PAINT
gen $D/tod-dusk.png "$TOD golden-hour dusk: deep amber and coral sky with a violet top, warm orange rim light on every edge, long shadows, sea reflecting gold, the first lanterns and windows lit warm. Painterly, beautiful." $PAINT
gen $D/tod-night.png "$TOD a magical moonlit night: deep blue-teal sky full of soft stars, a gentle silver moonlight on the edges, the land still readable (never pitch black), every lantern, window and flame glowing warm orange with soft halos, a dark glassy sea with moon glints. Painterly, cozy, beautiful, Studio-Ghibli-like night." $PAINT
