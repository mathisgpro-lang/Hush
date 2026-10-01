# P2 Phase Plan — The 3D Tests and the Design Round

*Prove the technology on Mathis's iPhone 15, lock the look, and test a no-spend art pipeline from concept to phone. Nothing here touches the real app or the real record.*

**Status:** draft for Mathis's approval (Plan 2.0 Part 7, P2) · **Written:** 2026-10-01
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

### B.2 Placeholder assets (no spend)
| Need | Source | License |
|---|---|---|
| The test Flame | Built in **Blender** by Claude through Blender's Python scripting: a round body, 5 flame-hair tongues, stubby limbs, face bones, a skeleton | Ours (Blender output belongs to its author) |
| Face states | Codex face sheet (B.5) → a texture atlas for eyes and mouth | Ours (Codex output) |
| Fluffy fire | Shell layers (6–12 offset shells with noise alpha, a fur technique) + an emissive core + RealityKit particles | Ours |
| Sanctuary block-out | Simple meshes + Codex-painted textures referencing the anchors | Ours |
| Rig blending check | Apple's sample skeletal USDZ (development use only) | Apple sample terms; never shipped |

If Mathis says no to Blender: the test Flame is built from code-generated meshes animated through RealityKit's low-level mesh API. That's less representative of real rigging, so S1 would then be marked "partial".

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

### B.4 Spikes S2 (the Sanctuary) and S3 (restoration)
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
5. Export to USDZ with a **reproducible export script** kept in the repo, validated with Apple's `usdchecker`/`realitytool`.
6. Run in S1 on the phone.

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
- **Tools:** Xcode Instruments (free) on the device: the RealityKit Trace, Animation Hitches and Allocations templates.
- **Conditions, fixed:** brightness 50%, volume 50%, Low Power Mode off, Wi-Fi on, auto-lock off, battery ≥ 80% at the start, not charging, room temperature.
- **The 30-minute scenario,** repeated: 60 s idle → 5 completions → 1 ceremony → Sanctuary → Grove → Sanctuary → background and back. Run once at full quality and once at reduced quality.
- **Measured:**
  - frame time p50/p95/p99;
  - hitches per minute;
  - total-app memory, steady and **peak** (including scene transitions);
  - texture memory;
  - the thermal state over time;
  - battery used.
- **Proposed targets (to validate, not facts):** 60 fps with p95 ≤ 16.7 ms and < 1 hitch per minute; total memory ≤ 350 MB steady and ≤ 500 MB peak; scene assets ≤ 150 MB; no "serious" thermal state within 30 minutes at full quality; ≤ 10% battery per 30 minutes.
- **The quality-mode test:** force each R4 mode, check that hysteresis prevents flicker, and check that every mode keeps the Flame animated and the controls working.

### B.8 Order of work
| Week | Work |
|---|---|
| 1 | The design round queued in the background (Codex) · SpikeLab skeleton + HUD · S1 (with the Blender test Flame, if approved) |
| 2 | S2 (both routes) · S3 (four combinations + Return) · Mathis tests S1 |
| 3 | The asset trial with the chosen design · measurement runs · Mathis tests S2/S3 |
| 4 | Write-ups in `docs/reviews/` · Codex review of the results · Mathis's art decision · the P3 plan begins |

### B.9 Exit criteria (P2 is done when)
1. S1–S3 results are written up with measured numbers for full and reduced quality, plus Mathis's recordings and verdict.
2. Every failed feature has its fallback step chosen and shown to Mathis (decision 97).
3. The design round is approved: all stages, the face sheet, the turnaround, the cast, the Sanctuary, Hushed/Alive, glyphs, UI kit.
4. The asset trial is done, with the acceptance checklist and the no-spend continuation written.
5. **Mathis has made the art decision** (no-spend continuation, or quotes).
6. Codex has reviewed the results.
