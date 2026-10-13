#!/bin/zsh
# Every world painted taller (Mathis, 2026-10-13: the dark band under the raised world "doesn't feel right"): the same
# scene, unchanged on top, continued downward so it reaches the bottom of the screen behind the quests. Re-run safe.
# Usage: p31-extend.sh [world ...]   (default: all seven)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
worlds=(${@:-sanctuary grove stillwater highlands forge library wilds})
for r in $worlds; do
  out=$D/px-$r-tall.png
  [[ -f $out ]] && { echo "exists: $out"; continue; }
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/px-$r.png -- "Extend the attached pixel-art scene DOWNWARD. Keep the whole attached image exactly as it is (same framing, same pixel-art style, palette, light and every detail) as the top part, and add about 35% more height BELOW it, so the final image is taller (about 9:27 portrait). In the new lower part, continue the scene naturally from its bottom edge: more of the same ground, stone steps or path leading toward the viewer, grass, flowers, rocks, water or roots, whatever this place already has, in the same perspective. No new characters, no text, no frame, no black or empty areas, nothing dark at the bottom edge. Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f $out ]] && echo "done: $out" || echo "MISSING: $out"
done
