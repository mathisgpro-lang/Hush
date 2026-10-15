# Sanctuary look-around extension — 2026-10-15

Source: `live/sanctuary-stage.png` (the approved home painting). Generated continuation: `live/sanctuary-surround.png`, copied unchanged into `Assets/stage-home-surround.png`.

Image-generation direction: outpaint the existing Sanctuary equally on each side and above/below, requesting 2.4 times the original width and 1.8 times its height. Preserve the central scene, perspective, palette, stone circle, braziers and their scale. Continue the ruined arches, ivy, flowers, waterfalls, ravine and foreground paving. No characters, interface, text or additional circles.

The delivered image's inset differed from the requested proportions. Image registration against the original measured normalized scale `(0.547633, 0.723277)` and center `(0.503511, 0.508919)`. `stageWorld` uses that registration, rather than assuming the requested dimensions. The first unregistered trial duplicated a brazier and was rejected.

The original painting remains the core texture; a narrow feather joins it to the extension. The mesh covers 1.8 times the original width and 1.35 times its height, inside the usable continuation. The Flame's coordinates, original painting scale, circle and ground lighting remain in their original coordinate system. Both textures share one surface shader and lighting treatment. No extra blurred UI layer is introduced.

The screenshot checks live in `verification/sanctuary-look/`. These are actual simulator captures, not design mockups. Physical iPhone performance must be measured separately.
