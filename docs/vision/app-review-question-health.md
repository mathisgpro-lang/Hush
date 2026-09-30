# Draft: question to Apple App Review on guideline 5.1.3(ii)

**Status:** draft, ready to send once Mathis is enrolled in the Apple Developer Program (decision 50).
**How to send:** App Store Connect → Contact Us → App Review → "Guideline question" (or developer.apple.com/contact/app-store → App Review).

---

**Subject:** Clarification on guideline 5.1.3(ii): storing activity facts in the user's own private CloudKit database

Hello App Review team,

We're building an iOS self-improvement app that uses HealthKit **only to read** workouts and sleep data, so we can confirm that a user completed an activity they planned (for example a morning run). We want to follow guideline 5.1.3(ii) ("may not store personal health information in iCloud") exactly, and we would appreciate clarification on the following design:

1. **HealthKit measurements** (distance, heart rate, sleep duration and so on) are never copied out of HealthKit. The app reads them on-device when needed.
2. The app keeps a personal activity log in the **user's own private CloudKit database** (a CKSyncEngine private database, which we as the developer cannot access). Each log entry contains structural facts only: an identifier, a timestamp, the life area (for example "Body"), a difficulty number relative to the user's own level (for example 1.2), and whether the user marked it complete. **It contains no HealthKit values and no references to HealthKit samples.**
3. Any data derived from HealthKit (verification results, HealthKit-based calibration) is kept only on the device, excluded from backups, and never synced.

**Our questions:**
- (a) Is syncing the structural activity facts in (2) to the user's private CloudKit database permitted under 5.1.3(ii)?
- (b) If not, is it permitted when the activity was self-reported by the user and not read from HealthKit at all?
- (c) Would syncing HealthKit-derived verification results (e.g. "verified: yes") to the user's private CloudKit database be permitted?

We'd rather design this correctly from the start than find out at submission. Thank you for your guidance.

Kind regards,
Mathis
