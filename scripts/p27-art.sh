#!/bin/zsh
# P2.7 art (docs/plan-2.0/p27-living-worlds.md): bar icons, the Ember coin, the character-sheet frame, creatures in
# animatable pieces, moving details. Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; ICONREF=docs/design/iter2/icon-book.png; D=docs/design/p27
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
STYLE="in exactly the painterly luminous style of the first attached image (warm golden light, soft painted detail, cozy fantasy)"
ICON="A single game UI icon object, in exactly the same painted style, lighting, size and angle as the second attached image (a painted fantasy book icon), $STYLE."
PROP="Centered, on a perfectly flat pure magenta #FF00FF background with no glow spilling onto it, no text, no letters."
# 1. Icons and the coin
gen $D/icon-map.png "$ICON A folded old fantasy world map, partly unfolded, aged parchment with tiny painted islands, a dotted path and a small red X, a little compass rose, leather tie. $PROP" $ROOTF $ICONREF
gen $D/icon-flame-lantern.png "$ICON A small ornate brass and glass lantern with a cute glowing fire spirit (round orange flame with tiny happy face) living inside it, warm light spilling through the glass. $PROP" $ROOTF $ICONREF
gen $D/ember-coin.png "$ICON A single thick gold coin with a small embossed flame emblem, glowing faintly orange at its edge, seen slightly from the front. $PROP" $ROOTF $ICONREF
gen $D/ember-pouch.png "$ICON A small leather coin pouch tied with a cord, a few glowing gold flame-coins spilling out of its open top. $PROP" $ROOTF $ICONREF
# 2. The character sheet (Witcher-inventory feel)
gen $D/sheet-frame.png "A tall portrait game inventory / character sheet background for a phone screen, in a cozy painterly fantasy style $STYLE: dark carved wood and worn brown leather with ornate gold filigree borders, two parchment inlay panels (left and right, empty), a round empty stone hearth pedestal in the centre lit by warm candlelight, five ornate empty round equipment sockets arranged around the centre, subtle embers in the air. No characters, no text, no icons inside the sockets." $ROOTF
gen $D/sheet-socket.png "A single ornate empty round equipment socket for a fantasy game inventory, dark metal ring with gold filigree and a soft inner shadow, $STYLE. $PROP" $ROOTF
gen $D/wax-seal.png "A single round red wax seal with a small flame emblem pressed into it, glossy, $STYLE. $PROP" $ROOTF
# 4. Moving details
gen $D/det-banner.png "A single long hanging cloth banner, warm red with a small gold flame emblem, fringed bottom, hanging straight, $STYLE. $PROP" $ROOTF
gen $D/det-lantern.png "A single hanging iron lantern on a short chain, glowing warm, $STYLE. $PROP" $ROOTF
gen $D/det-windmill.png "The four sail blades of a wooden windmill as one piece, seen straight from the front, centred on their hub, $STYLE. $PROP" $ROOTF
gen $D/det-leaves.png "Eight separate small falling leaves and petals laid out in a grid (autumn red, gold, green, pink blossom petals), $STYLE. $PROP" $ROOTF
