#!/bin/zsh
# P3.4, round 2 (Mathis, 2026-10-22, pointing at option C: "I like something of this sort a lot, but with another
# background"). Codex keeps option C's flame emblem exactly and repaints only the background, four ways. Re-run safe.
# Usage: p34-app-icon-c2.sh [navy dusk teal sunrise]. In resume-codex.sh. Runs in parallel.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p34
BASE="The attached image is an iPhone app icon: a rounded golden flame character with two big friendly eyes on a near-black background. Mathis loves the flame and wants ANOTHER BACKGROUND. Recreate this icon with the flame EXACTLY the same (same shape, size, position, eyes, colours, soft glow, same painting style; do not redesign it, do not add a mouth, arms or any detail), and change ONLY the background as described below. Keep it a perfectly square 1024x1024 image, full bleed, NO rounded corners (iOS rounds them), NO text, NO border, NO transparency. The flame must keep strong contrast and read instantly at 60 pixels on a phone home screen; a soft halo of the flame's own warm light may glow into the new background around it."
typeset -A DESC
DESC[navy]="BACKGROUND: a deep night blue, from rich navy at the edges to a slightly lighter indigo-blue behind the flame, smooth and clean, maybe two or three tiny faint warm sparks drifting near the flame; a cool background that makes the warm flame pop. Save it as $D/icon-c-navy.png."
DESC[dusk]="BACKGROUND: the game's dusk sky as a smooth gradient, deep plum-violet at the top melting into warm rose and ember-orange at the bottom, soft and painterly, no scenery; warm and magical. Save it as $D/icon-c-dusk.png."
DESC[teal]="BACKGROUND: a deep teal-emerald, from dark green-teal at the edges to a softer jade glow behind the flame, smooth and clean; the complementary colour to the orange flame, calm and distinctive. Save it as $D/icon-c-teal.png."
DESC[sunrise]="BACKGROUND: a soft bright sunrise, light sky blue at the top melting into pale peach-gold at the bottom, airy and luminous; give the flame a slightly deeper orange rim if needed so it still stands out on the light background. Save it as $D/icon-c-sunrise.png."
if (( $# )); then opts=($@); else opts=(navy dusk teal sunrise); fi
for o in $opts; do
  out=$D/icon-c-$o.png
  [[ -f $out ]] && { echo "exists: $out"; continue; }
  ( "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/icon-c.png -- "$BASE
${DESC[$o]} Use your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
    [[ -f $out ]] && echo "done: $out" || echo "MISSING: $out" ) &
done
wait
