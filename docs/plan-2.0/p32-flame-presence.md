# P3.2 — Flame presence (2026-10-14)

Authorized by Mathis's request to implement the sketches in the actual game, with a finish between the two studies.

1. Produce six transparent character assets between the crisp and softly painted studies; preserve their volume and alpha when importing. Keep the other realm paintings; recompose Sanctuary at character height (170).
2. Use these same assets in the live rig, Your Flame, and onboarding. Render all six onboarding forms as dark silhouettes with readable stage names; reveal no colored details.
3. Give the character a coherent local light pool, grounding shadow, restrained ambient tint and live flame movement. Preserve facial details and avoid the previous double pixel reduction.
4. Bring the world camera closer and size/position the Flame inside the available home space. Apply the same framing rules to all seven worlds.
5. Build and inspect simulator captures: all six forms, seven worlds, onboarding silhouettes, day/night, and look-around edges. Check live motion and available performance measurements. Device feel remains Mathis's final check.

Acceptance: the actual app uses the generated art; faces retain their volume; feet/hover and light share one ground anchor; no rectangular matte or hard contour; onboarding includes Radiant and every stage name; other realm identities and viewing angles remain intact. The sketches are the visual target, not a claim that a flat painting becomes unrestricted 3D.

Status: implemented; final Release build installed on Mathis’s iPhone on 2026-10-14. Device feel awaits Mathis.

## Screen and map refinement (170)

- Use the full Sanctuary UI sketch as the composition target, with an extracted empty background and the softly shaded three-quarter character art. Keep native, functioning quest cards and navigation.
- Match Flame scale and ground anchor; compact the header and keep the ivory quests prominent.
- Show each map realm inside a distinct illustrated boundary with a readable label; space them along a discovery route. Preserve purchases and progression.
- Rebuild, inspect actual simulator screenshots and install on the iPhone.

## Delivery verification

- Release builds succeeded for iPhone simulator and physical iPhone.
- Device installation confirmed by devicectl (bundle `com.mathis.lifegamified.spikelab`, database sequence 13856). No journey-reset flags used on the phone.
- Actual simulator screenshots inspected: composed Sanctuary/Beyond, Grove/Flame, map boundaries and Radiant onboarding silhouette. The broader automated sweep was inconclusive: several captures were taken while loading. Do not count it as a completed all-form/all-world check.
- The full-screen sketch is a design reference. Actual controls remain native and interactive. The first hard-outline atlas is superseded by `evolutions-atlas-v2.png`.

- 2026-10-15: Sanctuary look-around restored and installed (sequence 13896); final left/right/up/down/rest captures inspected, full interface steady at 60.1 fps on iPhone 15. See `p32-sanctuary-look.md`.
