#!/bin/zsh
# The first Flame as a pure spirit (Mathis, 2026-10-02): the current character (arms, legs, plush body) reads as a
# later stage. Concepts for the Spark: same face shape, same cuteness and colors, but only a small spirit of fire.
# Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
REF=prototypes/p2-spikes/SpikeLab/Assets/d-keyed.png; ROOTF=docs/design/cohesion/D-luminous.png; D=docs/design/spark-v3
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
BASE="The first attached image is our fire character as it is today; the second is the world it lives in (the style root). Design its FIRST, youngest stage, the Spark: a pure little SPIRIT of fire. Keep EXACTLY the same face (the same big glossy amber eyes with their highlights, the same small smile, the same rosy cheeks, the same face shape and proportions) and the same warm golden-orange colors and soft luminous painterly style. But it is NOT a developed creature: NO arms, NO legs, NO hands, NO feet, no plush body. Just a soft floating wisp of living flame around that face, smaller and simpler, like a newborn flame spirit. Centered, full figure, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text."
gen $D/spark-a-teardrop.png "$BASE Shape: a soft teardrop flame, the face in the round lower part, one gentle flame tip curling at the top." $REF $ROOTF
gen $D/spark-b-wisp.png "$BASE Shape: a floating wisp whose bottom tapers into a little trailing flick of fire (like a tiny ghost of flame), two small flame tips on top." $REF $ROOTF
gen $D/spark-c-ember.png "$BASE Shape: a round glowing ember ball with the face, soft flickering flames rising from its top like a small crown, a few floating sparks around it." $REF $ROOTF
gen $D/spark-d-candle.png "$BASE Shape: like a candle flame come alive: a tall soft flame with the face near its base, a glowing white-gold core inside, the tip swaying." $REF $ROOTF
# The whole growth line, so the intro can preview it (the Spark → the current character → later stages).
gen $D/evolution-line.png "One horizontal lineup of the SAME fire character growing through five stages, left to right, all with exactly the same face as in the first attached image (same eyes, smile, cheeks), same palette and luminous painterly style: 1 the Spark: a tiny floating spirit of flame with only the face, no limbs; 2 the Flame: the character exactly as in the first attached image (small plush body with little arms and legs); 3 the Blaze: taller, more confident, a bigger crest of flame, a glowing chest core; 4 the Kindled: graceful and radiant, flowing flame like a mantle, small floating embers orbiting; 5 Beyond: a luminous silhouette of light, mysterious, only its eyes visible. Same scale progression from small to tall, on a perfectly flat pure magenta #FF00FF background, no text, no labels." $REF $ROOTF
