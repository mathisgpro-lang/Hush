---
name: no-design-by-claude
description: "Mathis wants Codex to do all visual design AND visual integration in Hush; Claude only does logic, rules and plumbing"
metadata:
  node_type: memory
  type: feedback
  originSessionId: bb9e71c8-a71b-457f-9772-e8fd4abf570e
  modified: 2026-10-20T08:51:32.089Z
---

Claude must not touch any design aspect of Hush: art, how the Flame or worlds look, visual integration (lighting, blur, sprites in the scene), icons, screens' look. Codex does both the art and its integration in the app. Claude does only non-visual work (game rules, data, logic, tests, builds, installs, measurements) and briefs/verifies Codex.

**Why:** Mathis (2026-10-14): "don't touch any of the design aspect, it never works like it should when you try it". Codex's sketches looked right; Claude's earlier integrations made the Flame look like a sticker.

**How to apply:** When a task has a visual side, split it: do the logic, write a Codex brief for the visual part (scripts/ + resume-codex.sh), then check Codex's result in the simulator and on the phone and report honestly. If Codex is out of tokens, wait for it rather than doing the visual part yourself.

Exception pattern for interface screens (Mathis's choice, 2026-10-20, the daily screen, decision 183; the level-up screen of decision 172 was similar): Codex sketches the full screen first, Mathis approves it, then Claude builds the SwiftUI screen to match the sketch and Codex reviews the result. Ask before assuming this for art, the Flame or the worlds. Related: [[hush-perf-rules]]
