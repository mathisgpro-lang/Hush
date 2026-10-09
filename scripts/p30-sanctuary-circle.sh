#!/bin/zsh
# The pixel Sanctuary with a bigger stone circle, like the other worlds (decision 156). Re-run safe.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"; D=docs/design/p29
out=$D/px-sanctuary-v2.png
[[ -f $out ]] && { echo "exists: $out"; exit 0; }
"$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image $D/px-sanctuary.png --image $D/px-wilds.png -- "Redraw the first attached pixel-art sanctuary scene in EXACTLY the same pixel-art style, palette, light and elements (the ruined arches, braziers, waterfalls, wisteria, the sea and the sunset), in a tall portrait format (about 9:20), but seen from closer so that the round stone rune circle is much larger: it should span about 60% of the image width, like the stone circle in the second attached image, and its centre should sit at about 42% of the image height from the BOTTOM, horizontally centred. Keep the circle round, empty, clearly visible and glowing softly. Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
[[ -f $out ]] && echo "done: $out" || echo "MISSING: $out"
