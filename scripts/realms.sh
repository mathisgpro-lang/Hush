#!/bin/zsh
# The next worlds (2026-10-03): each realm painted from its place on the world map, in the style root, at the Grove's
# eye level, with a stone circle where the Spark hovers. Then its left and right panels (swipeable, no edges).
# Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; GROVE=prototypes/p2-spikes/SpikeLab/Assets/grove-paint.png; D=docs/design/realms
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
MAIN="A tall portrait painting (9:19.5) of a fantasy realm, in exactly the painterly luminous style of the first attached image (warm golden light, rich painted detail, cozy fantasy, no photorealism). Compose it EXACTLY like the second attached image: an eye-level view standing inside the place, a round empty stone circle with glowing runes on the ground in the lower middle (where a small fire spirit will hover; leave it EMPTY), depth leading back to a sunset sky, framing elements left and right. The third attached image shows this realm from above on the world map: match its colors and landmarks. No characters, no creatures, no text."
panel() { echo "Paint the portrait panel that sits IMMEDIATELY TO THE $1 of the attached image, as if the camera turned $2: same height, same scale, same horizon, same light and painterly style. Its $3 edge must continue seamlessly into the $4 edge of the attached image: $5 Portrait 9:19.5, no characters, no text."; }
realm() { local n="$1" desc="$2" left="$3" right="$4"
  gen $D/$n.png "$MAIN The realm: $desc" $ROOTF $GROVE $D/ref/$n-map.png
  [[ -f $D/$n.png ]] || return
  gen $D/$n-left.png "$(panel LEFT left RIGHT LEFT "$left")" $D/$n.png
  gen $D/$n-right.png "$(panel RIGHT right LEFT RIGHT "$right")" $D/$n.png
}
realm stillwater "THE STILLWATER (Spirit): a vast mirror lake at the edge of night, perfectly still water reflecting a sky full of slow stars and the last violet-gold of sunset, lotus flowers and lotus stepping stones leading across the water, a small elegant pavilion floating at the center in the distance, willow trees and soft mist on the shore; the stone circle sits on a little stone platform at the water's edge." "more of the mirror lake, willows and reeds, lotus pads, a few glowing stones on the shore, mist." "more of the lake reaching to distant moonlit hills, lotus stepping stones, a tiny lantern boat, mist."
realm highlands "THE ASCENT HIGHLANDS (Body): terraced hills and dramatic cliffs with roaring waterfalls, wind-carved stone stairs climbing up the mountain, an old domed observatory on the summit far above, prayer-flag-like banners in the wind, warm ember and sunrise tones; the stone circle sits on a wide stone terrace at the foot of the stairs." "more cliffs and terraces, a tall waterfall, wind-carved stairs, fallen stone arches (a training ground)." "more mountains, a waterfall staircase, a garden of pale moonflowers on a ledge, banners in the wind."
realm library "THE LIBRARY OF EMBERS (Mind): a floating island of towering ancient bookshelves open to the sky, books drifting through the air like birds, warm reading lamps and ink-blue light, spiral stairs, a great glowing lantern atop the tallest shelf tower; the stone circle sits on a mosaic floor between the shelves." "more towering shelves and floating book-islands, a cozy reading nook with a fireplace, paper cranes in the air." "more shelves opening onto the sky, a map room with a giant globe and hanging star charts, drifting books."
realm wilds "THE WILDS (World): wide green lands with wildflower meadows, a winding river, a small abandoned village of cottages with dark windows, old trees, migrating birds in the sky, distant blue mountains at sunset; the stone circle sits in a meadow clearing by the river." "more meadows and a forest edge, the river bending, a little wooden bridge, wildflowers." "more of the empty village and its well, a hill with a far lookout tower, the river flowing to distant mountains."
realm forge "FORGE MOUNTAIN (Craft): a volcano-mountain hollowed into great workshops, rivers of molten golden light, bronze machinery, gears and chains, huge anvils, glowing furnaces, an ancient precise craftsmanship mood; the stone circle is a bronze-and-stone forge floor with glowing runes in a great hall open to the sky." "more workshops carved into the rock, a waterfall of molten light, bronze cranes and chains." "more of the great hall, a gigantic anvil, racks of tools, furnaces glowing, smoke rising to the sunset sky."
