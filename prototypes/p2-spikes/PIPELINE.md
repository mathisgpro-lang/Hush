# P2 pipeline: pinned versions and steps (throwaway spikes)

*Required by the P2 plan §B.2 (Codex finding 7). Update this file whenever a version or step changes.*

| Piece | Pinned |
|---|---|
| macOS | 27.0.1 |
| Xcode | 27.0 (27A266a) |
| Device | iPhone 15 (A16, 6 GB), iOS 26.4; deployment target iOS 26.0 |
| Blender | 4.5.14 LTS (hash 62c1db4208e8), `/Applications/Blender.app`, from blender.org, SHA-256 `65134d9b…ca170` verified |
| Export | Blender's built-in USD exporter (`bpy.ops.wm.usd_export`), `.usdz`, Y-up, meters, armatures + animation + materials + textures |
| Validation | `/usr/bin/usdchecker` (and `usdchecker --arkit`); Xcode `realitytool` |
| Rendering | RealityKit via `RealityView`; materials: `CustomMaterial` (Metal) first, Shader Graph only where simpler; bloom: `PostProcessEffect` (iOS 26+) |
| Clips | One exported timeline; clips cut in RealityKit with `AnimationView(trimStart:trimEnd:)` |
| Face | Separate face part with its own material; face states swapped as textures at runtime |
| Part order | Material slots follow the export order: 0 body, 1 hair, 2 face (imported tints are unreliable for identification) |
| Apple sample (rig-blending check) | Not used yet. Pin the exact file and its terms here before use |

## Steps (reproducible)
1. `scripts`: `Blender --background --factory-startup --python blender/<script>.py -- <out.usdz>`
2. `usdchecker <out.usdz>`
3. Copy into `SpikeLab/Assets/` (bundled), build SpikeLab, install on the phone.
4. Materials and shaders are applied **after import**, in code (`SpikeLab/Materials/`), in this order: body → hair (geometry modifier) → face → core glow → bloom.

## Clip map (probe)
| Clip | Frames (30 fps) |
|---|---|
| idle | 1–60 |
| cheer | 61–90 |

## Step-0 probe results (2026-10-01, simulator; the device run is next)
| Check | Result |
|---|---|
| Blender → USDZ export, `usdchecker` | ✅ Success (skeleton of 6 joints, one SkelAnimation, 3 material subsets, a packaged texture, Y-up, meters) |
| RealityKit load | ✅ `Entity(named:)` loads it; `availableAnimations` = 2 (global scene + subtree), both 2.97 s |
| Two clips from one timeline | ✅ `AnimationView(trimStart:trimEnd:)` idle (looping) and cheer; both report playing |
| Blending idle ↔ cheer | ✅ `playAnimation(_:transitionDuration:)` hop + arm swing visible, back to idle |
| Face texture swap while animating | ✅ eyes-closed texture shown during idle |
| Materials applied after import | ✅ body kept, face → `UnlitMaterial` with an alpha texture |
| Hair geometry modifier (`CustomMaterial`) | ✅ after the Metal Toolchain download (839 MB, 2026-10-01): compiles and runs on the skinned mesh at 60 fps in the simulator |
| Lessons | Bone-local Y runs along the bone (rotating on it twists); sway uses local Z. Crude position-based weights stretch the arms, so real characters need smooth weights. Blender emission strength > 0.6 washes colors out in RealityKit |

## S1 alive system: first results (2026-10-01, simulator, probe Flame as a placeholder for all three routes)
| Check | Result |
|---|---|
| Idle variety (`IdlePicker`, seeded) | ✅ 2,000 picks: 10 of 11 behaviors used (doze only at night or low mood), 0 immediate repeats, 0 patterns repeated 3× (after raising the minimum cooldown to 2; the first run had 1) |
| Touch → visible response | ✅ simulator, code-triggered taps: p50 12 ms, p95 29 ms. **Real touch on the iPhone still owed** (decision 100) |
| Awareness inputs | ✅ time of day, season tint, mood → glow and animation speed; night + low mood → asleep (eyes closed, no blinks) |
| Pillar reactions | ✅ six distinct reactions after an action (hop, head tilt, warm squint + pulse, float, nod, rock) |
| Tilt | ✅ wired to CoreMotion (device) with a slider fallback in the simulator |
| Eye-follow | ⚠️ probe only: the whole head turns toward the finger. Real eye movement needs separate eye parts (routes B/C) |

