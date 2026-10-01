#!/bin/zsh
# Design & Feel phase (decision 106): art cohesion test. The Flame and the Sanctuary generated TOGETHER in one image,
# in four directions, so Mathis can pick the one where they're one artwork. Re-run safe. Registered in resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
D=docs/design/cohesion; mkdir -p $D
SANC=docs/design/world/sanctuary-stone-age.png; HERO=docs/design/character/flame-hero.png
gen() {
  [[ -f "$1" ]] && { echo "exists: $1"; return; }
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" --image "$SANC" --image "$HERO" -- "$2 Save it as $1 using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$1" ]] && echo "done: $1" || echo "MISSING: $1"
}
BASE="Portrait 9:19.5 key frame of a mobile game home screen. The place: the ancient stone Sanctuary on cliffs above a calm sea at golden dusk, from the first attached painting (same place, composition and colors), seen from slightly above. At the center, a small cute fire spirit character (the second attached image: round fluffy fire body, flame hair, big glossy brown eyes, blush, glowing chest core) sits on the glowing stone circle, about one fifth of the screen tall, lit by the same warm sunset light as the world, casting warm firelight on the stones around it, with a soft reflection. The character and the world must look like ONE artwork made by one artist: same rendering, same light, same atmosphere. No text, no UI."
gen $D/B-painterly.png "$BASE Direction: render the character in exactly the same rich painterly illustration style as the world, with the same brushwork, soft edges and palette, as if the painter painted it into the scene."
gen $D/D-luminous.png "$BASE Direction: keep the world exactly as painted and make the character a luminous spirit of living fire painted with light: semi-translucent glowing flames, soft painterly glow, no hard outlines, so it feels like light living inside the painting, still cute with big eyes."
gen $D/C-anime.png "$BASE Direction: render both the world and the character like a hand-painted classic Japanese animated film: lush painted background, a simpler cel-shaded character with clean shapes, warm nostalgic light."
gen $D/A-diorama.png "$BASE Direction: render both the world and the character as a soft stylized 3D animated-film diorama: rounded shapes, soft materials, simplified details, like a premium 3D animated movie."
gen $D/E-luminous-3d.png "$BASE Direction: an immersive real-time 3D game world like a luminous adventure game: simple, elegant stylized 3D shapes with soft gradients instead of painted detail, deep atmospheric haze and fog layers that give huge depth, volumetric clouds, god rays and bloom from the low sun, glowing particles in the air, the tiny character small against a vast, awe-inspiring landscape. The character is a soft 3D fire spirit lit by and lighting the scene."
