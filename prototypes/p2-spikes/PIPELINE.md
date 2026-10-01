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
| Hair geometry modifier (`CustomMaterial`) | ⏸ blocked: Xcode needs the **Metal Toolchain** download (`xcodebuild -downloadComponent MetalToolchain`), pending Mathis's permission. Shader kept in `Shaders.metal.pending` |
| Lessons | Bone-local Y runs along the bone (rotating on it twists); sway uses local Z. Crude position-based weights stretch the arms, so real characters need smooth weights. Blender emission strength > 0.6 washes colors out in RealityKit |
