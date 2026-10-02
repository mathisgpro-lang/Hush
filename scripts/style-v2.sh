#!/bin/zsh
# Style v2 assets (decision 113): everything references the root cohesion frame. Re-run safe. In resume-codex.sh.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
CODEX="/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex"
ROOTF=docs/design/cohesion/D-luminous.png; D=docs/design/v2
gen() { local out="$1" prompt="$2"; shift 2
  [[ -f "$out" ]] && { echo "exists: $out"; return; }
  mkdir -p "$(dirname "$out")"; local args=(); for r in "$@"; do args+=(--image "$r"); done
  "$CODEX" exec -s workspace-write --ephemeral -C "$ROOT" "${args[@]}" -- "$prompt Save it as $out using your image generation tool. Do not create or edit any other file." < /dev/null > /dev/null 2>&1
  [[ -f "$out" ]] && echo "done: $out" || echo "MISSING: $out"; }
gen $D/sanctuary-home.png "Recreate the attached image EXACTLY (same composition, framing, colors, light, every detail, portrait) but REMOVE the fire character sitting on the stone circle: show the empty glowing rune circle where it sat, with its warm glow on the stones. No character, no text." $ROOTF
gen $D/rig/flame-body.png "Paint ONLY the fire character from the attached image, alone, in exactly the same painterly luminous style: front view, sitting, full body, round plush body of soft fire with its tall soft flame crest, glowing swirling chest core, but WITHOUT eyes, eyebrows, mouth or cheek blush (a smooth glowing face area). Centered, on a perfectly flat pure magenta #FF00FF background, no glow spilling onto the background, no text." $ROOTF
gen $D/rig/flame-face.png "Paint the facial features of the fire character from the attached image as separate pieces, in exactly its painterly style, on a perfectly flat pure magenta #FF00FF background, arranged in a clean grid with space between them: left eye open, right eye open, left eye closed (happy curve), right eye closed (happy curve), both eyes looking up, both eyes looking down, small smile, big open joyful mouth, small round o mouth, talking mouth, flat mouth, two rosy cheek blushes. No face around them, no text." $ROOTF
gen $D/rig/flame-crest.png "Paint ONLY the tall soft flame crest (the flame hair on top of the head) of the fire character in the attached image, split into 3 separate pieces laid out side by side with gaps (left lock, tall center lock, right lock), in exactly the same painterly luminous style, on a perfectly flat pure magenta #FF00FF background, no text." $ROOTF
# The world beyond the frame (decision 118): a wide panorama continuing the Sanctuary on all sides.
gen $D/sanctuary-panorama.png "OUTPAINTING: extend the attached painting outward to a much WIDER landscape image (about twice as wide as tall). Keep the original scene exactly as it is in the CENTER (same ruins, stone circle, waterfalls, sea, sunset, colors, brushwork), and continue the world naturally on the LEFT and RIGHT and a little above: more cliffs and ruined arches with ivy and wisteria, more waterfalls into the turquoise sea, distant islands and sea stacks in golden haze, the sunset sky continuing. Same painterly luminous style, seamless, no frame, no text, no characters." docs/design/v2/sanctuary-home.png