## Route C, the painted rig: first results (2026-10-01, simulator, placeholder layers)
| Check | Result |
|---|---|
| Layers as textured planes (body, 5 tongues, eyes, mouth) + embers | ✅ built from `PaintedLayout`; placeholder art from `tools/rig_assets.py placeholder` |
| Tongue sway + stretch (`tongueSway`) and breathing (`breathe`) shaders on `CustomMaterial` from `UnlitMaterial` | ✅ each tongue has its own phase; never in unison |
| Draw order | ✅ after a fix: transparent layers at one depth z-fought (dark bands). Now `ModelSortGroupComponent` (strict back-to-front) + `writesDepth = false` |
| Texture edges | ✅ after a fix: clamp-to-edge sampler (with repeat, a layer's bottom row bled into its top edge as a thin line) |
| Alive system on route C | ✅ same director as route A: blinks, idles, giggle, pillar reactions, parallax glance (face moves most, body least), mood tint, sleep at night |
| Touch → response | simulator, code-triggered: p50 15 ms, p95 42 ms |
| Next | swap in Codex's layers (`docs/design/rig/`, keyed with `tools/rig_assets.py keyout`); author `PaintedLayout` for them |

## Route C preview: Codex's hero painting, alive (2026-10-01, simulator)
- `hero-keyed.png`: `flame-hero.png` with the dark background keyed out by brightness, feathered edges, the floor reflection faded.
- One subdivided plane with the `heroLive` geometry modifier: the top of the painting (flame hair) sways and licks upward, the body breathes; mood scales the motion; embers; the shared alive system (hops, tilts, lean, tap reactions).
- 60 fps, about 55 MB in the simulator. No blinking or mouth yet (that needs the face parts from the design round). Demo: `docs/design/demos/2026-10-01-codex-hero-alive.mp4`.

### Preview v2: "it looks like a fixed image" (Mathis), and what changed
- **Keying:** only darkness connected to the image border is background (`tools/hero_key.py`); dark details inside the Flame stay opaque (v1 made the irises semi-transparent).
- **Blink and happy squint:** eyes found by color, refilled from the skin above and below, lash curves drawn; textures swapped live (`hero-blink.png`, `hero-happy.png`).
- **Living fire:** `heroFireSurface` (upward-flowing waves through hair and fur, the face kept crisp, a heartbeat pulse in the core, soft flicker) + `heroLive` (sway, lick, breathing).
- **Light in the world:** a ground pool and a halo (`glowPulse`) breathing with the core.
- **No card-turning:** looking at the finger is now a small drift and lean, not a Y rotation (rotating a flat image reads as a card).
- **Lesson:** a `CustomMaterial` converted from `UnlitMaterial` behaves as lit here, and its tint reads as 0. Output color via `set_emissive_color`, and pass brightness in `custom.y`.
- Demo: `docs/design/demos/2026-10-01-codex-hero-alive-v2.mp4`. Still to come: separate parts (eyes that move, a mouth that talks, arms), a depth map (parallax), and route B (true 3D).

### Preview v3: "it needs to move around a bit more" (Mathis)
- New idles: `wander` (walks to a new spot with a waddle and per-step bounce; the ground glow follows, the halo moves with the body) and `dance`.
- Squash and stretch around the feet (`bodyPivot`): every hop has a crouch, a stretched launch, a squashed landing and a settle. Stretch, yawn, doze and pillar reactions use the same poses.
- A constant gentle float in `heroLive`, so it's never perfectly still.
- Livelier pacing for the painted Flame: idle tempo 0.55 (about 2.2–6.6 s between behaviors).
- Demo: `docs/design/demos/2026-10-01-codex-hero-alive-v3.mp4`.

### Preview v4: "its movement should be more fluid" (Mathis)
- Tweens (`move(to:)` between poses) replaced by **`FluidBody`**, stepped every frame (`SceneEvents.Update`):
  - travel follows smooth multi-octave noise, plus behavior and finger bias, through a soft spring;
  - hops use gravity, and landing impact drives a jiggly squash spring;
  - squash and stretch come from vertical speed (volume preserved);
  - it leans into motion (roll from horizontal speed) with an organic sway;
  - hair follow-through springs are fed to the shader (`custom.zw`).
- Behaviors now only set targets and impulses; the physics makes every transition flow.
- Measured on the recording: centroid displacement every 0.25 s over 21 s gave 83 samples, **0 nearly still**; motion amplitude rises and falls smoothly (bigger on hops and travel).
- Demo: `docs/design/demos/2026-10-01-codex-hero-alive-v4.mp4`.

## S2 · the painted Sanctuary: first pass (2026-10-01, simulator)
- `sanctuary-paint.png` (Codex's `sanctuary-empty.png`) on a mesh **bent in depth** (water near, steps, arches and waterfalls, then the sky far). Each vertex keeps its rest screen position (scaled along the camera ray), so the painting looks untouched from the rest camera, and camera drift or tilt reveals parallax.
- `sanctuaryLive`: rippling water with soft glints, waterfalls flowing (pale bright pixels in the middle band), the Hush grading from Vitality (grey, cool, mist, dimmer), and **the Flame's light spill** (A1), following its position and flickering.
- Mist cards just behind the Flame (it stays the clearest, warmest thing); fireflies; the HeroRig on the top step at the step's own depth, with reflection (A4) and landing embers (A3); SwiftUI calls on top (tap → the Flame reacts).
- 60 fps and about 61 MB in the simulator (one 13 fps dip while recording right after launch; to verify on the device).
- **Gap to the bar (Part 4 §10):** still one painting with a bend. Real layers (B1) and occlusion (A5) need the depth maps (queued); world-lights-Flame (A2), reactions (A7), wind (B3) and creatures (B4) are not done yet. The 3D route of S2 is not built yet.
- Demo: `docs/design/demos/2026-10-01-s2-sanctuary-painted-v2.mp4`; Hushed still: `docs/design/demos/2026-10-01-s2-hushed.png`.

## Depth from Apple's Depth Anything V2 (decision 102)
- Model: `tools/models/DepthAnythingV2SmallF16.mlpackage` (Apache-2.0, input/output 518×392), compiled with `xcrun coremlcompiler compile`.
- Tool: `swiftc -O tools/depthmap.swift -o tools/depthmap` → `./tools/depthmap <model.mlmodelc> <painting.png> <out.png> 0.5`. Portrait paintings run as 5 overlapping landscape tiles (40% overlap), each aligned to the previous one by least squares on the overlap, with feathered blending. White = near.
- S2 uses `sanctuary-depth.png` as a **relief mesh** (72×156 grid; relief = 0.45·g^0.6 − 0.15 m, mid-tones lifted so the arches separate from the cliffs); the Flame's depth is sampled at its step. 60 fps, about 64 MB in the simulator.
- Known limit: a single relief stretches at depth edges (rubber-sheet). Next: split into layers at depth discontinuities with edge inpainting, so things can pass in front of the Flame cleanly (A5).

## S2 · life and integration, round 2 (2026-10-01, simulator)
- **A2, the world lights the Flame:** in scenes (`inScene`), the hero shader adds a sunset rim on the sun side (a silhouette edge from alpha sampling) and a touch of the scene's warm haze. Brightness is passed + 10 as the switch (reflection excluded).
- **B3, wind:** `SanctuaryLife` makes a breeze plus gusts every 9–20 s (3–4.5 s, smooth rise and fall). They sway the painting's foliage (shader; wind passed through `roughness`), bend the Flame's hair and lean it, and push the fireflies.
- **B4, birds:** small flocks every 14–26 s, flapping (scaled sprite) at z −1.3. They **pass behind the arches** because the relief painting writes depth (real occlusion, A5, for free).
- **A7, the moth:** it visits for about 11 s every 25–35 s, fluttering around the Flame's head; the Flame looks at it and drifts after it. It resets once when the moth leaves (resetting every frame cancelled the wandering).
- Demo: `docs/design/demos/2026-10-01-s2-sanctuary-life.mp4`.
- Bar status: A1 ✅ light spill, A2 ✅ rim/haze (first pass), A3 ✅ landing embers (contact shade still missing), A4 ✅ reflection, A5 partial (birds behind the arches; the Flame itself can't yet walk behind things), A6 ❌ (it only moves sideways on one step), A7 partial (the moth), A8 partial; B1 partial (one relief, not layers), B2 ✅, B3 ✅, B4 partial (birds, moth), B5 ❌.

## S3 · restoration in the Whispering Grove, painted route (2026-10-01, simulator)
- Codex's `grove-scene.png` as a depth relief (Depth Anything V2, blurred 5 px to calm the depth edges).
- **474 lights** detected by color (bright, warm, saturated blobs; the sun is excluded by size) and ordered **outward from the stone circle**. `grove-lanterns.png`: R = order of the nearest lantern (Voronoi within 34 px, read with nearest filtering), G = the lantern core (soft), B = its pool of light (wide blur).
- `groveRestore` (R1): restoration 0…1 from the Heart pillar's Depth via the Part 1 §8 levels (0/3/15/50/150/400, continuous within a level). Hushed = grey, cool, dim, thick mist, every lantern dark. Lanterns relight in order (flicker, a flare when relit), color and light return early in each lit lantern's pool, then everywhere. Water moves from about level 1; fireflies return from r > 0.25; vitality thickens or thins the mist; wind sways the foliage.
- **The core loop, visible:** "A real Heart action" → the Flame cheers → a glowing strand with a spark trail arcs from its chest to the next lantern (1.1 s) → a cluster of 6 relights with a flare; Depth is raised to match (in the real app, Depth comes from the growth engine).
- Bugs fixed on the way: hard lantern discs (jagged rings, color patches) → soft G/B masks; interpolated order at region edges → nearest sampling; the sun detected as a lantern → only accepted blobs enter the mask.
- 60 fps, about 64 MB in the simulator. Demo: `docs/design/demos/2026-10-01-s3-grove-restoration.mp4`; still: `2026-10-01-s3-hushed-vs-radiant.png`.
- **Gap:** restoration here is light and color (painted); "geometry returns" (an arch rebuilding, a bridge appearing) needs painted state variants or the 3D route. Creatures returning (Nim & Ro, animals) come with the cast art.

## Route C final: the living layered Flame, from Codex's parts (2026-10-01, simulator)
- Parts: `docs/design/rig/rig-body.png`, `rig-hair.png`, `rig-face-parts.png` (flat magenta) → `tools/rig_assets.py keyout` → semantic files `SpikeLab/Assets/rig2/lf-*.png`. Fixes: pink haze removed from the closed lids; variants padded onto shared canvases (eyes 220×190 with lids low; mouths 200×140) so swaps never move parts; body and tongues eroded 1 px, with blue clamped to green (no magenta fringe).
- `LayeredFlame` (FlameRig): body (`layerBodyFire`: fire flowing upward, the face area kept crisp, heartbeat core at uv (0.5, 0.40)); 5 tongues on the head's circle (`tongueSway` + `tongueFire`; outer ones tilted, bent by hair follow-through and wind); eyes (open L/R, closed L/R as blink and happy squint, up/down from the look target); brows lift and tilt; mouth (smile, joy, o, flat, talk; Emberspeak babble when talking); face parallax; ground glow; embers. All on `FluidBody`.
- Layout measured on the body painting (px → m: body 0.17 m tall): eyes (228/502, 352) at 165 px wide, brows (222/508, 255), mouth (365, 432), head circle center (365, 290) r 300 for the hair bases.
- Bug fixed: the body used `breathe` while its custom values meant mood/brightness, which stretched it about 2× (the face landed on the chest). Breathing now comes from FluidBody only.
- 60 fps, about 59 MB in the simulator. Demo: `docs/design/demos/2026-10-01-living-flame-layers.mp4`.

## The app shell v1 (decision 105) — SpikeLab now opens on it (add `-lab` for the old test menu)
- `Shell/`:
  - `IntroView`: ember → hold with a rising haptic → flash → the Spark springs onto the circle → the 10 First Words lines in a glowing plate, an Emberspeak glyph→English melt, the Hush greying on lines 5–6 and warming on 7 → the first question with 6 interests + "I'm not sure".
  - `HomeView`: the cockpit. The Stone Age Sanctuary, calls as glowing scroll tags around the circle, a card ("I did it") → the light flies to the Flame → a reaction; a hint to where something new waits; a bar with World (badge), Book, Your Flame.
  - `RoadMapView`: Codex's map scrolled from the sea up; a road along the painted paths (waypoints), gold up to the last open realm and dotted beyond; nodes open/NEW/locked in the Hush with "Opens with…"; the Flame token travels the road; zoom into the world.
  - `RealmView`: the Grove (S3) with the LayeredFlame, glowing spots; tap → the camera glides there, clamped inside the painting; a card with the action ("Send a lantern" → the strand → lanterns relight); Map → back.
  - `ShellModel`: prototype state only.
- Scenes gained: Flame hatch (spring), camera focus, `spot(u,v)`.
- Verified in the simulator: the full loop works, lanterns 118 → 125 after an action, the NEW badge clears after visiting, and the token stays at the Grove. Known: the first tap on the map right after it appears can be swallowed by the scroll settling.
- Demo: `docs/design/demos/2026-10-01-app-shell-v1.mp4`.
