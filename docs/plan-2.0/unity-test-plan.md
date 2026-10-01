# Unity Test Plan (2–3 days)

*Does Unity make the experience clearly better than our native Swift route, for the cohesive, refined, game-scale app Mathis has in mind?*

**Status:** approved by Mathis (decision 110) · **Written:** 2026-10-01 · **Throwaway:** `prototypes/unity-test/`, never merged as-is

## What we build (the same scene as the Swift version, so the comparison is fair)
1. **The Sanctuary home** (Codex's Age-of-Stone painting split into depth layers with Apple's depth model): water, falls and braziers moving; mist; the Hush.
2. **Your Flame as a real light source** (URP 2D lights): it lights the stones, the circle and the nearby pillars, flickers with its fire, and the scene's sunset light rims it. Layered Flame parts (Codex's pieces) animated (breathing, blinking, the tongues, physics-like bounce).
3. **The hold-to-give-light moment** on one task object: rising haptic (an iOS native haptics plugin or Unity's), sound, ignition, the light flying to the Flame.
4. **The cinematic rise** (Cinemachine): from home, the camera rises through clouds, and the Sanctuary becomes its island on the world map.
5. Runs **on Mathis's iPhone 15**.

## How it's built (AI-driven)
- Claude writes all C# scripts, builds scenes from **editor scripts** (no clicking needed), and builds from the command line (`-batchmode`) to an Xcode project → signed with Mathis's free team → installed on the phone.
- Mathis can open the project in the editor at any time to look around.

## Pass criteria (judged side by side with the Swift version, on the phone)
| Question | Unity must show… |
|---|---|
| Cohesion | The Flame clearly *belongs* in the world: lighting, rim light, shared atmosphere |
| Movement | The rise to the map feels cinematic and continuous |
| Feel | The hold moment is at least as good (haptics, sound, timing) |
| Performance | 60 fps on the iPhone 15; memory and app size acceptable |
| Our process | Claude can build and change it reliably from code (scenes, builds, installs) without manual editor work blocking progress |
| Mathis's verdict | "This is clearly closer to what I have in mind" |

## Setup (Mathis's part, about 15 minutes plus download time)
1. Claude downloads **Unity Hub** (free, about 166 MB, from unity.com), with Mathis's go-ahead.
2. Mathis opens Unity Hub and **signs in or creates a free Unity account** (the Personal license; Claude can't create accounts).
3. Claude installs **Unity 6 LTS + iOS Build Support** through the Hub (about 10–15 GB), with Mathis's go-ahead.

## After the test
- **If Unity wins:** a decision log entry; the feel slice (D4) and P3 are built in Unity; the growth engine is ported to C# and checked number for number against the Python reference; Part 5 (technical architecture) is rewritten.
- **If not:** we continue in Swift, with what we learned.
