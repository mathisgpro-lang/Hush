#!/bin/zsh
# Iteration 2 art (decision 124): the quest satchel and its objects, the Grove's side panels. Re-run safe.
# In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; D=docs/design/iter2; A=prototypes/p2-spikes/SpikeLab/Assets
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in exactly the painterly luminous style of the attached image (warm golden light, soft painted detail, cozy fantasy)"
PROP="Centered, a single object, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text."
# The Quest Satchel (2c): the satchel icon, the journal's parchment, and the objects quests become in the world.
gen $D/satchel.png "A small worn leather satchel with a brass clasp and a soft golden glow seeping from under its flap, as a game icon, $STYLE. $PROP" $ROOTF
gen $D/journal-page.png "An open old parchment journal seen from straight above, two warm cream pages with soft painted texture, gentle gold-leaf corner ornaments and a ribbon bookmark, the pages blank (no writing), $STYLE. Fill the whole image with the journal, portrait, no background visible, no text." $ROOTF
gen $D/prop-lantern.png "A small unlit stone-and-brass lantern with a tiny ember inside waiting to be lit, $STYLE. $PROP" $ROOTF
gen $D/prop-scroll.png "A small rolled parchment scroll tied with a red ribbon, a faint golden glow around it, $STYLE. $PROP" $ROOTF
gen $D/prop-crystal.png "A small glowing amber crystal growing from a mossy stone, $STYLE. $PROP" $ROOTF
gen $D/prop-bloom.png "A single closed glowing flower bud on a short stem with two leaves, softly luminous petals about to open, $STYLE. $PROP" $ROOTF
# The Whispering Grove, swipeable (4): the panels that continue it left and right.
gen $D/grove-left.png "Paint the portrait panel that sits IMMEDIATELY TO THE LEFT of the attached image, as if the camera turned left: same height, same scale, same horizon, same light and painterly style. Its RIGHT edge must continue seamlessly into the LEFT edge of the attached image: more ancient giant trees with hanging glowing lanterns, mossy standing stones, ferns and white flowers, mist, a stream. Portrait 9:19.5, no characters, no text." $A/grove-paint.png
gen $D/grove-right.png "Paint the portrait panel that sits IMMEDIATELY TO THE RIGHT of the attached image, as if the camera turned right: same height, same scale, same horizon, same light and painterly style. Its LEFT edge must continue seamlessly into the RIGHT edge of the attached image: more ancient giant trees with hanging glowing lanterns, a mossy rock wall with a small waterfall, ferns and white flowers, mist, the pool continuing. Portrait 9:19.5, no characters, no text." $A/grove-paint.png
