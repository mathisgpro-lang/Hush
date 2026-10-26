#!/bin/zsh
# P3.4 (Mathis, 2026-10-22: "lets now create the logo of the app, and then install it so I can see it on my phone").
# Codex paints four app-icon options in the game's own style; Claude installs the chosen one (Mathis picks; the default
# is option A). Re-run safe. Usage: p34-app-icon.sh [a b c d]. In resume-codex.sh. Runs the options in parallel.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p34; mkdir -p $D
A=prototypes/p2-spikes/SpikeLab/Assets
REFS=(--image $A/depth-spark-keyed.png --image $A/depth-blaze-keyed.png --image docs/design/flame-depth/sanctuary-screen-v1.png --image docs/design/p33/daily-morning.png)
BASE="Design the iPhone APP ICON of a cozy self-growth game whose hero is a small living flame character (the attached Spark, first image; an older form, Blaze, second image) in a warm painted fantasy world (third image) with a warm gold-on-dark interface (fourth image). Match their painting style exactly: soft cel-shaded anime / cartoon painting, warm golden-orange fire with a glowing white-gold core, big warm brown eyes with highlights, rosy blush, a happy friendly face. RULES FOR AN APP ICON: a perfectly square 1024x1024 image, full bleed, NO rounded corners (iOS rounds them), NO text or letters, NO transparency, NO border or frame, NO tiny details: it must read instantly at 60 pixels on a phone home screen next to other apps; one clear subject, big, centred, with the important part inside the central 80% (the corners get cut); strong silhouette and contrast; warm, inviting, premium, and different from every other app."
typeset -A DESC
DESC[a]="OPTION A, the face: the Spark's face and flame crown filling most of the icon, big friendly eyes looking at you, a warm smile, its fire curling up and slightly beyond the top, on a deep warm dusk background (dark plum to ember-orange glow behind it). The most character-forward option, like a beloved mascot. Save it as $D/icon-a.png."
DESC[b]="OPTION B, the little scene: the whole Spark, small but clear, glowing on a round stone circle with faint golden runes, seen from slightly above, at dusk with a soft sky; its light is the brightest thing in the icon. A tiny world in a square. Save it as $D/icon-b.png."
DESC[c]="OPTION C, the emblem: a bold, simple, rounded flame shape in rich gold-to-orange with two big friendly eyes and nothing else, like a polished game emblem, centred on a deep warm dark background with a soft circular glow. The most minimal and logo-like option, still clearly the same character. Save it as $D/icon-c.png."
DESC[d]="OPTION D, the ember in the night: the Spark, joyful and glowing, rising from a cupped pair of glowing golden embers or a small lantern of light, against a deep night-blue to warm-amber gradient with a few floating sparks; strong warm-cold contrast so it pops on any wallpaper. Save it as $D/icon-d.png."
if (( $# )); then opts=($@); else opts=(a b c d); fi
for o in $opts; do
  out=$D/icon-$o.png
  [[ -f $out ]] && { echo "exists: $out"; continue; }
  ( "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${REFS[@]}" -- "$BASE
${DESC[$o]} Use your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
    [[ -f $out ]] && echo "done: $out" || echo "MISSING: $out" ) &
done
wait
