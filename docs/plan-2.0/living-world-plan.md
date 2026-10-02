# The Living World Plan (decision 118)

*Mathis: "it should genuinely feel like the world is endless… this is the part which will make or break this app". And: "how can we add the animated feeling, not just a painted feeling?"*

## Why it still feels "painted"
One flat painting with effects on top. Real animated worlds (Ori, Alba, Sky, Hollow Knight) are built from **separate layers and separate living things**, each moving on its own, with a camera that reveals space.

## The approach: a layered, living diorama
1. **A bigger world (Codex):** a wide panorama continuing the Sanctuary on all sides (in progress: `docs/design/v2/sanctuary-panorama.png`).
2. **Cut into real layers (Codex + Apple's depth model):** sky plate → far sea and islands → mid cliffs and arches → the Sanctuary island and circle → foreground foliage and flowers. Each layer is its own picture (with the parts behind it painted in), so layers can truly slide past each other.
3. **Every layer lives on its own:**
   - the sky: clouds drifting slowly across it, the sun or moon moving with the hour;
   - the sea: a real moving water surface (rolling swell, glitter, foam around rocks);
   - waterfalls: flowing water plus spray particles and mist at their feet;
   - braziers and lanterns: real flame sprites burning (not warped paint), lighting the stones;
   - foliage: trees, ivy and flowers bending from their roots in the wind, gusts rolling through;
   - life: birds crossing, butterflies, fish glints, fireflies at night.
4. **A camera that reveals space:** gentle drift and phone-tilt parallax; **swipe to look around** the wider panorama; a slow establishing move when you arrive.
5. **No edges, ever:** the world always extends past the screen (the backdrop safeguard is already in place).

## Free options to go further
- **Image-to-video tools** (Kling, Luma Dream Machine, Runway, free tiers; Mathis's account needed): can turn a layer into a seamless looping animation (waves, foliage, clouds). Evaluate on one layer.
- **Rive / Lottie** (free): small looping UI and creature animations.
