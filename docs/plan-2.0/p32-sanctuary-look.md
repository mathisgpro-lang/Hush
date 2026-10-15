# Sanctuary look-around — delivered 2026-10-15

Status: implemented, verified and installed/opened on Mathis’s iPhone. Awaiting his feel check. This report completes the queued `scripts/p32-sanctuary-look.sh` job; do not rerun it.

## Changes

- Extended the Sanctuary scenery around the original painting. Matched the generated image to the original before joining them; original coordinates, Flame scale, circle, local light and resting composition remain intact. Art/registration details: `../design/flame-depth/sanctuary-surround.md`.
- Expanded the depth mesh and used the existing `EdgeSafety.lookAround` range, rubber band and camera spring. Vertical limits reserve room for home framing. Framing feedback now excludes the player's pan, so it no longer cancels vertical swipes.
- No changes to HomeView, quest folding/scrolling, gesture ownership or other realm scenes.
- One performance correction in shared `LiveIcon`: alpha-composite the small glints instead of screen-blending them over the moving world. Their idle/tap animation remains active. The diagnostic evidence justified this additional change to meet the 60 fps requirement.

## Verification

- Release simulator and signed iPhone builds succeeded; source diff whitespace checks passed.
- Inspected final simulator captures after allowing each launch to finish: [left](../design/flame-depth/verification/sanctuary-look/left.png), [right](../design/flame-depth/verification/sanctuary-look/right.png), [up](../design/flame-depth/verification/sanctuary-look/up.png), [down](../design/flame-depth/verification/sanctuary-look/down.png), [rest](../design/flame-depth/verification/sanctuary-look/rest.png). The four held extremes expose no black stripe or canvas border. Horizontal travel is substantial; vertical travel works; resting Flame/quests retain their composition. These checks cover the tested iPhone simulator aspect ratio, not every possible display.
- Actual iPhone 15 measurement: original full screen about 30 fps; hiding navigation/quest content or freezing icons restored 60 fps. With the glint fix and **all interface/animations enabled**, the final right-limit run sustained **60.1 screen fps and 60.1 3D updates/s**, with **17 ms worst steady frame**. Startup is excluded. Logs: `../reviews/p32-sanctuary-performance.log`. This is a short device measurement, not a long thermal/endurance guarantee.
- Final device installation confirmed by devicectl: bundle `com.mathis.lifegamified.spikelab`, database sequence **13896**, application container `1064F538-432E-43D9-A44B-E1076B89A5F5`.
- Final normal launch confirmed with `-skipintro -nogift`. No held camera, diagnostic UI hiding, form override or journey reset left on the phone. Existing progress preserved.

No commit made. Broader all-world/all-evolution validation remains separate; this delivery does not claim that unfinished sweep passed.
