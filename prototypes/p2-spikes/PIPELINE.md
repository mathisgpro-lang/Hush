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
