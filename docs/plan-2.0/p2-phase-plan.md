# P2 Phase Plan — The 3D Tests and the Design Round

*Prove the technology on Mathis's iPhone 15, lock the look, and test a no-spend art pipeline from concept to phone. Nothing here touches the real app or the real record.*

**Status:** draft for Mathis's approval (Plan 2.0 Part 7, P2), revised after Codex's review ([`docs/reviews/2026-10-01-codex-p2-plan.md`](../reviews/2026-10-01-codex-p2-plan.md): ready with fixes; all 7 findings folded in) · **Written:** 2026-10-01
**Meets:** Part 9 §3 (the P2 gates from Codex's review) · **Constraints:** AI-only art (87), no paid Apple program (88), Alive, always (93), style anchors (95), the step-by-step fallback (97)

---

## Part A — For Mathis

### A.1 What P2 does, in one breath
Three small **test apps** check whether Apple's 3D engine can make your Flame and its world look and feel like the anchors you love, on your actual phone:
1. a living Flame;
2. a Sanctuary scene;
3. a realm coming back to life.

At the same time, **Codex designs** the final look of your Flame's stages, the first characters, the Sanctuary and the Emberspeak glyphs. Finally, one **full art trial** takes a design all the way from picture to living 3D character on your phone, using only free tools, so we learn what AI-only art can really reach before you decide anything about money.

### A.2 What you'll do (about 5 short sessions, 15–30 minutes each)
| When | You | Why |
|---|---|---|
| Start | Approve this plan; say yes or no to **downloading Blender** (free, open source, about 400 MB from blender.org) | Blender is the free 3D tool for the art trial and the test characters |
| Week 1 | Pick from Codex's concepts (stages, cast, Sanctuary) | You're the director |
| After each test | Open the test app on your phone for 5 minutes, touch the Flame, and **screen-record one minute** (Control Center → Screen Recording, then AirDrop it to the Mac) | Screenshots can't show whether it feels alive |
| End | Read the results and make the **art decision**: continue no-spend, or get quotes | P3 needs it |

### A.3 What you'll get at the end
- **A clear yes or no on Apple's engine,** with measured numbers (smoothness, memory, battery, heat) and recordings, for full quality and for the lighter mode.
- **Approved designs:** all five stages of your Flame with distinct forms, its face sheet, a turnaround (front, side, back) for 3D modeling, the Lamplighter, Nim & Ro, Orrin, the Sanctuary in the Age of Stone, Hushed vs. Alive versions, the Emberspeak glyphs, a First Words frame, and the UI kit.
- **The truth about AI-only art:** a first living 3D Flame made with free tools, what it took, how close it gets to the anchors, and what it would cost to go further.
- **Then the P3 plan** (the vertical slice), written against these results.

### A.4 How long
**About 3–4 weeks.** I work on it continuously; your part is the sessions above. If a test fails early, we switch to the next fallback step (decision 97) instead of pushing on.

---

## Part B — For the builders

### B.1 Ground rules
- **Location:** `prototypes/p2-spikes/`, never `app/`. One app, **SpikeLab**, with one screen per test, to stay within free signing's app limits (the real app plus SpikeLab = 2 apps on the phone).
- **Bundle ID:** `com.mathis.lifegamified.spikelab`. It never opens or writes the real record. Its fake growth data is generated in memory.
- **Versions (recorded with every result):** Xcode 27.0 (27A266a), macOS 27.0.1, iPhone 15 (A16, 6 GB) on iOS 26.4, deployment target iOS 26.0, RealityKit via `RealityView`.
- **The HUD on every screen:** fps, frame time, total memory, thermal state, battery level, and quality mode (Part 9 R4), plus sliders for `restoration` and `vitality` (R1).
- **Throwaway:** the code is labeled and never merged. What we learn goes into Part 5 and the P3 plan.
- **Free-signing checklist** (Apple's limits: 3 apps per device, 10 App IDs per week, 7-day expiry):
  - before the first install, inventory the free-signed apps already on the phone;
  - **one** SpikeLab app with one bundle ID and team, and no extensions;
  - re-provision weekly by reinstalling in place;
  - **never delete the real app** to fix signing;
  - assets are bundled;
  - when Codex hits a usage limit, pause and wait for the reset, never buy capacity.

### B.2 Placeholder assets (no spend)
| Need | Source | License |
|---|---|---|
| The test Flame | Built in **Blender** by Claude through Blender's Python scripting: a round body, 5 flame-hair tongues, stubby limbs, face bones, a skeleton | Ours (Blender output belongs to its author) |
| Face states | Codex face sheet (B.5) → a texture atlas for eyes and mouth | Ours (Codex output) |
| Fluffy fire | Shell layers (6–12 offset shells with noise alpha, a fur technique) + an emissive core + RealityKit particles | Ours |
| Sanctuary block-out | Simple meshes + Codex-painted textures referencing the anchors | Ours |
| Rig blending check | Apple's sample skeletal USDZ (development use only) | Apple sample terms; never shipped |

**Pinned before any asset is made** (written to `prototypes/p2-spikes/PIPELINE.md`):
- the Blender release and its version;
- the exact Apple sample file and its terms;
- **the material route:** `CustomMaterial` (Metal) first, Shader Graph only where it's simpler;
- **bloom:** `PostProcessEffect` (iOS 26+);
- **validation:** `/usr/bin/usdchecker` and Xcode's `realitytool`;
- the order in which shaders are applied after import.

**Step 0, the pipeline probe (days 1–2):** one tiny skinned model with **two blended clips, a changing face and displaced hair**, exported from Blender, imported, run on the phone, all together. If it breaks, the pipeline is fixed before anything bigger is made.

If Mathis says no to Blender: the test Flame is built from code-generated meshes animated through RealityKit's low-level mesh API. S1 is then **"partial"**, and **a partial rig result blocks the engine/art conclusion and the P3 handoff** until a real rigged character is tested.

### B.3 Spike S1: the living Flame (the feature checklist)
| # | Feature | Approach | Pass | If it fails |
|---|---|---|---|---|
| 1 | Rigged body animation, blending idle ↔ cheer ↔ walk | Skeletal USDZ, `AnimationResource` blending | Smooth blends, no pops | Fallback step 3 (pre-rendered layers) |
| 2 | **Face while the body moves** | Texture-swapped eyes/mouth + bone-driven brows | 12 face states readable during walk and cheer | Face as a 2D layer projected onto the head |
| 3 | **Fluffy fire** | 6–12 shells with noise alpha + rim light (Shader Graph or `CustomMaterial`) | Reads as plush fire next to `flame-hero.png`, side by side, at 60 fps | Fewer shells + baked fluff texture (step 1) |
| 4 | Flame hair moving continuously | Vertex animation in the shader, not a looped clip | No visible loop over 2 minutes | Particles shaped as tongues |
| 5 | Glowing core + embers | Emissive + bloom; `ParticleEmitterComponent` | Visible glow, soft embers | Additive sprite glow |
| 6 | **Alive** (decision 93) | Layered: breathing + hair + eyes + idle pool with randomness | Idle variety, no repeat pattern in 2 minutes; touch → reaction in < 100 ms; eyes follow a finger; it sways when the phone tilts (motion sensor) | Fix before anything else (it's non-negotiable) |
| 7 | Emberspeak mouth sync | Mouth states driven by the babble's loudness | In sync to the eye | Simpler open/closed sync |
| 8 | **Aware of its world** | HUD controls for local time, season, mood (Vitality) and "just did an action in pillar X" | Each gives its expected visible response (yawn and stretch in the morning, sleepy at night, seasonal tint, five moods, a pillar reaction); an interrupted reaction resumes cleanly | Fix (non-negotiable) |

**How touch response is measured:** each touch is timestamped, then the frame on which the reaction first appears is timestamped (a presented-frame callback). Measured under the S2 load and reported as p50/p95.

**Failure order for S1** (decision 97; each substitute repeats the visual, aliveness and performance checks and needs Mathis's acceptance):

| Step | What it means for S1 |
|---|---|
| 1 · Simplify | Fewer shells, a baked fluff texture, simpler hair, simpler face sync |
| 2 · Painted/live hybrid | Doesn't apply to the character itself (it stays live 3D); applies to the world in S2 |
| 3 · Layered pre-rendered character | Body animation pre-rendered from Blender as layered image sequences (body, hair, face, glow) mixed live, so it still never visibly loops |
| 4 · Unity | Only after a separately scoped Unity spike, with its own plan and Mathis's approval |

### B.4 Spikes S2 (the Sanctuary) and S3 (restoration)

**The representative combined scene** (the budget is defined, not guessed):
- **Screen:** native portrait resolution (1179 × 2556).
- **Two camera distances:** close-up (the Flame fills about 60% of the height) and gameplay (about 20%).
- **Counted together:** total rendered triangles **including the character and its shells**; transparent coverage (a target of at most 4 transparent layers over any pixel on average); material and texture counts; shadows; the water treatment; peak ceremony particles.
- **The trial Flame** (B.6) runs **inside S2 and S3**, on both routes, with face, rig, hair, glow, mist and the UI all active at once.
- **The result needs Mathis's explicit visual acceptance:** moving phone footage compared with the anchors. If only a smaller scope is accepted (e.g. "the Sanctuary at this density"), it's named as such, never reported as proof for every future stage or realm.
**S2: a scene at expected density, with SwiftUI on top.**
- A Sanctuary block-out at the expected density (about 40k triangles, 2 dynamic lights, a water plane with moving normals, layered mist cards, about 300 particles), the S1 Flame, and SwiftUI calls and plates over the scene.
- Tap-to-interact on the Flame and on one object.
- **Both rendering routes are built side by side**, so Mathis can compare them on his phone:
  - **full 3D;**
  - **painted layers** (Codex painting + parallax) with live 3D water, lights, mist and the Flame (fallback step 2).

**S3: restoration with both inputs (R1).**
- A broken arch that **rebuilds** (geometry animation).
- A waterfall that **starts flowing** (animated texture + particles).
- **Three small creatures** that appear.
- Grass greening (material).
- Mist, light and saturation driven by `vitality`.
- Tested in **all four combinations**: low/high restoration × low/high vitality.
- Plus the **Return effect**: a temporary foreground mist-lift.

**Failure order for S2 and S3** (each substitute repeats the checks and needs Mathis's acceptance):

| Step | S2 (the scene) | S3 (restoration) |
|---|---|---|
| 1 · Simplify | Fewer mist cards and particles, baked lighting, simpler water | Fewer restoring elements, simpler transitions |
| 2 · Painted/live hybrid | The painted-layers route becomes the main one | Restoration as painted states crossfaded per area, with live water, creatures and mist |
| 3 · Pre-rendered | Pre-rendered scene loops behind the live Flame | Pre-rendered restoration transitions |
| 4 · Unity | Separately scoped spike only | Same |

**A fallback has to pass, not just be chosen.** If every step fails for a spike, the engine conclusion is "not proven", and P3 doesn't start.

### B.5 The design round (Codex, AI-only, anchors as references)
Every prompt passes the anchors with `--image` (Part 4 §9): one image per call, a short prompt, no other file edits. These are added to `scripts/style-tests.sh` (re-run safe).

| File (`docs/design/…`) | Content | Reference |
|---|---|---|
| `character/stage-spark.png` … `stage-kindled.png`, `stage-beyond-silhouette.png` | Each stage alone, with **distinct form details** on top of evolution v2 (posture, markings, the Kindled crown) | evolution v2 + hero |
| `character/turnaround-flame.png` | The Flame stage: front, side, back, ¾ | hero |
| `character/face-sheet.png` | 12 eye and mouth states on a flat background, for the texture atlas | expressions |
| `character/pillar-markings.png` | Six Blaze variants, one per strongest pillar | evolution v2 |
| `cast/lamplighter.png`, `cast/nim-and-ro.png`, `cast/orrin.png` | The Act I cast, same family | hero + Grove |
| `world/sanctuary-stone-age.png` | The Sanctuary with the stone hearth and an empty spot for the Flame (portrait) | Grove + map |
| `world/sanctuary-hushed.png`, `world/grove-hushed.png` | The Hushed versions (grey, misted, nothing destroyed) | Grove / Sanctuary |
| `ui/emberspeak-glyphs.png` | 24 ember glyphs (decorative script) | — |
| `ui/first-words-frame.png` | A storyboard frame: the Spark speaking, the text box with glyphs melting into English | hero + Sanctuary |
| `ui/kit-calls-plates.png` | Calls by the hearth, plates, buttons, map UI, over the Sanctuary | Sanctuary |

Mathis picks; a rejected image is re-run with his notes.

### B.6 The end-to-end asset trial (Part 9 §3.3)
1. Take Mathis's chosen **Flame-stage design** and its turnaround.
2. Claude builds the model in Blender by script (the base mesh, then the rig).
3. Six animations: idle breathe, blink, cheer, tap-giggle, sleep, walk.
4. Materials: fluffy fire, core, face atlas.
5. Export to USDZ with a **reproducible export script** kept in the repo, validated with `/usr/bin/usdchecker` and `realitytool`.
6. Run it **in S1, S2 and S3** on the phone, on both routes.
7. **Keep every editable source**, with tool versions: the Blender file, the rig, the animations, the material and shader sources, the sound project.

What gets recorded:
- **Time spent** per step.
- **A side-by-side** with `flame-hero.png`.
- **Every license.**
- **A playable sound sample:** a procedural Emberspeak babble + fire crackle (synthesized, labeled as a placeholder).

**The asset acceptance checklist** (used for every future asset, AI-made or human-made):

| Check | Rule |
|---|---|
| Scale | 1 unit = 1 m; the Flame stage stands about 0.30 m |
| Character budget | ≤ 15k triangles, ≤ 4 materials, textures ≤ 2048², ≤ 60 bones |
| Rig | Bone names follow `flame_<part>_<side>`; root at the feet; no scale keys |
| Animations | The required list per stage; in-place (no root motion); loop points marked |
| Validation | `usdchecker` clean; it loads in S1 with no warnings |
| Performance | Passes the S1 numbers |
| Rights | A license note beside every source file |

**The no-spend continuation** is written up at the end in plain words: what an AI-built Flame reached, what it lacks next to a professional animator's work, and the honest compromise (e.g. simpler animation, painted-layer realms).

### B.7 The measurement protocol (Part 9 §3.2)
**Definitions (and the instrument behind each):**

| Measure | Definition | Instrument |
|---|---|---|
| **Frame time** | The interval between presented frames | RealityKit Trace + Animation Hitches (Instruments), exported |
| **Hitch** | A presented frame later than 2 × 16.7 ms; a **stall** is any frame over 100 ms | Animation Hitches |
| **Memory** | The whole-app physical footprint (not just allocations), steady and peak | VM Tracker / footprint in Instruments + `os_proc_available_memory` logged by the HUD |
| **Texture memory** | Resident texture memory in total (a target ≤ 200 MB), not only the per-texture cap | RealityKit Trace, Metal resource view |
| **Thermal** | `ProcessInfo.thermalState` logged every 10 s | HUD log |
| **Battery** | `UIDevice.batteryLevel` at the start and end | HUD log |

**The script:**
- **Warm-up:** 5 minutes of the scenario, not counted.
- **Then exactly 30 minutes,** repeating this 5-minute loop six times:

| Time | Event |
|---|---|
| 0:00 | Sanctuary idle |
| 1:00 | Completions at 1:00, 1:15, 1:30, 1:45 and 2:00 |
| 2:30 | A ceremony (60 s, peak particles) |
| 3:30 | Travel to the Grove (load) |
| 4:15 | Back to the Sanctuary (unload the Grove) |
| 4:45 | Background for 15 s, then foreground |

- Fixed fake data and a **fixed random seed**.
- **3 runs** for each combination: route (full 3D / painted hybrid) × mode (full / reduced).

**Memory pressure:** a debug control allocates ballast memory in steps until the system raises a memory warning on the device (real pressure; a simulator warning doesn't count). Pass: no crash; caches are released; the scene reloads within 2 s once the ballast is freed.

**Battery runs are separate from profiling:**
- **Setup:** unplugged, no Instruments, no wireless debugging, no screen recording.
- **Fixed conditions:** brightness 50%, volume 50%, Low Power Mode off, Wi-Fi on, auto-lock off, a starting charge of 80–90%, room temperature (about 20–24 °C), and 20 minutes of cooling between runs.

**Saved with every run:** the build and asset versions, the raw traces (in `prototypes/p2-spikes/traces/`, kept out of git), and a summary in the write-up. Report p50, p95 **and p99**, hitches per minute, and stalls.

**Proposed targets (to validate, not facts):** 60 fps with p95 ≤ 16.7 ms, p99 ≤ 33 ms, < 1 hitch per minute and 0 stalls outside loading; total memory ≤ 350 MB steady and ≤ 500 MB peak; resident textures ≤ 200 MB; no "serious" thermal state within 30 minutes at full quality; ≤ 10% battery per 30 minutes.

**The quality-mode test:**
- **Define each R4 mode's effects** and the precedence of triggers (thermal > Low Power Mode > user choice).
- **Exercise the automatic rules:** step down after 5 s below target, recover after 60 s stable, with no flicker.
- **Check in all five modes:** the Flame stays animated; completing, **undoing** and navigating all work; and the background image **updates when the world state changes** (so it never lies about your progress).

### B.8 Order of work
| Week | Work |
|---|---|
| 1 | The design round queued in the background (Codex) · SpikeLab skeleton + HUD · S1 (with the Blender test Flame, if approved) |
| 2 | S2 (both routes) · S3 (four combinations + Return) · Mathis tests S1 |
| 3 | The asset trial with the chosen design · measurement runs · Mathis tests S2/S3 |
| 4 | Write-ups in `docs/reviews/` · Codex review of the results · Mathis's art decision · the P3 plan begins |

### B.9 Exit criteria (P2 is done when)
1. S1–S3 results are written up with measured numbers for full and reduced quality, plus Mathis's recordings and verdict.
2. Every failed feature has a fallback that **passed** its repeated checks and was accepted by Mathis (decision 97). A partial rig result or a failed fallback chain blocks the P3 handoff.
3. The design round is approved: all stages, the face sheet, the turnaround, the cast, the Sanctuary, Hushed/Alive, glyphs, UI kit.
4. The asset trial is done, with the acceptance checklist and the no-spend continuation written.
5. **A schedule re-estimate**, built from the trial's measured work and revision time: the P3 asset workload, the approvals and phone sessions needed from Mathis, checked against his 1–2 hours a day, with the chosen no-spend compromises stated.
6. **Mathis has made the art decision** (no-spend continuation, or quotes). **Asking for quotes never authorizes outreach or a paid trial by itself:** each contact and each spend needs his explicit yes.
7. Codex has reviewed the results.
