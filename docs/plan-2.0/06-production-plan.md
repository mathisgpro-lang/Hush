# Plan 2.0 · Part 6 — Production: Who Makes What

*A universe needs makers. What the AIs can do, where humans are needed, and what it may cost.*

**Status:** draft · **Written:** 2026-10-01 · **Spending is always Mathis's decision** (decision 63 exception)

---

## 1. The honest picture

A world with a polished 3D character, six realms, a cast of Keepers, music and lore is **game-scale work**. The AIs (Claude Code, Codex) can do a remarkable share of it: all the code, the systems, the tests, the planning, the writing, and first-draft concept art. But **some crafts still need skilled humans** to reach the "super refined" quality you want, especially the final 3D character, its animation, and the music.

The plan keeps humans **few, focused and freelance**, brought in at specific moments, never a big team.

---

## 2. Who does what

| Work | Claude Code | Codex | Human (freelance) | Mathis |
|---|---|---|---|---|
| Plans, specs, lore writing, dialogue | ✅ drafts | reviews | (optional: narrative editor) | approves, shapes |
| All app code, systems, tests | ✅ builds | ✅ reviews | — | judges the feel |
| Concept art (characters, realms, UI) | briefs | ✅ generates | refines | **picks** |
| **Final 3D Flame (model, rig, fluffy-fire look)** | integrates | concept | ✅ **3D character artist** | approves |
| **Animation set** (~30 animations, Part 3 §6) | state machine | — | ✅ **3D animator** | approves the feel |
| Keepers and creatures (3D) | integrates | concepts | ✅ 3D artist (same or another) | approves |
| Realm scenes (dioramas) | assembles, lights, optimizes | concepts, textures | ✅ **environment artist** | approves |
| World map illustration | integrates | concept | ✅ illustrator (or Codex if good enough) | approves |
| UI kit and icons | builds | concepts | (optional: UI illustrator) | approves |
| **Music** (themes per realm, ceremonies) | integrates | — | ✅ **composer** | approves |
| **Sound design** (Flame voice, ambiences, UI sounds) | integrates | — | ✅ **sound designer** | approves |
| Health and safety content review (decision 70) | drafts | reviews | ✅ **qualified reviewer** (coach, physician…) | approves |
| Privacy and security review before public release | prepares | reviews | ✅ security professional | approves |

---

## 3. Cost ranges (rough orders of magnitude, to be validated with real quotes)

These are **typical freelance market ranges** as a planning aid, not quotes. Real prices vary a lot by country, experience and scope.

| Item | Rough range (USD) |
|---|---|
| Final Flame character: model + rig + fluffy-fire material | 2,000 – 6,000 |
| Flame animation set (~30 short animations + evolution forms) | 4,000 – 12,000 |
| Lamplighter + 6 Keepers (3D, rigged, a few animations each) | 7,000 – 25,000 |
| Encounter creatures (10–20 simple rigged critters) | 3,000 – 12,000 |
| Realm scene (environment diorama), each | 2,000 – 8,000 |
| World map illustration | 1,000 – 4,000 |
| Music: Sanctuary theme + 6 realm themes + ceremonies | 3,000 – 15,000 |
| Sound design: Flame voice, ambiences, UI | 1,500 – 6,000 |
| Health/safety content review | 500 – 3,000 |
| Security/privacy review | 1,500 – 6,000 |

### By phase (Part 7)
| Phase | What gets made | Rough total |
|---|---|---|
| **Spikes** (S1–S3) | Placeholder assets only | ~0 (free assets, Codex) |
| **Vertical slice** | Final Flame (Spark + Flame stages) + ~12 animations, the Lamplighter, the Sanctuary diorama, the Grove diorama, Nim & Ro, the main theme + Grove theme, core sound design | **~12,000 – 40,000** |
| **MVP** (private beta) | + the Highlands and Stillwater, Brakka and Ilo, more animations, more music, the health review | **+ ~15,000 – 50,000** |
| **V1** (public) | + the remaining realms and Keepers, full animation set, full soundtrack, security review | **+ ~40,000 – 120,000** |

### Ways to spend less (trade-offs, your call)
1. **AI-assisted 3D:** AI generators can produce draft 3D models from Codex concepts, with a human only cleaning up and rigging. That's cheaper and faster, but quality and consistency vary.
2. **2.5D for realms, 3D only for characters:** painted layered scenes (Codex + an illustrator) instead of full 3D dioramas. That's much cheaper, and the characters still feel 3D.
3. **One generalist** (a 3D character artist who also animates) instead of two specialists.
4. **Fewer realms in V1** (the Sanctuary + 3 realms), with the rest added as later "realm releases": a good rhythm for keeping users excited anyway.
5. **Stock music libraries** for early phases, with a composer later for the signature themes.

**Decided for now (decision 87): AI-only until the spikes are done**, then revisit with real quotes. **Longer-term recommendation:** combine 2 + 4: 3D characters, 2.5D painted realms, and V1 with 3–4 realms. That puts the money where people feel it most (your Flame) and keeps the world growing release by release.

---

## 4. How to work with freelancers (the process)

1. **Brief:** Claude writes a precise brief from the Character/World bible plus Codex concepts (style, poly budget, rig spec, animation list, file formats: Blender + USDZ, naming).
2. **Find:** ArtStation, Behance, or specialized marketplaces (stylized 3D, mobile games). Ask for a **paid test** (e.g. the Spark form only) before the full job.
3. **Iterate:** Claude integrates each delivery into the app the same day, so Mathis judges it **in the app, on his phone**, not in a PDF.
4. **Own:** contracts must transfer **full rights** to the app (characters, music, sounds). Originality must be guaranteed (no copied references; our references were inspiration only).
5. **Review:** Codex checks the technical spec compliance (poly counts, rig, naming) before payment milestones.

---

## 5. Apple and accounts (small but necessary)

| Item | Cost | When |
|---|---|---|
| Apple Developer Program | $99/year | **When the app is basically done (decision 88)**, at the start of P5: iCloud sync, cloud AI, TestFlight, App Store |
| Cloudflare (the Relay for Gatherings) | free tier expected | MVP |
| Codex / ChatGPT plan | your current plan (it hit its usage limit once on 2026-09-30) | ongoing; consider a higher plan during art-heavy phases |

---

## 6. Mathis's role (the irreplaceable one)

You're the **director**:
- you choose between concepts;
- you approve every character and realm;
- you judge the *feel* on your phone (decision 39);
- you hold the vision;
- you're user zero, living with it every day;
- you decide every spend.

You never have to write code, model or compose.
