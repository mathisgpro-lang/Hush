# 20 — Security, Privacy and Compliance

**Status:** First pass (Phase B baseline): Part A ✅ approved 2026-09-30 (revised after Codex review, decisions 48–50) · Part B 🔎 revision 3, in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 29, 30, 34, 37, 43, 48–50 · **Depends on:** chapters 16, 17

---

# Part A — For Mathis

## A.1 What the company holds, and what it doesn't

| Data | Who holds it | Can the company see it? |
|---|---|---|
| The record, plans, Companion memory | The user (phone + private iCloud) | **No** |
| Health data | Apple Health | **No** |
| Companion conversations (MVP) | Processed by Apple only (on the phone or in Apple's private cloud); not stored anywhere | **No** |
| Ritual participation | The Relay | It sees a **random anonymous device key** (to prove the request comes from the real app) and which Rituals that key joined. It never knows who you are. The link between key and Ritual is deleted about 10 days after each Ritual closes; only the total count is kept. |
| Payments (later) | Apple | **No** |
| Crash reports | Apple, and only if the user opted into sharing with developers | Anonymous technical reports |

**Honesty rule (decision 48):** the privacy promise states the anonymous device key plainly. We never claim "we know nothing" when we know something, however small.

**After the MVP:** if a frontier AI (like Claude) is added, some requests will *pass through* the Relay on their way to it. They won't be stored, but we won't pretend they're invisible either. This will come with a clear permission screen and wording like "passed through, never stored" (decision 49).

## A.2 The App Store privacy label

The label appears at public release (V1), not during the private beta.
- **Honestly: to be determined.** Because the Relay briefly remembers which anonymous device joined which Ritual (to avoid counting twice), Apple may consider that data *linked to the device*. The label could therefore be **"Data Linked to You: Device ID,"** even though nobody can know who you are.
- **Chapter 11** will look at ways to count Rituals without keeping that link. If one works, the label improves. We won't bend any definition to get a better label (decision 48).

## A.3 What's protected, and how

- **Only the real app can use the Relay.** Apple's App Attest proves each request comes from our genuine app on a real iPhone.
- **No spy code.** No advertising, tracking or analytics kits inside the app, ever, in the MVP.
- **Encrypted everywhere.** On the phone, in iCloud (fully end-to-end for users with Apple's Advanced Data Protection), and in transit.
- **Safety in the Companion.** Hard limits are enforced by code, not just by instructions to the AI. Sensitive areas refer the user to a professional.
- **Deletion really deletes.** An old phone coming back online can never bring deleted data back.

## A.4 What you still need to do (not now; before the private beta or V1)

1. **A privacy policy**, short and honest. It covers what the Relay sees, and how Apple processes Companion requests.
2. **Ask Apple App Review in writing** about the health-data rule, **before the health features are built** (decision 50). I'll draft the question.
3. **Join Apple's Small Business Program** (free, and it cuts Apple's commission to 15%), then **apply for Private Cloud Compute access**.
4. **Health disclaimers**, for example "not medical advice." Wording goes in chapter 15.
5. **Before V1:** one review by a human security and privacy professional (decision 20).

---

# Part B — For the builders

## B.1 Threat model (first pass)

| Threat | Mitigation |
|---|---|
| Stolen or lost phone | iOS data protection (`completeUntilFirstUserAuthentication` for the databases, which background sync requires); the Keychain for secrets |
| Relay abuse (fake Ritual counts) | App Attest registration plus an assertion on every request, with a counter that strictly increases; per-key rate limits; de-duplication per key and window (16 §B.7) |
| Relay compromise | Holds only pseudonymous key registrations, short-lived de-dup hashes and counts; no content, no IP addresses; secrets only in the platform's secret store; the catalog signing key is kept **offline**, never on the Relay |
| Data leaking to AI | MVP: Apple tiers only (on-device, and PCC, which stores no prompts). Tier 3 is post-MVP with a consent gate (16 §B.4) |
| Supply chain | Minimal dependencies (`docs/dependencies.md`: a justification for each, pinned versions, review on every update) |
| Prompt injection | Model outputs never directly trigger record writes or destructive actions; all structured outputs go through deterministic validators; source IDs must resolve to supplied sources (16 §B.4) |
| Import of hostile files | Bounded, validated import into a temporary database (17 §B.9) |
| Deleted data resurrecting | Deletion protocol with dataset generations (16 §B.9) |
| Account mixing | Namespacing by iCloud account; never upload across accounts (16 §B.8) |
| Self-reported cheating for public status | No public status in the MVP. Chapter 09 designs verification |

## B.2 Data classification

The P / H1 / H2 classes are defined in chapter 16 §B.5. Two more:
- **Ps (Pseudonymous, Relay):** key registrations `{keyIdHash, publicKey, counter, registeredAt, lastSeenAt}` and de-dup hashes linking a device key to Ritual participation. They're persistent per device, so they are **not** anonymous.
- **A (Anonymous, Relay):** aggregate counts only.
- **S (Secrets):** the App Attest key ID, the deletion intent, the install ID. Keychain only. The App Attest private key is held by the Secure Enclave, and the app stores only its identifier.

**Relay retention table:**

| Data | Retention |
|---|---|
| Key registrations | Deleted after 90 days unused |
| De-dup hashes | Deleted at acceptance deadline (window close + 72 h) + 7 days |
| Aggregate counts | Kept (anonymous) |
| Request logs | Status code and latency only; no bodies, IP addresses or key identifiers |

## B.3 Hard rules (enforced in code review, tests and runtime)

1. No third-party analytics, ads, attribution or crash SDKs (Apple's built-in crash reporting only).
2. **Network egress:** all app-controlled networking goes through one `NetworkGate`. It checks each destination against an allowlist (Apple services plus the Relay domain, which also serves the content catalog, 16 §B.10) at runtime, and rejects redirects to other hosts. Adapter tests check that nothing leaks out through other paths. A lint check for URL literals is an *extra* check, not the security boundary.
3. **Logging:**
   - structured diagnostics only, with a fixed set of approved non-personal fields (event codes, counts, durations);
   - never log prompts, payloads, free text, error bodies or identifiers;
   - `os.Logger` `.private` interpolation is *redaction*, not removal, so personal values are simply never passed to loggers;
   - release logging configuration is verified.
4. **No H1 data in the app's own storage.** H2 goes to its designated store per mode (16 §B.5), and backup exclusion is tested after every migration.
5. **Relay:** no body logging, no IP storage, the retention table above, and Worker observability limited and verified.
6. **Consent (post-MVP tier 3):** no personal context goes to a third-party AI without an explicit, informed permission. Changing provider requires fresh consent. Queued requests respect the consent that was in effect when they were queued.

## B.4 Compliance checklist (tracked to V1)

- [ ] Privacy policy published (chapter 15), covering Relay pseudonymous keys, Apple PCC processing, and (later) tier-3 pass-through.
- [ ] App Privacy details in App Store Connect, **determined from the actually retained relationships** (currently: device key ↔ Ritual participation for up to ~10 days after the window, and key registrations for up to 90 days unused). No expected answer is presumed; if in doubt, declare the stricter category. Ref: https://developer.apple.com/app-store/app-privacy-details/
- [ ] Written App Review answer on 5.1.3(ii); `HealthFactSyncMode` set accordingly.
- [ ] Small Business Program enrollment and PCC entitlement; both eligibility conditions monitored.
- [ ] HealthKit usage descriptions written in the app's voice.
- [ ] GDPR/CCPA review. Transmitting personal data for processing (to Apple PCC, or later a tier-3 AI) is itself processing under GDPR, even when nothing is retained. The policy and records of processing reflect that.
- [ ] Human security review before V1.
