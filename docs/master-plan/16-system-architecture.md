# 16 — System Architecture

**Status:** First pass (Phase B foundations): Part A ✅ approved 2026-09-30 · Part B 🔎 in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 20, 23, 28–39 · **Research:** see §B.10 (sources checked 2026-09-30)

This chapter has two layers:
- **Part A, for Mathis:** plain language. Mathis reads and approves this part.
- **Part B, for the builders:** the technical specification. Codex reviews this part independently.

If the two layers ever disagree, Part A's intent wins and Part B gets corrected.

---

# Part A — For Mathis

## A.1 The big picture: four places

The whole system lives in four places, and only one of them belongs to the company.

```
┌──────────────────────────── The user's iPhone ────────────────────────────┐
│                                                                           │
│   THE APP  (the body: screens, the Flame, haptics, sound)                 │
│   THE BRAIN (growth rules: how the record becomes Depth, Vitality,        │
│              the Flame; identical on every future platform)               │
│   THE RECORD (the permanent history, stored on the phone)                 │
│   APPLE HEALTH (health data stays here; the app only reads it)            │
│   ON-DEVICE AI (Apple's model: private, free, offline)                    │
│                                                                           │
└──────┬───────────────────────┬─────────────────────────┬──────────────────┘
       │ syncs                 │ heavier AI              │ anonymous only
       ▼                       ▼                         ▼
┌───────────────┐   ┌─────────────────────────┐   ┌─────────────────────────┐
│ THE USER'S    │   │ APPLE PRIVATE CLOUD     │   │ THE RELAY               │
│ PRIVATE iCLOUD│   │ COMPUTE (Apple's bigger │   │ (the only company piece)│
│ Their copy.   │   │ model; free, stores     │   │ • Ritual counters       │
│ We can't see  │   │ nothing) and, when      │   │ • pass-through to a     │
│ it.           │   │ needed, a frontier AI   │   │   frontier AI           │
│               │   │ (e.g. Claude) via relay │   │ • Stores nothing        │
└───────────────┘   └─────────────────────────┘   │   personal. Ever.       │
                                                  └─────────────────────────┘
```

- **Your phone does almost everything.** The tracking moment, the Flame and your record all work with no internet at all.
- **Your private iCloud is the backup and sync.** It's yours, and the company can't read it.
- **Apple's AI does most of the Companion's thinking,** on the phone or in Apple's private cloud. It's free for us and stores nothing.
- **The Relay** is the only piece the company runs. It's small and holds no personal data. It exists for two jobs the phone can't do alone:
  1. counting Ritual participants across millions of people;
  2. passing the hardest Companion requests to a frontier AI without exposing our access key.

## A.2 What the research changed (2026-09-30)

I checked the current facts on every Apple technology we rely on. Three findings matter.

**1. The AI layer got better and cheaper.** Since iOS 27 (released 14 September 2026), Apple offers three levels of AI through a single system:
- the **on-device model**: free, private, offline, now with image understanding;
- **Apple's Private Cloud Compute model**: a much bigger model on Apple's servers. It's **free for apps under 2 million downloads**, needs no account or key, and **stores no prompts**, which independent researchers can verify;
- **frontier models like Claude or Gemini**, plugged into the *same* system.

So the Companion can do most of its heavy thinking privately and **at no cost** during the MVP and early growth. Being "provider-neutral" (decision 34) is now built into Apple's own tools.

**The catch:** Apple's free cloud model has a daily limit per user. It also **stops being available once an app passes 2 million downloads** (you get 6 months to migrate), and there's no paid option. So it's a great launch engine but not the foundation for millions of users. The architecture is built so that switching the heavy work to a frontier AI is a configuration change, not a rebuild.

**2. Ritual counters move to the Relay.** I had planned to keep the anonymous Ritual counters in Apple's shared iCloud database. That database throttles at around 40 requests per second, which can't handle millions of people joining a Ritual the same morning. The counters move to the Relay instead. They're still fully anonymous, so this changes nothing about your distance from personal data.

