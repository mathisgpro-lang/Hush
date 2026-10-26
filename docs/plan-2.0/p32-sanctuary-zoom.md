# Wider worlds — installed 2026-10-16

Latest scope: all seven worlds (decisions 176–179), superseding the retired Sanctuary-only zoom job.

## Delivered

- Extended full-color paintings for Sanctuary, Grove, Stillwater, Highlands, Forge, Library and Wilds.
- Each finished wide painting is sampled as one continuous surface; the original/extended crossfade was removed because repainted architecture did not join cleanly.
- Explicit color texture loading corrects the washed-out sides. Original source assets remain available.
- Wider camera: Sanctuary 36° versus its former 30°; other realms 40° versus 30°. Sanctuary’s slightly tighter final camera reserves vertical swipe room.
- Flame framing reduced 30%, centered in free space above quests. Current quest, XP, icons and native artwork changes preserved.
- Measured circle centers in each surround JSON; six sprite foot anchors measured from opaque foot pixels. Growth and form switching use the contact point. Spark intentionally hovers above its centered ground anchor.
- Old cutout floaters are suppressed on the new paintings to avoid fragments of the previous artwork appearing over the new composition. Live Flame, local light, animated surface effects and particles remain.

## Verification

- Simulator Release and signed iPhone Release builds succeeded; source diff whitespace checks passed.
- Beyond captured at rest and four forced swipe corners in all seven worlds. Final Sanctuary recaptured after the 36° adjustment. Captures: `docs/design/flame-depth/verification/wider-worlds/`.
- Final Sanctuary limits approximately x 0.1004, y 0.0378; the six realms retain horizontal and vertical movement. Inspected captures show painted scenery at screen edges.
- Seven circle coordinates pass mapping round-trip validation. Six form anchors match the independent opaque-foot measurement within 0.0024 texture pixels of rounding. This validates shared placement data; it is not a claim of 42 separate visual captures.
- The previous automated batch before camera activation/acknowledgement was unreliable. Current verification explicitly activates each world and waits for each screenshot acknowledgement.
- Final phone installation succeeded: sequence 14088, bundle `com.mathis.lifegamified.spikelab`; normal launch succeeded. Progress was not reset or seeded.
- Phone performance: the immediately preceding identical renderer/alignment build held 60.1 fps, 17 ms worst sampled frame; final camera-only revision is rechecked before handoff. Logs copied into verification folder.

No commit or remote Git push was performed. Phone installation is the requested delivery. Mathis’s visual feedback remains the acceptance check.

## Fire-only motion — decision 180

Mathis requested a planted character whose fire burns, without body hopping or swaying.

- Painted forms now use an identity body transform: no gravity hops, hover/bob, squash/stretch, roll, wandering or tilt response. Idle/reaction movement requests cannot displace their feet.
- Spark is also planted at its calibrated contact (supersedes the hover note above).
- Fire motion comes from two upward-travelling noise fields, curling the crown/fringe geometry and flowing the sampled fire texture. Feet and central face/torso are excluded; brightness flicker is localized to fire.
- Automatic camera drift is disabled for the wide paintings; swipe navigation remains.
- Flame navigation icon no longer scales, rotates or hops; its light can still flicker.
- Simulator evidence: five frames across eight seconds, Beyond in Sanctuary. Foot patch translation was (0,0) in all four comparisons to the first frame; the fire region changed in every comparison (mean pixel change 2.31–2.97/255). Frames: `docs/design/flame-depth/verification/fire-only/`.
- Both platform builds passed for the rig/shader changes. Final icon-only adjustment is built for the phone before delivery.

### Signing interruption — 2026-10-16

Fire-only body/tip animation installed and launched successfully (installation sequence 14096). A final one-line removal of the small navigation Flame icon’s rotation is saved but not installed: the free provisioning profile expired at 10:10:21 Europe/Paris, and Xcode now reports no Accounts/no provisioning profile. Refresh build retry failed for the same reason. Mathis explicitly declines computer control; do not invoke computer-use tools. Asked him to sign into Xcode Accounts manually. Once ready, rebuild signed Release, install via `work/install-wide-phone.py` with `HUSH_PHONE_BUILD_LOG=/tmp/hush-fire-phone.log`, measure frame rate and relaunch normally. Never reset or seed phone progress. Earlier main-screen measurements were 60.1 fps; the final fire-only phone performance check remains pending because of signing. Simulator image comparisons establish fixed feet with moving fire.

### Signing restored and fire refined — 2026-10-17

Mathis signed into Xcode manually. Both Release builds succeeded and the final motion update installed/opened on the iPhone (sequence 14128). This includes the icon rotation removal. Shared upward noise now drives both outline curl and inner fire flow, with a face-height-aware mask for each form. Foot, face and central-body exclusion remain; no hopping or camera idle drift. No computer-control tools were used for this delivery. Previous signing block is resolved.


### Reference-inspired fire pass — 2026-10-17 (decision 181)

Reviewed Mathis’s `IMG_8546.MOV`: stylized fire tongues curl, narrow, split and shed tips. Increased the coherent upward outline/texture flow, added thinning at the crown and occasional detached wisps using each form’s own palette. Extended transparent mesh space above/alongside the artwork permits these tips without resizing the character or moving its foot contact. This is a first adaptation of the reference to the existing painted character, not an exact recreation of the reference animation.

Both Release builds passed. Inspected Beyond in Sanctuary across five simulator frames: feet remained at (0,0) relative translation in all four comparisons; upper-fire mean pixel changes were 3.89, 4.95, 5.14 and 4.05 out of 255. Actual captures are in `docs/design/flame-depth/verification/fire-only/`. These checks cover the shared animation and one rendered form/world, not every possible combination. Signed build installed and opened on Mathis’s iPhone, installation sequence **14136**, preserving journey data. Phone performance measurement follows below.

Phone performance: two startup samples at 32.8/39.7 fps during loading, followed by five consecutive samples at **60.1 fps**, **17 ms** worst frame and zero quest-card redraws. The 20-second console timeout ended the measurement as intended; the app was then relaunched normally without diagnostic or form-override flags. Logs saved alongside simulator evidence.
