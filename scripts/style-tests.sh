#!/bin/zsh
# Codex art queue (decisions 79-82: cartoon/anime universe). One short prompt per image, stdin closed.
# Re-run safely: finished images are skipped. Registered in scripts/resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
CARTOON=docs/design/style-tests/B-cartoon-sanctuary.png
gen() { # $1 output, $2 prompt, $3 optional reference image
  [[ -f "$1" ]] && { echo "exists: $1"; return; }
  mkdir -p "$(dirname "$1")"
  if [[ -n "$3" ]]; then
    "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image "$3" -- "$2 Save it as $1 using your image generation tool." < /dev/null > /dev/null 2>&1
  else
    "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "$2 Save it as $1 using your image generation tool." < /dev/null > /dev/null 2>&1
  fi
  [[ -f "$1" ]] && echo "done: $1" || echo "MISSING: $1"
}

# U2: the character bible (an ORIGINAL design, inspired by traits Mathis shared: plush fluffy fire body, flame hair,
# big glossy eyes with highlights, soft brows, blush, small smile, stubby limbs, warm glowing core, floating embers).
gen docs/design/character/flame-hero.png "Design an ORIGINAL cute cartoon flame spirit character, stylized 3D look (soft volume and lighting, like a high-quality animated film), full body, front view: a round plush body made of soft fluffy fire, flame hair rising from its head with the tallest tongue in the center, big glossy brown eyes with bright highlights, soft eyebrows, rosy blush, small warm smile, short stubby arms and legs, a glowing golden core in its chest, a few embers floating around. Simple dark warm background. No text."
gen docs/design/character/flame-expressions.png "Create an expression sheet of ONE original cute cartoon flame spirit (round plush fluffy fire body, flame hair, big glossy eyes, blush, stubby limbs, stylized 3D look) in 6 poses in a grid: calm, happy, cheering with arms up, surprised, sleepy small ember with closed eyes, proud and blazing. Same character in every pose, dark warm background, no text."
gen docs/design/character/flame-evolution.png "Using the attached character as the exact base design, show it in 5 evolution stages left to right: a tiny round baby ember with no arms, the attached character as is, a taller confident blaze with 5 flame tips and soft glowing patterns, a radiant kindled form with golden markings, and a majestic luminous final form. Keep the SAME face, eyes, plush fluffy fire body and glowing chest core in every stage. It stays a little fire person: NO animal features, no ears, no tail, no fox or cat. Dark background, no text." docs/design/character/flame-hero.png

# U3/U4: the cartoon world
gen docs/design/world/sanctuary-empty.png "Recreate the attached cartoon scene exactly (same composition, style, palette, portrait 9:19.5) but REMOVE the glowing vessel on the pedestal in the lower middle: leave the steps and pedestal EMPTY with a faint warm glow, so a character can stand there. No text, no UI." "$CARTOON"
gen docs/design/world/world-map.png "Create an illustrated cartoon fantasy WORLD MAP for a mobile game, portrait 9:19.5, warm magical dusk colors, soft stylized painterly look: at the bottom an ancient sanctuary of ruins and water; paths leading up to a lantern-lit forest grove on the left, a mirror-like lake on the right, a floating library of books above the forest, a road climbing into hills above the lake, a glowing forge inside a mountain at the top center, wide wild lands and a mysterious misty veil at the very top. No text, no labels."
gen docs/design/world/grove-scene.png "Create a cartoon fantasy scene, portrait 9:19.5, soft stylized painterly look: the Whispering Grove, a magical forest at dusk where hundreds of small warm lanterns hang in giant old trees, a mossy clearing in the center with a stone circle where travellers gather, fireflies, gentle mist. No characters, no text."