**3. An Apple rule on health data shapes the record.** Apple's App Store rules say apps *"may not store personal health information in iCloud."* It's unclear whether that applies to a user's *own* private iCloud storage like ours, but we design so it can never be a problem:
- **Health data stays in Apple Health.** Apple Health already syncs securely across the user's devices; that's Apple's job.
- **Our record stores only the *fact* and a *reference*.** For example: *"Action: morning run, verified by Apple Health, workout #ABC."* It never stores the distance, heart rate or sleep hours themselves. When the app needs the details, it reads them fresh from Apple Health.
- **Health-type things you log yourself** (for example "drank 2L of water" or "meditated 10 minutes") are saved *into Apple Health*, where possible, and our record references them.
- **Everything else** (read a chapter, called a friend, finished a Spark) is stored in the record normally.

This also *strengthens* your "stay away from data" principle: the most sensitive data doesn't even pass through our app's storage. **Action for later:** before the private beta, we ask Apple App Review for a written answer on this rule, so it's settled in writing.

## A.3 What happens when things go wrong

| Situation | What the user experiences |
|---|---|
| No internet | Everything works. The tracking moment is instant. Sync catches up later. Heavy Companion requests wait politely, with the user's draft kept. |
| iCloud off or full | The app works, and says kindly and clearly that the Flame lives only on this phone, with a one-tap backup (decision 32). |
| Apple's free AI limit reached for the day | The Companion switches to the on-device model for simple things, or queues heavier requests for later. It never silently breaks. |
| The Relay is down | Rituals show the last known count; your own participation is saved and sent later. Nothing else is affected. |
| New phone | Sign into iCloud and the record, Flame and Paths come back. Health details come back through Apple Health. |

## A.4 What's still open

- **Minimum iPhone:** the MVP needs iOS 27 (current). Which older iPhones V1 supports gets decided in chapter 24.
- **Where the Relay runs:** proposed Cloudflare (a large, reliable, low-cost provider that runs small programs without anyone managing servers). Confirmed when the Relay is built.
- **Which frontier AI:** chosen by testing quality and cost (decision 34).
- **Delivering new game content without app updates** (decision 40). Real game depth needs a steady flow of new Sparks, Rituals, milestones, story and world content. The proposed way is a public, read-only content catalog served by the Relay/CDN. It holds no user data, and it's designed with chapter 28.

---

# Part B — For the builders

## B.1 Platform baseline
- **Minimum OS (MVP):** iOS 27.0. Revisit for V1 (chapter 24).
- **Language/UI:** Swift 6 with strict concurrency checking on; SwiftUI for all UI; Metal for the Flame renderer; Core Haptics; AVFoundation / AVAudioEngine for sound.
- **Tooling:** Xcode 27. Swift Package Manager only (no CocoaPods/Carthage).
- **Devices:** iPhone only for MVP. No iPad/Mac layouts. Watch and widgets are allowed as later targets, and module boundaries must not block them.

## B.2 Module map (local Swift packages in one repo)

Dependencies point **downward only**. Anything marked "pure" has no Apple UI frameworks and no I/O, so it's deterministic and fully unit-testable.

