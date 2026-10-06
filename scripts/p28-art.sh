#!/bin/zsh
# P2.8 art (Mathis 2026-10-06: the intro's first moments high-end; the Flame icon without a cage). Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; ICONREF=docs/design/iter2/icon-book.png; SPARK=docs/design/spark-v3/spark-a-teardrop.png; D=docs/design/p28
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in exactly the painterly luminous style of the first attached image (warm golden light, soft painted detail, cozy high-end fantasy game art)"
PROP="Centered, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text, no letters."
EGG="A magical ember egg for a high-end cozy fantasy game, $STYLE: a smooth egg of dark warm obsidian-gold stone with fine glowing golden rune veins, a soft molten-orange light glowing from inside,"
gen $D/egg-0.png "$EGG intact, calm, faint inner glow. Front view, the egg fills the frame vertically. $PROP" $ROOTF
gen $D/egg-1.png "$EGG EXACTLY the same egg as before (same shape, size, position) but brighter inside, with a few thin glowing cracks spreading from the top. $PROP" $ROOTF $D/egg-0.png
gen $D/egg-2.png "$EGG EXACTLY the same egg (same shape, size, position) blazing with light inside, many wide glowing cracks all over it, small flakes lifting off, about to burst. $PROP" $ROOTF $D/egg-0.png
gen $D/egg-shards.png "Eight separate broken shell shards of a dark obsidian-gold egg with glowing golden rune veins and molten-orange inner edges, scattered in a grid with space between them, $STYLE. $PROP" $ROOTF $D/egg-0.png
gen $D/embers-six.png "Six separate small glowing magical ember orbs in a single row with space between them, each a soft round flame-crystal with an inner light, $STYLE: rose pink (love), sky blue (curiosity), deep orange-red (strength), pale silver-lavender (calm), warm gold (craft), fresh green (wonder). $PROP" $ROOTF
gen $D/icon-flame-v2.png "A single game UI icon in exactly the same painted style, lighting, size and angle as the second attached image: the cute fire spirit from the third attached image, free and happy, floating above a small round ornate gold medallion base with a soft halo of light behind it, no cage, no frame around it. $PROP" $ROOTF $ICONREF $SPARK
gen $D/speech-frame.png "A wide empty speech scroll for a high-end fantasy game dialogue: soft warm parchment with gently curled ends and a thin gold-leaf border, a tiny flame ornament at the bottom center, perfectly empty, flat front view, $STYLE. $PROP" $ROOTF
gen $D/name-plaque.png "A wide empty ornate name plaque for a fantasy game: warm parchment inset in a carved dark-wood and gold frame, with a single faint ink line across the middle to write on and a small quill resting at the right end, flat front view, perfectly empty, $STYLE. $PROP" $ROOTF
gen $D/choice-card.png "A single empty tall-ish rounded game choice card made of warm parchment with a thin gold-leaf border and soft shadow inside the edge, perfectly empty, flat front view, $STYLE. $PROP" $ROOTF
