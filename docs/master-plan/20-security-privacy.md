# 20 — Security, Privacy and Compliance

**Status:** First pass (Phase B baseline): Part A ✅ approved 2026-09-30 · Part B 🔎 in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 29, 30, 34, 37 · **Depends on:** chapters 16, 17

---

# Part A — For Mathis

## A.1 What the company holds, and what it doesn't

| Data | Who holds it | Can the company see it? |
|---|---|---|
| The record, plans, Companion memory | The user (phone + private iCloud) | **No** |
| Health data | Apple Health | **No** |
| Companion conversations | Processed by Apple, or by a frontier AI via the Relay; not stored anywhere | **No** (passed through, never kept) |
| Ritual counts | The Relay | Only anonymous totals ("41,209 joined") |
| Payments (later) | Apple | **No** |
| Crash reports | Apple, and only if the user opted into sharing with developers | Anonymous technical reports |

## A.2 The App Store privacy label

Apple's definition says data processed only to serve a request, and not kept, doesn't count as "collected." With the design above, the **MVP aims for the label "Data Not Collected"**, the strongest possible. From V1, if users opt into anonymous statistics (decision 37), the label becomes **"Data Not Linked to You."** The exact label gets confirmed at App Store submission.

## A.3 What's protected, and how

- **Only the real app can use the Relay.** Apple's App Attest proves each request comes from our genuine app on a real iPhone.
- **No spy code.** No advertising, tracking or analytics kits inside the app, ever, in the MVP.
- **Encrypted everywhere.** On the phone, in iCloud (fully end-to-end for users with Apple's Advanced Data Protection), and in transit.
- **Safety in the Companion.** Hard limits are enforced by code, not just by instructions to the AI. Sensitive areas refer the user to a professional.

## A.4 What you still need to do (not now; before the private beta or V1)

1. **A privacy policy**, short and honest. It's easy to write when you hold nothing.
2. **Ask Apple App Review in writing** about the health-data-in-iCloud rule (chapter 16, §A.2).
3. **Apply for Apple's Private Cloud Compute access**, which requires joining the App Store Small Business Program (free, and it also cuts Apple's commission to 15%).
4. **Health disclaimers**, for example "not medical advice." Wording goes in chapter 15.
5. **Before V1:** one review by a human security and privacy professional (decision 20).

---

# Part B — For the builders

## B.1 Threat model (first pass)

| Threat | Mitigation |
|---|---|
| Stolen or lost phone | iOS data protection (the local DB uses `completeUntilFirstUserAuthentication`, which background sync requires), a device passcode, and the Keychain for secrets |
| Someone abusing the Relay (AI cost, fake Ritual counts) | App Attest assertion on every request; per-key rate limits; daily AI budget caps; de-duplication tokens (16 §B.7) |
| Relay compromise | The Relay holds no personal data, keeps no content logs, and stores secrets only in the platform's secret store; provider keys can be rotated |
| Leaks from the AI provider | Minimal context per request; zero-retention agreements with the provider; PCC before third parties |
| Supply chain (dependencies) | Minimal dependencies. Each one needs a written justification in `docs/dependencies.md`, pinned versions, and review on update |
| Prompt injection via user text or imported content | Model outputs never directly trigger destructive or record-writing actions without deterministic validation; plans are validated by safety code (16 §B.4) |
| Self-reported cheating for public status | Out of scope for the MVP (no public status). Chapter 09 designs verification |

## B.2 Data classification

| Class | Examples | Rules |
|---|---|---|
| **H — Health** | HealthKit samples, derived health observations | Never stored by the app outside HealthKit or a device-local store. Never synced to iCloud. Never sent to tier-3 AI without explicit per-feature consent. |
| **P — Personal** | Record entries, plans, memory, notes | Device + private CloudKit (encrypted fields). Sent to AI only as the minimal context a task needs. |
| **A — Anonymous** | Ritual joins, counts | The Relay only, per 16 §B.7. |
| **S — Secrets** | App Attest keys, install secret, relay tokens | Keychain only. |

## B.3 Hard rules (enforced in code review and CI)
1. No analytics, ads, attribution or crash SDKs from third parties (Apple's built-in crash reporting only).
2. Network allowlist: Apple services and the Relay domain only. Anything else fails the build (a static check on URL literals plus a review item).
3. No logging of Class H or P data. Logs are stripped in release builds (`os.Logger` with `.private` interpolation by default).
4. No health measurements in record payloads (a test validates payload schemas).
5. The Relay has no body logging, stores no IP addresses, and has a documented data-retention table (currently: Ritual counters until the window closes plus 30 days, and aggregate counts kept).

## B.4 Compliance checklist (tracked to V1)
- [ ] Privacy policy published (chapter 15).
- [ ] App Privacy details completed in App Store Connect.
- [ ] Written App Review answer on 5.1.3(ii).
- [ ] Small Business Program enrollment and PCC entitlement.
- [ ] HealthKit usage descriptions (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`) written in the app's voice.
- [ ] GDPR/CCPA review. With no personal data held, obligations are minimal, but the AI processing flows (PCC, tier 3) must be described in the policy.
- [ ] Human security review before V1.
