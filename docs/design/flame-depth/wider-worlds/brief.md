# Wider worlds — sketch brief, 2026-10-15

Mathis requested sketches before this framing pass: pull the camera back in Sanctuary and every other world, revealing more environment while keeping the smaller Flame the clear hero. These images are design studies, not installed runtime changes.

## Composition

- Reuse the existing paintings and preserve each world's identity. Outpaint connected scenery where the wider view and swipe envelope exceed the source artwork. Do not stretch or mirror edge pixels.
- Shared frontal camera angle, shallow elliptical circle, and consistent apparent Flame scale across worlds. Target roughly 30% smaller than the installed large-character composition; adjust for each evolution's silhouette.
- Center the character/circle grouping in the free space between the compact header and quest panel. The hero's face must read clearly, feet and light must meet the circle, and breathing must not overlap controls. Exact runtime anchoring follows the measured free space, not arbitrary coordinates from a generated sketch.
- Sanctuary reveals more ruins, waterfalls, sea and sky. Grove retains lantern trees and waterfall valley; Stillwater its lake and island rotunda; Highlands its climbing terraces and banners; Forge its machinery and molten cascades; Library its bookshelves and floating towers; Wilds its meadow, windmill village and river.
- Preserve prominent ivory quest cards, three visible rows, fold control, navigation and gesture ownership. The world continues behind the full interface.

## Implementation acceptance, after the sketch stage

1. Size camera and character together. Preserve the character's real ground anchor, contact shadow and local light.
2. Measure the complete camera envelope including horizontal/vertical pans, rubber band, parallax, framing lift and motion. Extend every required edge with registered artwork; test corners as well as four directional limits. No canvas edge, black stripe, duplicated landmark or seam.
3. Preserve look-around spring behavior and live movement. Never flatten the mockup into a single screenshot used as the interactive screen.
4. Measure the full animated interface on the iPhone at rest and during swipes. Target 60 fps; static sketches cannot establish performance. Retain the LiveIcon alpha-blend performance fix.
5. Keep existing journey data; install without journey-reset flags when implementing the approved direction.

Boards: `01-sanctuary.png`, `02-grove-stillwater-highlands.png`, `03-forge-library-wilds.png`. Generated text and exact spacing are visual guides; native controls remain the source for functional behavior and legibility.
