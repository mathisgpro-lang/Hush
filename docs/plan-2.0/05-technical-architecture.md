# Plan 2.0 · Part 5 — Technical Architecture for a Game-Scale Universe

*How a living world and a 3D character run inside a private, native iPhone app, without losing the foundation.*

**Status:** draft with a recommendation; **requires spikes before approval** · **Written:** 2026-10-01
**Foundation kept unchanged:** decisions 28–39, 58–59, 66 (the record, the growth engine, privacy, the user holds their data). Code: `app/Packages/Core` (Domain, Storage; 67 tests).

---

## Part A — For Mathis

### A.1 The big question
The app now has to show **a living world** (scenes, a map, movement, weather, restoration) and **a stylized 3D character** with dozens of animations. Can that run in a native SwiftUI app, or does it need a **game engine**?

### A.2 The options

| Option | What it is | Strengths | Weaknesses |
|---|---|---|---|
| **A. Native Apple 3D (RealityKit) + SwiftUI** (recommended) | Apple's own 3D engine, rendered inside the app's SwiftUI screens | One language (Swift); small app; best battery and haptics; privacy and native feel kept; Apple keeps investing; the existing code plugs in directly | Fewer ready-made game tools; some features are younger (developers report quirks combining skeletal animation and blend shapes); stylized shaders need care |
| **B. Unity, embedded in the app** | The world's most used mobile game engine, running as a library inside the native app | Mature tools for characters, animation, worlds; huge asset ecosystem; artists know it | A second language (C#) and a second build system; a big app size and memory (Unity keeps ~80–180 MB in memory even when idle); harder for AI agents to build reliably in two worlds; licensing |
| **C. Godot, embedded** | An open-source game engine | Free, lighter than Unity | Embedding into a native iOS app is less mature; fewer artists and tools |
| **D. 2.5D only (SwiftUI + SpriteKit)** | Painted layers with parallax, a 2D animated character | Simplest; very performant | Can't reach the "much more 3D" character Mathis wants (decision 82) |

### A.3 Recommendation: **A, native RealityKit + SwiftUI, validated by spikes first**
- It keeps what makes the app special: **privacy, native feel, haptics, small size, one codebase that AI agents build reliably** (decisions 20, 28–30).
- It supports what's needed: 3D models (USDZ), skeletal animation, custom materials, particles, and lighting, inside SwiftUI screens.
- **The risk is real,** so we don't decide on faith: three small throwaway **spikes** (S1–S3 below) must prove it on *your* iPhone 15 first. If they fail, option B (Unity) is the fallback, and the foundation (record, engine) stays the same either way.

### A.4 What the spikes must prove (before any world building)
| Spike | Question | Pass criteria |
|---|---|---|
| **S1 · The character** | Can a stylized, rigged 3D flame character with a fluffy-fire look animate smoothly in RealityKit on an iPhone 15? | 60 fps, idle + cheer + walk blending, a glowing core, embers, < 10% battery per 30 min of use |
| **S2 · A diorama** | Can a realm scene (the Sanctuary) with lights, fog, water, particles and the character run alongside SwiftUI UI? | 60 fps, < 150 MB memory, tap-to-interact |
| **S3 · Restoration** | Can a scene blend smoothly between "Hushed" and "Alive" per area from the engine's Depth? | Visible, smooth, cheap (a shader/material parameter) |

Each spike uses placeholder assets (free sample models or Codex-made textures) and takes a few days. Results come back to you with a recommendation.

---

## Part B — For the builders

### B.1 Layered architecture (unchanged foundation, new world layer)

```
┌──────────────────────────────────────────────────────────────┐
│ Features (SwiftUI): Sanctuary · World · Realm · Flame · Book │
│                     · Keepers · Settings                     │
├──────────────────────────────────────────────────────────────┤
│ Universe (NEW): WorldRenderer (RealityKit) · CharacterRig    │
│   · SceneDirector (ceremonies, travel) · RestorationShading  │
├──────────────────────────────────────────────────────────────┤
│ Experience: Theme · Sensory (haptics, sound, music) · UI kit │
├──────────────────────────────────────────────────────────────┤
│ Companion (Keepers' counsel; later: PCC)  │ Relay (Gatherings)│
├──────────────────────────────────────────────────────────────┤
│ Storage (GRDB record, sync later) ─── Domain (pure): growth, │
│   journey, dealer, character stages, WORLD + JOURNEYS (NEW)  │
└──────────────────────────────────────────────────────────────┘
```
- **The rule (decision 66 plus the universe):** `Domain` decides *what is true* (restoration levels, unlocks, stages, Journey progress). The `Universe` layer only *draws* it. No world logic lives in rendering code.

### B.2 New Domain models (pure, tested, from the record)

