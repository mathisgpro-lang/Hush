#!/bin/zsh
# P2.6 step-up art (decision 135): the painted UI kit, the Keepers, the Spark's animation parts. Re-run safe.
# In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; SPARK=docs/design/spark-v3/spark-a-teardrop.png; D=docs/design/p26
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in exactly the painterly luminous style of the first attached image (warm golden light, soft painted detail, cozy fantasy)"
PROP="Centered, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text, no letters."
# 1. The UI kit: panels and buttons made of the world's materials.
gen $D/ui-panel-parchment.png "A wide empty game UI panel made of warm aged parchment with a thin hand-painted gold-leaf border and small ornamental corners, soft shadow inside the edge, perfectly symmetrical, flat front view, $STYLE. $PROP" $ROOTF
gen $D/ui-panel-emberglass.png "A wide empty game UI panel made of dark smoked ember-glass (deep warm brown-black, slightly translucent look) with a thin glowing golden rim and tiny ember sparks at the corners, perfectly symmetrical, flat front view, $STYLE. $PROP" $ROOTF
gen $D/ui-button-gold.png "A wide pill-shaped game button plate of polished warm gold with a soft painted highlight on top and a subtle embossed rim, empty (no text), perfectly symmetrical, flat front view, $STYLE. $PROP" $ROOTF
gen $D/ui-badge-streak.png "A small round game badge: a bright living flame inside a circular golden frame with a soft orange glow, $STYLE. $PROP" $ROOTF
gen $D/ui-badge-shield.png "A small round game badge: a soft blue-silver shield with a tiny flame emblem, inside a circular frame, $STYLE. $PROP" $ROOTF
gen $D/ui-pillars.png "Six small round game icons in a single row with space between them, each a painted emblem in a circular frame: a red-orange fist (Body), a blue open book (Mind), a pink heart-lantern (Heart), a pale lavender lotus (Spirit), a bronze hammer and anvil (Craft), a green sprouting leaf (World), $STYLE. $PROP" $ROOTF
gen $D/ui-divider.png "A long thin horizontal ornamental divider of gold leaf with a tiny flame in the middle, $STYLE. $PROP" $ROOTF
# 2. The Keepers (Plan 2.0 character bible), each alone, full body, to live in their realm.
KEEP="A cute, expressive fantasy character for a cozy painterly game, full body, three-quarter view, $STYLE."
gen $D/keeper-nimro.png "$KEEP Nim and Ro: twin little lantern-fireflies with glowing amber lantern bodies and tiny wings, big friendly eyes, side by side. $PROP" $ROOTF
gen $D/keeper-ilo.png "$KEEP Ilo: a slender silver heron standing on one leg, calm wise half-closed eyes, a faint moonlight glow. $PROP" $ROOTF
gen $D/keeper-brakka.png "$KEEP Brakka: an ancient gentle stone tortoise carrying a small mossy mountain with a tiny waterfall on her shell, kind patient eyes. $PROP" $ROOTF
gen $D/keeper-quill.png "$KEEP Quill: a playful owl folded from living paper, its feathers are book pages with faint writing, round curious eyes, a tiny ink quill tucked behind one wing. $PROP" $ROOTF
gen $D/keeper-mossbeard.png "$KEEP Mossbeard: an enormous friendly walking forest-giant spirit made of bark and moss, a long mossy beard with tiny birds and nests living in it, warm funny smile. $PROP" $ROOTF
gen $D/keeper-orrin.png "$KEEP Orrin: a soot-black salamander blacksmith with round brass spectacles and a leather apron, holding a small hammer, gruff but secretly proud expression, glowing ember spots. $PROP" $ROOTF
# 3. The Spark in parts, for real animation (pixel-matched to the second attached image).
gen $D/spark-body.png "Recreate the fire spirit from the second attached image EXACTLY (same shape, size, position, colors, framing, magenta background) but with NO face at all: no eyes, no mouth, no cheeks, a smooth glowing face area. No other change." $ROOTF $SPARK
gen $D/spark-face-sheet.png "Paint the facial features of the fire spirit in the second attached image as separate pieces in exactly its style, on a perfectly flat pure magenta #FF00FF background, in a clean grid with space between them: eyes open, eyes looking left, eyes looking right, eyes looking up, eyes closed (blink lines), happy closed eyes (^ ^), sleepy half-closed eyes, worried eyes, small smile, big open joyful mouth, small round 'o' mouth, gentle flat mouth, two rosy cheek blushes. No face around them, no text." $ROOTF $SPARK
