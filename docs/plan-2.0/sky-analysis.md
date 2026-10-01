# What makes Sky immersive, and how we get there (2026-10-01)

*From Mathis's screen recording of Sky: Children of the Light (3½ min: the intro flight through clouds, the temple, the first candle).*

## What we saw
1. **A real 3D space you move *through*.** The camera flies through clouds, past ruins, toward a temple. Depth comes from parallax, fog layers and scale changes, not from a painting.
2. **Simple shapes, rich light.** The geometry is simple and stylized (soft gradients, few details). The beauty comes from **light**: bloom, lens flares, god rays, glowing particles, strong backlight and silhouettes.
3. **Atmosphere everywhere.** Haze between every layer of depth (aerial perspective); volumetric clouds; the scene fades into blue mist.
4. **Scale = awe.** The character is tiny against huge landscapes and the temple.
5. **The camera is the storyteller.** It's always slowly moving and frames where to go (the temple, the candle). No cuts.
6. **Minimal UI, in-world prompts.** A hand icon appears near the candle; one line of hint text; nothing else.
7. **Life in the air.** Birds, light creatures, drifting sparks.

## What it means for us
- Our painted worlds can't give this: a painting is a flat picture, and moving through it reveals that. **Immersion like Sky needs real 3D scenes**, but **stylized and simple**, with the work going into light, fog and camera, which also makes them very buildable from code.
- The user doesn't steer the Flame, so we can choose **authored camera paths** (slow drifting at home, flights between places, glides to spots): the cinematic quality of Sky without the cost of an open world.
- The Flame should eventually be **3D** (or at least very well lit in 3D space) to sit inside such a world.

## Best route (recommendation)
| Piece | Best tool |
|---|---|
| Engine | **Unity** (URP: fog, bloom, light, particles; Cinemachine dolly paths for authored camera flights; free) |
| Building the worlds | **Claude Code**: scenes assembled from code; stylized geometry modeled by script in **Blender** (installed); terrain, ocean, clouds, ruins from simple shapes |
| Free 3D pieces | **Kenney** and **Quaternius** (CC0 stylized kits), **Poly Pizza** (CC0), free **Unity Asset Store** packs (skyboxes, clouds, water), all license-checked |
| Art direction | **Codex** concept frames (a new direction "E: luminous stylized 3D" added to the cohesion test) |
| The Flame in 3D | Blender (scripted) or a free image-to-3D tool (your account), then animated in Unity |
| Reviews | Codex |
