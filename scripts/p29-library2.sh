#!/bin/zsh
# The pixel Library reframed: its stone circle higher, so the Spark sits above the quest panel. Re-run safe.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
out=$D/px-library-v2.png
[[ -f $out ]] && { echo "exists: $out"; exit 0; }
"$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/px-library.png -- "Redraw the attached pixel-art library scene in EXACTLY the same pixel-art style, palette, light and details, in a tall portrait format (about 9:20), framed so that the round stone floor circle sits at about 38% of the image height from the BOTTOM (show more polished floor and a few steps below it), with the floating books, the sunset and the towers above as now. Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
[[ -f $out ]] && echo "done: $out" || echo "MISSING: $out"