| Module | Responsibility | May depend on |
|---|---|---|
| `GrowthRules` (pure) | **The brain.** Turns a sequence of record entries into derived state: pillar Depth, Vitality, growth number, milestone eligibility, Flame parameters. Versioned rule sets. | Nothing |
| `RecordKit` | Local append-only store (SQLite via GRDB), entry types, projections cache, export/import, delete-all. | `GrowthRules` (types only) |
| `SyncKit` | CKSyncEngine against the user's **private** database, custom zone. Pushes and pulls record entries. Idempotent by entry ID. | `RecordKit` |
| `EvidenceKit` | HealthKit read/write, turning HealthKit samples into evidence references. Later: partner integrations. | `RecordKit` |
| `CompanionKit` | AI routing (on-device → Apple PCC → frontier via Relay), prompts, guided-generation schemas, safety checks, source attribution, Companion memory. | `RecordKit`, `GrowthRules` |
| `ThemeKit` | Theme tokens (color, material, typography, motion, sound, haptic patterns) derived from Flame state. The **only** source of look and feel. | `GrowthRules` |
| `FlameKit` | Metal renderer that assembles artist-made assets into the live Flame from Flame parameters. | `ThemeKit`, `GrowthRules` |
| `SensoryKit` | Haptic and sound playback driven by theme tokens and named sensory events (e.g. `actionCompleted`). | `ThemeKit` |
| `RitualKit` | Client for the Relay's anonymous Ritual endpoints, with an offline queue. | — |
| `RelayClient` | App Attest–authenticated transport to the Relay. | — |
| `AppFeatures` | SwiftUI feature screens (Today, Flame, Paths, Companion, Record, Settings). | All of the above |
| `App` | The app target: composition root and dependency injection. | `AppFeatures` |

**Rules:**
1. `GrowthRules` must compile and pass tests with zero Apple-platform imports beyond Foundation. It's the reference for a future Android port.
2. No feature module hard-codes a color, font, duration, sound or haptic. It reads from `ThemeKit` (decision 35). This is enforced with a lint rule and a code-review checklist item.
3. No module except `EvidenceKit` imports HealthKit.
4. No module except `CompanionKit` talks to an AI model.

## B.3 The brain: growth rules as specification
- Each rule set is documented in plain language in chapter 04 (growth model) **and** encoded in `GrowthRules`.
- **Golden test vectors:** `GrowthRules/Tests/Vectors/*.json` hold hand-checked pairs of `{record entries → expected derived state}`. They're the platform-neutral contract; any future Android implementation must pass the same files.
- Rule sets carry a `rulesVersion`. Derived state is always recomputable from the record under any version.
- **Awards are facts, not calculations.** Once a milestone/Transformation or reward has been *granted and witnessed*, it's written to the record as an entry and never revoked by later recalculation (principle P6). Recalculation may grant new things; it never takes granted things away.

## B.4 AI routing (`CompanionKit`)

All model access goes through Apple's Foundation Models `LanguageModel` abstraction, so the model behind each task is configuration, not code.

| Tier | Model | Used for | Data leaves device? |
|---|---|---|---|
| 1 | On-device `SystemLanguageModel` (≈8K context in iOS 27) | Spark phrasing, encouragement, classifying a logged Action, short summaries, understanding free text | No |
| 2 | Apple Private Cloud Compute model (32K context, reasoning levels) | Plan building within expert frameworks, weekly reflection, deeper conversation | To Apple PCC; no prompts stored |
| 3 | Frontier model (e.g. Claude) via the Relay | Tasks tiers 1–2 fail at in evals, and all tier-2 work once PCC eligibility ends | Only the minimal context for that request; provider with zero data retention; the Relay never logs content |

- **Routing is a per-task policy table**, stored as configuration and chosen by evaluation results, not intuition.
- **Fallback:** if tier 2 is unavailable (no entitlement, daily limit, outage), degrade to tier 1 where acceptable, otherwise queue the request with the user's draft preserved.
- **PCC requirements:** App Store Small Business Program enrollment, the `com.apple.developer.private-cloud-compute` entitlement, and fewer than 2M first-time downloads across the developer's apps. Beyond that there's a 6-month migration window to tier 3. Also track the per-user daily allowance.
- **Safety and sources:** expert frameworks and hard safety limits are enforced by **deterministic code in `CompanionKit`/`GrowthRules`**, never only by prompt. For example, a generated running plan is validated against max weekly volume increases before it's shown. Every generated plan carries `sources[]` (decision 18).
- **Guided generation** (`@Generable` types) for every structured output. No free-text parsing of plans.

