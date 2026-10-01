# P2.5 Design Spec — Storyboards (D2) and the Interaction, Motion & Sound Language (D3)

*The exact experience, beat by beat, before it's built. Every beat lists what you see, what you do, the camera, the motion, the haptic and the sound, so nothing is left to improvisation.*

**Status:** draft for Mathis's review · **Written:** 2026-10-01 · **Implements:** Part 10 (the Cohesion Plan, decision 108)
**Art note:** the visuals here follow whichever cohesion direction Mathis picks (D1). The beats, timings and feel don't depend on it.

---

## Part A — The language (D3)

### A.1 Gestures: one meaning each, everywhere
| Gesture | Means | Never used for |
|---|---|---|
| **Hold** (≈1.0 s, with rising feedback; release early = nothing happens, softly) | **Give light**: complete something, confirm a meaningful choice | Navigation |
| **Tap** | Look closer, open, talk to the Flame | Completing |
| **Swipe** (sideways on the map, along a road) | Travel, scroll the land | Dismissing important things |
| **Pinch out / the horizon button** | Rise: home → map, realm → map | — |
| **Pinch in / tap a place** | Descend into a place | — |
| **Swipe down on a parchment** | Put it away | — |

### A.2 Motion tokens (every animation uses one of these)
| Token | Use | Spring (response / damping) | Notes |
|---|---|---|---|
| `breath` | Idle life: the Flame, objects, glows | — (continuous, 3–6 s cycles, never in sync) | Nothing on screen is perfectly still |
| `soft` | Panels, parchments, text | 0.50 s / 0.85 | Gentle settle, no visible bounce |
| `weighty` | The Flame, task objects, things with mass | 0.65 s / 0.65 | Visible overshoot, squash and stretch |
| `snappy` | Tap feedback, small icons | 0.25 s / 0.80 | Immediate |
| `flight` | Light strands, the Flame traveling | Bézier arcs, 0.9–1.4 s, ease-in-out | Always an arc, never a straight line |
| `camera` | Every camera move | 1.2–2.0 s, slow-in slow-out, no overshoot | The cinematic one. Never shorter than 1.2 s |

Rules:
- No linear motion.
- No move under 0.15 s.
- Text never animates letter by letter except Emberspeak glyphs.
- Every animation can be skipped by tapping.

### A.3 Haptic patterns (Core Haptics)
| Pattern | Feels like | Shape |
|---|---|---|
| `heartbeat` | Touching your Flame | Two soft taps (0.4, then 0.25 intensity, 120 ms apart), sharpness 0.2 |
| `charge` | The hold | Continuous, intensity 0.15 → 0.8 over 1.0 s, sharpness rising 0.1 → 0.5, with soft ticks every 120 ms |
| `ignite` | The moment light is given | One strong transient (1.0, sharpness 0.6) + a 0.4 s warm tail (0.5 → 0) |
| `catch` | Your Flame catches the light | Soft double tap (0.6, 0.3) |
| `rise` | The camera rising to the map | A swelling continuous rumble 0.1 → 0.4 → 0 over 1.5 s, low sharpness |
| `arrive` | Landing in a realm | One deep, soft thump (0.7, sharpness 0.1) |
| `nudge` | The Flame points at something new | One very light tap (0.25) |
| `nope` | Something locked | Two quick light taps, sharpness 0.8 (never harsh) |

