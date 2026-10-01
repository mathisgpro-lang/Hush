# The 3D World, Step 1: the Sanctuary island (Unity)

*From painted pictures to a real, Sky-like 3D world: stylized and simple shapes, with the effort in light, fog, atmosphere and authored camera flights (sky-analysis.md).*

**Status:** approved direction (decision 111) · **Written:** 2026-10-01 · **Where:** `prototypes/unity-test/HushUnity` (the scene `Assets/Scenes/Island3D.unity`, built from code by `HushIsland3D.cs`)

## What step 1 builds
1. **The Sanctuary island in 3D:** rocky cliffs rising from the sea; the stone circle with glowing runes at its heart; ruined arches and pillars; braziers with real fire light; trees; waterfalls spilling into the sea.
2. **A world around it:** an ocean to the horizon, a dusk sky with a low sun, distant islands in the haze (the other realms, silhouettes for now: the Grove's lantern glow, the Library's floating shapes, Forge Mountain's ember light).
3. **Atmosphere (the Sky lesson):** layered fog for depth, bloom, a soft color grade, light shafts from the sun, drifting cloud banks, embers and birds in the air.
4. **Your Flame on the circle** (Codex's layered parts, facing the camera) as **a real light** that warms the stones in 3D.
5. **An authored camera:** at home it slowly drifts around the circle (never still). **The rise:** it lifts above the island, through cloud, until the Sanctuary is a small island in a vast misty sea with the realms glowing far away. **The dive** brings you back.
6. **The hold moment** on one task object (as in the test).

## Not yet (later steps)
- Entering the Grove in 3D;
- the Flame as a true 3D model;
- the tutorial;
- real art passes on every object;
- sound beyond the synthesized set.

## How it's built
Everything is generated from C# in the editor: procedural meshes for cliffs and ruins, custom URP shaders (ocean, sky, the Flame's sprites), a post-processing volume, and Cinemachine cameras. Built from the command line, installed on the iPhone.

## Judged by
On the phone, by Mathis: does it start to feel like an immersive 3D world (depth, light, atmosphere, a camera that flies), with the Flame belonging to it? Plus 60 fps on the iPhone 15.