## B.5 Health data rule (App Review 5.1.3(ii))
- The record **never stores health measurements** (distances, heart rates, sleep durations, weights, nutrition quantities).
- Evidence entries store `{source: "healthkit", sampleType, sampleUUID, verifiedAt}`. Details are read live from HealthKit when displayed or computed.
- Health-type self-reported Actions are written to HealthKit (where a matching type exists), then referenced.
- Companion memory that syncs must not contain health measurements. Health-derived observations are kept in a **device-local, non-synced** store, or recomputed from HealthKit.
- `GrowthRules` receives health-derived inputs as evaluated facts at computation time (e.g. "Action met its target: yes"), not raw series.
- **Open, owner Mathis:** request written clarification from App Review before external TestFlight.

## B.6 The Relay
- **Runtime (proposed):** Cloudflare Workers (TypeScript), with Durable Objects for Ritual counters. Chosen because it's managed, has no servers to run, is global, cheap at low volume, and AI agents know it well. Final confirmation happens when the Relay is built.
- **Endpoints (first pass):**
  - `POST /ritual/{ritualId}/join`: anonymous increment.
  - `GET /ritual/{ritualId}/count`: the current count.
  - `POST /ai/{task}`: a stateless pass-through to the tier-3 provider.
- **Authentication:** Apple App Attest on every request (assertion verified server-side). No user accounts.
- **Storage:** Ritual counters only (and the anonymous de-duplication data required by §B.7). **No request bodies, no IP addresses, and no identifiers are logged or stored.** Platform request logs are disabled or reduced to status codes.
- **Secrets:** provider API keys live only in Cloudflare secrets, never in the app binary.
- **Abuse limits:** per-attested-key rate limits; per-day AI budget caps.

## B.7 Ritual counting (first pass)
- A join sends `{ritualId, dedupToken}`. `dedupToken = HMAC(ritualId, per-install random secret kept in the Keychain)`. The Relay can de-duplicate joins per Ritual, but it can't link one person's joins across different Rituals.
- Tokens are deleted when the Ritual window closes; only the aggregate count is kept.
- **Open → chapter 11:** verified vs. self-reported Ritual participation, and any public display.

## B.8 Offline and sync behavior
- Every write goes to the local store first. The UI reacts to the local write. Sync is asynchronous.
- The tracking moment's code path must contain **no network calls**, and a test enforces it.
- CKSyncEngine is initialized at launch, with a custom zone in the private database. Entries are immutable, so the only possible "conflict" is a duplicate ID, which is resolved as a no-op.

## B.9 Non-goals for the foundations
- No custom backend database. No user accounts. No analytics SDKs. No third-party UI frameworks. No cross-platform frameworks.

## B.10 Research sources (checked 2026-09-30)
- Apple WWDC26, "What's new in the Foundation Models framework": https://developer.apple.com/videos/play/wwdc2026/241/
- Private Cloud Compute eligibility and limits: https://developer.apple.com/private-cloud-compute/ · https://daringfireball.net/linked/2026/06/13/pcc-severely-limited-third-party-developers · https://creuto.com/foundation-models-framework-ios-27-apps
- iOS 27 release (14 Sept 2026): https://9to5mac.com/2026/09/09/apple-confirms-ios-27-release-date-september-14/
- App Review Guidelines 5.1.3: https://developer.apple.com/app-store/review/guidelines/
- 5.1.3(ii) ambiguity for private CloudKit: https://github.com/jirigrill/eczema-helper/issues/675
- CKSyncEngine and SwiftData sync limitations: https://superwall.com/blog/syncing-data-with-cloudkit-in-your-ios-app-using-cksyncengine-and-swift-and-swiftui · https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/
- CloudKit public database throughput (~40 req/s): https://developer.apple.com/forums/thread/114154
- Xcode 27 agentic coding: https://www.apple.com/newsroom/2026/06/apple-aids-app-development-with-new-intelligence-frameworks-and-advanced-tools/