### A.4 Sound list (each event, with what to look for in free libraries)
| Event | Sound | Free source to search |
|---|---|---|
| Ember (intro) | Low wind, a faint heartbeat, a soft crackle growing | freesound CC0: "soft wind loop", "heartbeat soft", "ember crackle" |
| Hatch | A warm whoosh into a bell-like bloom | freesound/Pixabay: "magic whoosh", "bell bloom" |
| The Flame's voice | Emberspeak babble: 3–5 pitched syllables, giggle, hum, yawn | CC0 voice syllables, pitch-shifted + warm filter (made in-house) |
| Hold `charge` | A rising airy tone in the scene's key | Synthesized (sine + noise), per pillar timbre |
| `ignite` | A soft fire bloom + a chime in the scene's key | freesound: "fire ignite soft", "chime" |
| Light flight | A shimmering sweep following the arc | Pixabay: "magic sweep" |
| `catch` | A small happy crackle + a giggle | freesound + voice |
| Camera `rise` | Wind swell, distant birds, the music opens up | Sonniss GDC bundle: wind ambiences |
| Arrival in a realm | The realm's ambience fades in under a short motif | Per realm |
| Ambience: Sanctuary | Calm sea, a breeze, distant waterfalls, braziers | freesound CC0 field recordings |
| Ambience: Grove | Leaves, soft chimes, night insects, an owl | freesound CC0 |
| Ambience: the map | High wind, a faint choir pad | Sonniss / Pixabay |
| Music | A main motif (piano + strings + soft choir), 2–3 minute loops: home (day, evening), Grove, the map, the Hush (sparse) | Pixabay Music (royalty-free), CC0 tracks; replaced later by a composer if wanted |
| The Hush | Sound thins out: filtered, quieter, wind | Processing of the same layers |

Rules:
- Respect the silent switch (ambient category).
- Music ducks under the Flame's voice and the tracking moment.
- Each file is logged in `docs/design/sound/LICENSES.md` (source, author, license).
- **Downloads are asked first** (each pack named, with its size and source).

### A.5 Task objects: states and behavior
Each task object (lantern, page, footprint stones, water bowl, ember on an anvil, seed) has the same seven states:

| State | Visual | Motion | Sound / haptic |
|---|---|---|---|
| 1 · Arriving | The Flame carries or conjures it onto the circle | `weighty` drop with a little bounce | soft thud, `nudge` |
| 2 · Waiting | Dim, softly breathing, its pillar color faint | `breath` | — |
| 3 · Noticed | The Flame glances at it now and then; a slight glow pulse | `breath` + a glance | — |
| 4 · Open | Tap → the camera leans in 10%, a parchment unfolds from it (title, 1–2 lines, source) | `soft` + `camera` (short lean) | paper unfold |
| 5 · Charging | Hold → light flows from the finger into it; it brightens | intensity follows the hold | `charge` + rising tone |
| 6 · Ignited | It lights fully, sparks burst; the Flame cheers and catches a strand | `weighty` pop | `ignite`, then `catch` |
| 7 · Gone to its realm | The light flies to the horizon in its realm's direction; a far flare; the object fades to a small glowing rune on the circle | `flight` | sweep, distant chime |

Undo: for 5 s after state 7, the rune can be tapped to take it back (the light returns, softly).

### A.6 The indication system ("where to go", always clear)
1. **The Flame looks and walks toward what's new** (diegetic). This is the main cue.
2. **A soft glow pulse** on the target: never a red badge, never an arrow overlay.
3. **The horizon** from home shows the realm where something waits as a glimmer, and the horizon button glows.
4. **On the map, a light trail** runs along the road to it.
5. **Today's count:** small glowing runes on the circle (done) and the waiting objects (to do); nothing else.

### A.7 Text and voice
- At most two lines at once.
- The Flame speaks in first person, short and warm; a Keeper speaks in its own voice; system text barely exists (Settings only).
- Fonts (free, Google Fonts): a display serif with character (candidates: *Cormorant Garamond*, *Fraunces*) for names and the Flame's words, and *Inter* for small functional text. The choice is made with the style bible (D1).

---

## Part B — Storyboards (D2)

