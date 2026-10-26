# P3.2: A fire that follows Vitality (decision 182)

Status: **plan, awaiting Mathis's approval.** Nothing built yet.

## Goal

Every form burns like a real fire, always: the whole fire moves, not just its edges. Its size follows Vitality (~7 days): a roaring fire when you've been living fully, low embers when you've been away, never out. Completing a quest makes it flare right then, and it settles back. The body, face and feet stay fixed (180).

## What the code does today

- The Flame's fire shader (`depthFire`, `Shaders.metal`) already receives Vitality (`mood`, slot x) but **doesn't use it**. It only uses a brightness value, clamped to a narrow range (0.7–1.03).
- The fire's height, tongue count, turbulence and detached tips are fixed numbers, the same at any Vitality.
- Slot w is free on the Flame's material: room for the completion flare.
- Body reactions (hops, squash) were removed under decision 180, so a completion currently doesn't change the Flame at all.

## Part A: motion references (Higgsfield → Codex)

Clips are references only; nothing ships as video (119).

1. Three to four short clips of one fire at different intensities, same framing, dark background, steady camera:
   - **Embers:** low, slow, a few small tongues, mostly glow.
   - **Calm:** a steady, moderate fire.
   - **Roaring:** tall, many tongues, fast turbulence, frequent detached tips.
   - **Flare:** a calm fire surging up for about a second, then settling (the completion moment).
2. Codex studies them next to `IMG_8546.MOV` and writes a short motion sheet: for each level, how tall, how many tongues, how fast they rise, how often tips detach, how bright the core is. Saved under `docs/design/fire-motion/`.

## Part B: wiring it into the live fire (Claude)

1. **Sustained intensity from Vitality.** In `depthFire`/`depthLive`, Vitality scales:
   - fire height (how far the crown and tongues reach above the body),
   - turbulence strength and rising speed,
   - number and size of detached tips (none in embers, frequent when roaring),
   - core brightness and glow on the ground.
   Embers stay visibly alive (decision 52: never out). The motion sheet's numbers set the endpoints.
2. **The completion flare.** When a quest is checked off, the rig sets a flare value to 1 that eases back to 0 over about 1.5 seconds; the shader adds it on top of Vitality (taller, faster, brighter, a burst of tips). Same frame as the check-off (the check-off and the reward are one moment). Vitality itself still moves only through the record.
3. **Body stays planted.** All of this happens inside the fire region; face, torso and feet stay protected as today.
4. **Mesh room.** The fire may need more transparent space above each form for the roaring level, without changing artwork scale or the foot anchor (as done for 181).

## Checks

- Simulator captures at Vitality 0.1 / 0.5 / 1.0 for every form, plus a flare sequence; zero foot movement across frames.
- Phone: steady 60 fps at full Vitality with a flare (the most demanding case).
- A developer flag to set Vitality for testing (e.g. `-vitality 0.2`) without touching the real record.
- Mathis's feel check on the iPhone decides.

## Open

- **Who generates the clips.** Checked 2026-10-17: Higgsfield isn't connected to Claude's session or to Codex. The connected generator is **Artlist** (Kling, Seedance, Veo and others), on a free trial with **one free video** left (one-time, no renewal). Option: spend it on a single clip that runs embers → calm → roaring → surge, covering all four references at once.
- **Cost.** Decision 87 says no spend: free generations only, unless Mathis decides otherwise.
