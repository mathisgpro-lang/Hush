# 12 — Visual, Sound and Verbal Identity (MVP slice)

**Status:** 📝 Drafted with default decisions (63), for Mathis's batch review · **Last updated:** 2026-10-01
**Based on:** the original brief ("Overall style"), decisions 35, 40, 61, 62, 64 and chapters 03, 06, 28 · **Design production:** Codex (decision 62)

---

> **Revision note (2026-10-01):** the visual identity is **pixel art** (decision 77): crisp pixels, a limited warm palette, 2D. Pillar colors and Era palettes below still apply, quantized to the pixel palette. Typography stays New York + SF Pro for readability over the pixel world, to be revisited with a pixel display font later.


# Part A — For Mathis

## A.1 The feeling in one line *[by default]*

**An ancient sanctuary, lit by your own fire, where the future is quietly waiting.** It's Dune's scale and silence, the green life of a hidden sanctuary, and Iron Man's precision hidden in the details.

## A.2 The names *[by default, except the app's name]*

| Concept | Name in the app | Why |
|---|---|---|
| Your growth number | **Ascent**, shown as ×1.37 | You're rising, not scoring points |
| The Transformations | **Eras**: the Stone Era, the Metal Era, the Crystal Era, the Era of Light | They're chapters of a life, and they match the Sanctuary's ages |
| The collectibles (fire styles, vessel forms, titles) | **Relics** | Earned, rare, timeless: things found in a sanctuary |
| The world | **The Sanctuary** | — |
| The weekly story | **The Chronicle** | — |
| Paths, the Spark, the Ritual, the Companion, Depth, Vitality | unchanged | — |

**The app's name: your call.** "Life Gamified" is the working title, but it describes the category rather than the feeling. The final name needs a trademark check and has to feel like *yours*. Candidates to react to:

| Candidate | The idea |
|---|---|
| **Ignis** | Latin for fire. Ancient, short, memorable. |
| **Hearth** | The fire at the center of a home. Warm, human. |
| **Sanctum** | Your inner sanctuary. Mythic, calm. |
| **Vessel** | What you're shaping. Unusual, strong. |
| **Emberlight** | The fire that never goes out. Soft, poetic. |

Until you decide, the beta uses the working title.

## A.3 Typography *[by default]*

- **Ceremonial and titles:** Apple's **New York** serif. It's classical and quietly monumental, free and built into every iPhone.
- **Everything else:** **SF Pro**, Apple's system font, for clarity and native feel.
- **Rules:** sentence case always, generous spacing, few words on screen.

## A.4 Color *[by default]*

**Pillar colors** (the fire and the motifs, chapter 03):

| Pillar | Color | Hex |
|---|---|---|
| Body | Ember orange | `#E8762C` |
| Mind | Clear blue | `#4A9BE0` |
| Heart | Rose-gold | `#D98C7A` |
| Spirit | White-silver | `#E6E9F0` |
| Craft | Bronze-gold | `#B8893A` |
| World | Living green | `#5FA85A` |

**Era palettes** (the whole app changes with each Era, decision 35):

| Era | Base | Surfaces | Accent light |
|---|---|---|---|
| Stone | Sandstone `#C9A77C` | Dusk violet `#3B2F4A` | Warm dawn `#F2B36B` |
| Metal | Forged bronze `#8C6A43` | Deep steel `#252A33` | Blue inlay `#6FA8DC` |
| Crystal *(glimpse)* | Pale quartz `#DDE6EE` | Deep water `#10202E` | Clear light `#BFE3FF` |
| Light *(glimpse)* | Starlight `#FFF6E5` | Night `#0B0B12` | Gold halo `#FFD27A` |

These are starting values. Codex's mockups will refine them, and they live only in the theme engine (nothing hard-codes a color).

## A.5 Sound *[by default]*

- **Organic first, technology underneath.** Real materials (stone, wood, water, breath, metal) with a subtle resonant shimmer, the "future in the details."
- **The Stone Era sounds raw and earthy; the Metal Era brighter and ringing.** Each Era re-tunes the whole app.
- **Silence is part of the design.** Most screens are quiet. Sound is saved for the moments that matter (chapter 06).

## A.6 The voice: how the app speaks *[by default]*

- **Sparse and calm.** If a sentence can be shorter, it is.
- **No exclamation marks.** Confidence doesn't shout.
- **Never these words:** *streak, fail, missed, lost, behind, lazy, should have, don't break, last chance, hurry.*
- **Say it like a companion would:** *"Your day is ready."* not *"Don't forget to complete your tasks!"*
- **Language (MVP):** English first. *Tell me if the beta should also be in French or another language.*

## A.7 The app icon *[by default direction; Codex produces options]*

The Flame in its stone vessel, simplified to a strong silhouette on a deep dusk background. It's recognizable at the smallest size, with no text. Over time, the icon could follow your Era (Apple allows alternate icons): **your home screen icon changes when you reach the Metal Era**, and people who see it will know.

---

# Part B — For the builders

## B.1 Theme bundle structure (chapter 16 §B.2, `Experience.Theme`)

```
ThemeBundle (per Era) {
  palette: { base, surface, surfaceElevated, accent, text, textSecondary, pillar[6] },
  typography: { ceremonial: NewYork(weights), ui: SFPro(weights), scale },
  materials: { card: glass|stone|metal params, blur, grain },
  motion: { durations, curves },
  sound: { assets per SensoryEvent × pillar },
  haptics: { AHAP per SensoryEvent × pillar },
  icon: alternateIconName
}
```
- The live accent = `palette.accent` blended with the fire color × vitality (chapter 03 §B.3).
- Contrast: all text/background token pairs must meet WCAG AA at minimum Vitality (V = 0.15), and this is checked by a test.

## B.2 Copy system
- All user-facing strings live in a localizable catalog. The banned-words list (A.6) is enforced by a unit test over the string catalog and by the AI output validators (chapter 07).
- The Era names, relic names and "Ascent" are keys, so they can be renamed without code changes.

## B.3 Alternate icons
- One alternate icon per Era, switched via `setAlternateIconName` when the user witnesses the Era's ceremony. **The user can opt out** in settings.

## B.4 Design deliverables (Codex, decision 62)
- MVP: home (Today, evening), the birth storyboard, the tracking-moment storyboard, the Path card and Path detail, the Companion conversation, the Chronicle page, settings (privacy: "What the Companion knows about me," delete everything), and app icon options (Stone, Metal).
- Briefs are stored in `docs/design/briefs/` and registered in `scripts/resume-codex.sh`.
