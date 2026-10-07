#!/bin/zsh
# The bottom bar's icons reimagined directly as pixel art (Mathis, 2026-10-07). Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
ICON="A single game UI icon designed directly as pixel art, about 32x32 art pixels shown large and centred, in EXACTLY the pixel-art style of the attached images (same palette approach, crisp grid, no anti-aliasing, a dark outline, warm cozy fantasy light), readable at small size, on a perfectly flat pure magenta #FF00FF background, no text:"
REFS=(docs/design/p29/px-sanctuary.png docs/design/p29/px-spark.png)
gen $D/px-icon-world.png "$ICON a small folded treasure map of a fantasy world, a winding dotted path to a tiny red X and a little compass star." $REFS
gen $D/px-icon-satchel.png "$ICON an adventurer's leather satchel with a brass buckle and a tiny glowing light peeking from its flap." $REFS
gen $D/px-icon-book.png "$ICON a thick old storybook with a leather cover, a small glowing gem on the front and a red ribbon bookmark." $REFS
gen $D/px-icon-flame.png "$ICON the cute little fire spirit from the second image, head and body only, smiling, with a soft glow." $REFS
