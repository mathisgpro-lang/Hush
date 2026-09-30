#!/bin/zsh
# Style tests for decision 75: same scene in pixel art vs stylized cartoon, plus the future personified Flame.
# One short prompt per image (the reliable way), stdin closed.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
REF=docs/design/sanctuary/stone-era-bright-empty.png
gen() { # $1 output, $2 prompt, $3 "ref" to attach the Sanctuary reference image
  [[ -f "$1" ]] && { echo "exists: $1"; return; }
  if [[ "$3" == "ref" ]]; then
    "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image "$REF" -- "$2 Save it as $1 using your image generation tool." < /dev/null > /dev/null 2>&1
  else
    "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "$2 Save it as $1 using your image generation tool." < /dev/null > /dev/null 2>&1
  fi
  [[ -f "$1" ]] && echo "done: $1" || echo "MISSING: $1"
}
gen docs/design/style-tests/A-pixel-sanctuary.png "Reimagine the attached scene as beautiful detailed PIXEL ART (like Alto's Odyssey meets Stardew Valley / Eastward, crisp pixels, limited warm palette, 2D): ancient sandstone ruins with arches, waterfalls, green life, water, a warm dusk sky. In the center on the stone pedestal, a small living flame inside a pointed diamond-shaped carved stone vessel. Portrait phone screen 9:19.5, no text, no UI."
gen docs/design/style-tests/B-cartoon-sanctuary.png "Reimagine the attached scene as a STYLIZED ILLUSTRATED CARTOON (soft clean shapes, gentle gradients, like Monument Valley, Alba or a Studio Ghibli background, NOT photorealistic): ancient sandstone ruins with arches, waterfalls, green life, water, a warm dusk sky. In the center on the stone pedestal, a small living flame inside a pointed diamond-shaped carved stone vessel. Portrait phone screen 9:19.5, no text, no UI." ref
gen docs/design/style-tests/C-pixel-flame-character.png "Create a PIXEL ART character sheet of a cute, wise living flame spirit with two expressive eyes and a small mouth (a companion, like Calcifer from Howl's Moving Castle but original), shown in 4 small poses: calm, joyful, sleepy ember (low energy), and blazing proud. Warm fire colors, crisp pixels, dark background. No text."
gen docs/design/style-tests/D-cartoon-flame-character.png "Create a STYLIZED CARTOON character sheet of a cute, wise living flame spirit with two expressive eyes and a small mouth (a companion, like Calcifer from Howl's Moving Castle but original), shown in 4 poses: calm, joyful, sleepy ember (low energy), and blazing proud. Soft clean shapes, warm fire colors, dark background, NOT photorealistic. No text."