### B.1 The first minutes (the tutorial; about 80 s)
| # | Time | You see | You do | Camera | Sound / haptic | Text (max 2 lines) |
|---|---|---|---|---|---|---|
| 1 | 0–6 s | Black. A single ember breathing; faint wind | — | Static | Wind, faint heartbeat | *Every person carries a flame.* |
| 2 | 6–12 s | The ember brightens as you touch it; cracks of light | **Hold** the ember (the first lesson: hold = give) | Slow push-in | `charge`, rising tone | *Touch it. Hold.* (appears only if you don't touch within 3 s) |
| 3 | 12–16 s | Burst of light; the Sanctuary dawns around a tiny Spark on the circle | — | Pull back from the light to the home view | `ignite`, hatch bloom, music enters softly | — |
| 4 | 16–24 s | The Spark blinks, wobbles, finds you, babbles | **Tap** it (prompted by its look); it giggles | Static | `heartbeat`, giggle | *…Oh. There you are.* → *I'm your Flame.* |
| 5 | 24–45 s | It conjures a water bowl with a candle onto the circle | **Tap** the bowl → the parchment: "Three slow breaths, right now." Do it. **Hold** the bowl → it ignites, the light flies into the Flame, the Flame glows brighter | Short lean-in, back | `charge` → `ignite` → `catch` | *Light is what I'm made of.* → *Every real thing you do makes some.* |
| 6 | 45–58 s | Six glowing stones rise around the circle, each with a word (Love, Read, Calm, Move, Make, Nature) + "not sure" | **Tap** one; the Flame takes it in its arms | Static | Chime per stone | *What would make this year feel alive?* |
| 7 | 58–72 s | The camera **rises** through clouds: the Sanctuary becomes an island; the Emberlands below are grey with mist; one realm (your choice's) glimmers | Watch; the pinch hint appears at the end | `camera` rise, 2.0 s | `rise`, wind, music opens | *The world out there went quiet.* → *We'll wake it, one light at a time.* |
| 8 | 72–80 s | The camera dives back home; your first real task object waits on the circle; the Flame yawns, content | Free | `camera` dive | `arrive` | *I'll have something for you each day.* |

What is **not** in the first minutes (it comes later, just in time): the Hush's full story, the Beacons, the Veil, "a tool, not a cage", the Book, Keepers, Encounters.

### B.2 A normal day (morning to evening)
1. **Opening the app in the morning:** the Flame is stretching, the light is morning gold, and 1–3 task objects are already on the circle (they arrived overnight). Sound: birds, the sea.
2. **Tap a task object** → the parchment → close it (swipe down), or do the task in real life.
3. **Later, done:** **hold** the object → states 5–7 → the light flies toward its realm. The circle gains a rune.
4. **Curious?** Pinch out → rise to the map → see the light that just arrived in that realm (a fresh glow) → tap the realm to visit, or pinch in to go home.
5. **Evening** (after 20:00, or tap the hearth): the Flame sits by the hearth, the day's runes drift into the fire (15 s), and it says one line about your day, then sleeps.

### B.3 Traveling to a realm
1. Map: tap the Grove (it glimmers; a light trail on the road).
2. The Flame token walks the road (`flight` along the path, small hops at bends); the camera follows, slightly ahead.
3. At the Grove, the camera dives; **a drifting leaf-and-lantern-light layer** masks the scene change (0.6 s).
4. Inside: the Flame lands on the stone circle (`arrive`); the Grove's ambience fades in; the glowing spots appear one by one.
5. Back: pinch out or the horizon button; the camera rises through the canopy (leaf layer) to the map.

### B.4 Evening at the Hearth
Covered in B.2 §5; a dedicated scene: the hearth close-up, the runes drifting into the fire, the Flame's line, the music settling, then sleep (the screen dims to the night palette).

### B.5 The Return (after days away)
1. Opening: the Sanctuary is softly grey with mist; the Flame sleeps as a small ember.
2. **Tap the ember**, or do any first action: the mist lifts in one breath (a temporary welcome effect, R1), the Flame wakes and leaps, `ignite`.
3. One line, never guilt: *"You're back. Everything we built is still here."*
4. The day continues normally.

---

## Part C — What D4 (the feel slice) will contain
Exactly: B.1 (the first minutes), B.2 steps 1–4 (one normal day with real task objects), B.3 (travel to the Grove and back), the A.1–A.7 language throughout, sound for every event in A.4, and the high-end bar (Part 10 §10). Built on the chosen style frame.
