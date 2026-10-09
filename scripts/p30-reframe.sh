#!/bin/zsh
# Every realm reframed so the Flame's circle sits near the middle of the screen, above the quest panel (Mathis,
# 2026-10-09). Same scene, same pixel art, a little wider, the circle at ~42% from the bottom. Re-run safe.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
for r in grove stillwater highlands forge; do
  out=$D/px-$r-v2.png
  [[ -f $out ]] && { echo "exists: $out"; continue; }
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/px-$r.png -- "Redraw the attached pixel-art scene in EXACTLY the same pixel-art style, palette, light and details, in the same tall portrait format (about 9:20), but framed slightly wider and lower so that the round stone circle on the ground sits at about 42% of the image height from the BOTTOM (continue the ground, path, steps, flowers or water naturally below it). Keep the circle round, empty and clearly visible, and keep the scenery above it as now. Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f $out ]] && echo "done: $out" || echo "MISSING: $out"
done
