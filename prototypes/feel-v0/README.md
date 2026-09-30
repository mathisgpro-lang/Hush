# Feel prototype v0 (M0): THROWAWAY

**This is a deliberate experiment, not the app.** Per chapter 23 §B.1 (M0), this code is never merged into `app/`. It exists to answer the chapter 06 §B.5 questions on Mathis's iPhone:

1. Does press-and-hold feel deliberate or annoying?
2. Are the pillar voices distinguishable?
3. Is the landing thrum satisfying without being tiring after 5 completions?
4. Is the comeback big enough?

## What's inside
- The Stone Era Sanctuary (Codex concept art) with a live, procedural Flame: fire plus stone vessel.
- Three Actions (Body, Mind, and a Heart Spark). Press and hold ¼ second → strike → the spark flies into the vessel → a thrum → the pillar's vein grows → the fire brightens → Ascent ticks up.
- The debug button "☾ 14 days away" drops Vitality to embers; the next completion triggers the **comeback**.
- The "Tune" sheet: sliders for hold time, flight time and thrum strength, so the feel can be tuned live on the phone.
- Haptics (Core Haptics) and synthesized pillar tones (AVAudioEngine; placeholder sounds).

## Put it on your iPhone (free)
1. Plug the iPhone into the Mac, unlock it, and trust the computer.
2. Open `FeelPrototype.xcodeproj` in Xcode.
3. Select the **FeelPrototype** target → Signing & Capabilities → Team: choose your Apple ID ("Personal Team").
4. Choose your iPhone at the top, then press ▶ Run.
5. On the iPhone, turn on Settings → Privacy & Security → **Developer Mode** if asked, then approve the developer profile under Settings → General → VPN & Device Management.