```
Realm { id, pillar, levels: [threshold], places: [PlaceId], keeper: KeeperId, beacon: BeaconId }
RestorationState(realm) = level + intra-level progress ∈ [0,1], from Depth(pillar) (Part 1 §8)
JourneyDef { id, realm, templateId, chapters: [Chapter], waypoints: [Waypoint], finale: PlaceId }
JourneyProgress = steps completed / plan structure → position on the road (from the record's scheduleIssued + completions)
CharacterState { stage (built), mood, pillarShape: [Pillar: Double], wearing: [KeepsakeId] }
Keepsake { id, kind: worn|carried|home, earnedBy: Condition, window? }   // grants (never revoked)
SeasonCalendar { season(for: LocalDate) }                                // Thaw/LongLight/Harvest/Embernight
StoryBeat { id, act, trigger: Condition, scene: SceneId }               // witnessed once (momentWitnessed)
```
All of these are **derived** from the existing record (`actionCompleted`, `scheduleIssued`, `momentWitnessed`, grants). **No new truth is stored for the world** except: placement of keepsakes at home (a P setting), the Flame's name (an H2 attachment, it's words), and the chosen worn items (a setting).

### B.3 Rendering
- **Engine:** RealityKit via `RealityView` in SwiftUI (iOS 26+), validated by S1–S3.
- **Assets:** USDZ authored in Blender (by a human artist), with stylized materials via Reality Composer Pro's Shader Graph. One package per realm (a Reality Composer Pro bundle). Characters are rigged with skeletal animation; facial expressions use **texture-swapped eyes/mouth or bone-driven face**, avoiding the reported issues with blend shapes combined with skeletal animation.
- **Restoration shading:** one material parameter per area (`hush ∈ [0,1]`), driven by `RestorationState`, controlling saturation, fog density and emissives.
- **Performance budget (iPhone 15):** 60 fps target, ≤ 150 MB memory per scene, ≤ 50k triangles per scene, ≤ 2 dynamic lights, baked lighting where possible, scenes loaded per realm (never all at once).
- **Fallback:** if a device can't hold 60 fps, drop particles first, then the Hush fog, then switch to a pre-rendered still with the character on top.

### B.4 Content delivery
- Realm packages are large, so: **realm 1 (the Sanctuary) ships in the app**; other realms download as **Apple On-Demand Resources / Background Assets** when unlocked, from Apple's servers (no personal data involved).
- Story beats, Encounters, Journey definitions and Keeper counsel ship in the **content catalog** (chapter 16 §B.10), so they can be updated without app releases.

### B.5 The character state machine
```
inputs: CharacterState + events (completion(pillar), comeback, ceremony(kind), tap, longPress, travel(to))
states: idle(mood) ⇄ react(event) → idle; travel(path) → arrive → idle; ceremony(kind) → idle
rules: every reaction is interruptible; ceremonies queue (one at a time); Reduce Motion → face-only reactions
```

### B.6 Migration from today's app
| Today | Becomes |
|---|---|
| `FlameCharacter` (2D procedural) | The `CharacterRig` (3D); 2D kept as a fallback for low-power mode |
| `SanctuaryView` (image + crossfade) | The Sanctuary diorama in RealityKit |
| `WorldMapView` (drawn islands) | The painted 3D or 2.5D map scene with real paths and travel |
| `LocationScene` | Realm scenes |
| Cards on Today | In-world "calls" near the hearth |
| `Journey` (steps I–VI) | Act I story beats |

### B.7 Spike plan (the first engineering work after approval)
1. **S1 Character:** a test rig (a free sample or a quick Blender rig of a blob flame), idle/cheer/walk, fluffy shader test, measured on the iPhone 15 (fps, memory, battery).
2. **S2 Diorama:** a simple Sanctuary block-out with fog, a water plane, particles and the S1 character, plus SwiftUI calls on top.
3. **S3 Restoration:** a `hush` parameter animating saturation and fog on S2's scene.

The spikes are throwaway and labeled; the results are written up in `docs/reviews/` and reviewed by Codex.

### B.8 Research notes (2026-10-01)
- RealityKit on iOS supports `RealityView`, skeletal animation and Shader Graph materials; developers report issues combining skeletal animation with blend shapes on rigged USDZ characters: [Apple forums, RealityKit](https://developer.apple.com/forums/topics/graphics-and-games-topic/spatial-computing-realitykit?page=3&sortBy=newest); Shader Graph parameters can be driven per frame from SwiftUI: [example](https://github.com/haikusw/schwa_ShaderGraphParameterAnimationExample).
- Unity as a Library is supported in Unity 6 for embedding in native iOS/SwiftUI apps; it retains ~80–180 MB of memory when unloaded: [Unity docs](https://docs.unity.com/en-us/engine/6000.0/manual/platform-specific/iphone/ios-developing/unityasa-library-ios), [SwiftUI integration](https://github.com/bdeweygit/unity-swiftui).
