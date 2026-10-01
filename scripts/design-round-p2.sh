#!/bin/zsh
# P2 design round (p2-phase-plan.md §B.5). Codex, AI-only (decision 87), style anchors as references (decision 95).
# One short prompt per image, stdin closed, re-run safe (finished images are skipped). Registered in scripts/resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
D=docs/design
HERO=$D/character/flame-hero.png; EVO=$D/character/flame-evolution.png; EXPR=$D/character/flame-expressions.png
GROVE=$D/world/grove-scene.png; MAP=$D/world/world-map.png
gen() { # $1 output, $2 prompt, $3.. reference images
  local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"
  local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"
}
SAME="Keep the exact same character identity as the attached images: same face, glossy brown eyes, blush, plush fluffy fire body, swirling golden chest core. It is a little fire person, no animal features."

gen $D/character/stage-spark.png "Full-body character design of the SPARK stage: a tiny round baby ember, no arms yet (little nubs), 3 small flame tips, enormous eyes, wobbly and curious. $SAME Dark warm background, no text." $EVO $HERO
gen $D/character/stage-flame.png "Full-body character design of the FLAME stage: the attached hero as is, 4 flame tips, real stubby arms and legs, playful and brave. $SAME Dark warm background, no text." $HERO $EVO
gen $D/character/stage-blaze.png "Full-body character design of the BLAZE stage: taller, confident posture, 5 flame tips, brighter core, the first soft glowing pattern markings on the arms and chest. It must read as deeper and more complex, not just bigger. $SAME Dark warm background, no text." $EVO $HERO
gen $D/character/stage-kindled.png "Full-body character design of the KINDLED stage: a radiant, wise, calm form with complete golden markings, a gentle flame crown, a unique silhouette, still cute and warm. Deeper and more complex, not just bigger. $SAME Dark warm background, no text." $EVO $HERO
gen $D/character/stage-beyond-silhouette.png "A mysterious glowing silhouette of the final BEYOND stage of the attached character, mostly hidden in brilliant light, only its shape hinted, majestic and serene. Dark background, no text." $EVO
gen $D/character/turnaround-flame.png "Character turnaround sheet of the attached character at its FLAME stage: front, three-quarter, side and back views, same scale, neutral pose, evenly lit, for 3D modeling. $SAME Plain dark background, no text." $HERO $EVO
gen $D/character/face-sheet.png "Face expression sheet for a texture atlas: 12 eye-and-mouth states of the attached character in a clean 4x3 grid (neutral, blink, happy, big joy open mouth, surprised, curious, determined, sleepy, eyes closed peaceful, giggle, proud, talking). Only the face area of each, same framing, flat warm background, no text." $EXPR $HERO
gen $D/character/pillar-markings.png "Six variants of the attached character at its BLAZE stage in a 3x2 grid, each with different soft glowing markings: ember-orange muscle-like streaks, fine blue script-like patterns, a rose-gold heart-shaped core glow, a silver-white halo crown, bronze geometric patterns, green-gold leaf-like flame tips. $SAME Dark background, no text." $EVO $HERO
gen $D/cast/lamplighter.png "Character design of THE LAMPLIGHTER: an ancient, small, hooded flame spirit with a very dim, gentle light, carrying an old lantern staff, wry and kind, same stylized 3D family and materials as the attached character. Dark warm background, no text." $HERO $GROVE
gen $D/cast/nim-and-ro.png "Character design of NIM and RO: twin tiny lantern-fireflies with glowing lantern bodies and expressive faces, chatty and affectionate, same stylized 3D family as the attached character, in the attached forest at dusk. No text." $HERO $GROVE
gen $D/cast/orrin.png "Character design of ORRIN: a soot-black salamander blacksmith with small round spectacles and a leather apron, gruff but kind, glowing ember spots on his skin, same stylized 3D family as the attached character. Warm forge light, no text." $HERO
gen $D/world/sanctuary-stone-age.png "Portrait 9:19.5 scene of THE SANCTUARY in the same rich painterly luminous style as the attached images: ancient soft-edged stone ruins on an island in a calm sea at dusk, waterfalls, moss, and at the center a round stone hearth with an empty warm glowing spot where a small character will stand. No characters, no text." $GROVE $MAP
gen $D/world/sanctuary-hushed.png "The same Sanctuary scene as the attached image but HUSHED: desaturated blue-grey, soft mist covering it, waterfalls still, lights out. Nothing destroyed, only asleep and grey. Same composition, no text." $D/world/sanctuary-stone-age.png
gen $D/world/grove-hushed.png "The same forest scene as the attached image but HUSHED: desaturated blue-grey, soft mist, all lanterns unlit, no fireflies, water still. Nothing destroyed, only asleep and grey. Same composition, no text." $GROVE
gen $D/ui/emberspeak-glyphs.png "A sheet of 24 original decorative glyphs for an invented ember script called Emberspeak, drawn as glowing warm ember strokes, soft and rounded, arranged in a 6x4 grid on a dark background. Not any real alphabet, no Latin letters." $HERO
gen $D/ui/first-words-frame.png "Portrait 9:19.5 mobile game storyboard frame: the tiny attached baby flame character (Spark stage) in the attached sanctuary at dawn, looking up at the viewer, with a soft glowing dark text plate below it showing glowing ember glyphs half-melting into the English words 'I'm your Flame.' Elegant, warm, minimal UI." $D/character/stage-spark.png $D/world/sanctuary-stone-age.png
gen $D/ui/kit-calls-plates.png "Portrait 9:19.5 mobile game UI mockup over the attached sanctuary scene: three small glowing scroll-like task tags floating near the hearth, color-coded (moss green, ember orange, silver), a dark warm translucent plate with a thin colored edge, round soft buttons, a small home ember icon, elegant serif headings. Readable, minimal." $D/world/sanctuary-stone-age.png
