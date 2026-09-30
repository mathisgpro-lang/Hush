# 22 — Building with AI Agents

**Status:** First pass (Phase B): Part A ✅ approved 2026-09-30 · Part B 🔎 revision 4 (final design pass, decision 60), in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 20, 38, 39, 46

---

# Part A — For Mathis

## A.1 How a feature gets built

```
 1. Approved chapter            (you + Claude, in conversation)
 2. Build plan                  (Claude writes a step-by-step plan from the chapter)
 3. Build + tests               (Claude Code writes the code and the tests that prove it works)
 4. Self-check                  (the app runs in the iPhone simulator; screenshots are checked)
 5. Independent review          (Codex reviews the work without seeing Claude's reasoning)
 6. Fixes                       (until both AIs and all tests agree)
 7. On your iPhone              (TestFlight: you try it and judge the feel)
 8. Done                        (only when it feels right to you)
```

Your part is steps 1 and 7: deciding *what* it should be, and judging *how it feels*. You never have to read code.

**One rule protects you:** if the AIs find a problem that could **lose or leak data**, they can never decide on their own to ignore it. Only you can accept such a risk, and only after it's been explained to you in plain language.

## A.2 A realistic rhythm at 1–2 hours a day

- **Planning phase (now):** conversation and chapter reviews.
- **Building phase:** most days you give short feedback on something that just landed on your phone ("haptic too soft," "Flame too orange"). Some days are conversation days, when we plan the next feature. The AI agents work while you're away; you review when you're back.

## A.3 What you'll need (reminder comes when the MVP plan is approved)

| Tool | What it is | Cost |
|---|---|---|
| **Xcode 27** | Apple's app-building tool (large download, from the Mac App Store). It includes AI agents. | Free |
| **Codex** | Already installed (inside your ChatGPT app) and signed in. ✅ | — |
| **Apple Developer Program** | Required for iCloud, TestFlight and the App Store. | $99/year |
| **TestFlight app** | On your iPhone, to receive each new version. | Free |

---

# Part B — For the builders

## B.1 Repository layout (first pass)

```
/CLAUDE.md, /AGENTS.md          agent context (keep current)
/docs/vision/                   brief, decisions log, conversation log
/docs/master-plan/              chapters (the specification)
/docs/plans/                    build plans, one per feature (YYYY-MM-DD-<feature>.md)
/docs/reviews/                  independent review reports
/docs/dependencies.md           every third-party dependency, with justification
/app/                           Xcode project + one local Swift package (targets per 16 §B.2)
/relay/                         Cloudflare Worker (TypeScript)
/assets/flame/                  artist-made Flame source assets
/content/                       content catalog source (16 §B.10)
```

## B.2 Definition of done (every feature)

1. It traces to an approved chapter section (link it in the plan).
2. Unit tests pass. `Domain` changes include new or updated golden vectors, plus permutation tests (the same entries in any order give the same result).
3. The **required scenario tests** (B.4) relevant to the feature pass.
4. UI is verified in the iOS Simulator, with screenshots attached to the plan's verification section.
5. **Real-device check** where platform behavior matters (sync, HealthKit, App Attest, haptics). "Production *environment*" and "real user *data*" are different things:
   - **Development builds:** the CloudKit development environment plus Relay staging.
   - **TestFlight integration tests:** TestFlight always uses CloudKit's **production environment** and production App Attest. So integration tests run in a **separate test app ID and CloudKit container** (e.g. `iCloud.<bundle>.test`) with its own deployed production schema, plus Relay staging, using test accounts only.
   - **Mathis's feel review (step 7)** uses the real app's TestFlight build. During the private beta, that's real user data by design.
   - **Never** run destructive tests against the real container.
6. An independent Codex review is done and every finding is resolved, or waived under B.3.
7. Mathis approves the feel on device (TestFlight).
8. The decisions log and chapter are updated if anything changed.

## B.3 Waivers
- **Only Mathis can waive a review finding**, after a plain-language explanation from Claude that states the risk and gives a recommendation. The waiver is logged in the decisions log.
- **Agents must never waive, downgrade or silently defer** a finding about data loss, data leakage, privacy, safety (Companion) or security.
- Style and minor findings can be deferred by the agents *only* by logging them in the plan's "deferred" section, which gets reviewed at each milestone.

## B.4 Required scenario tests (the failures that destroy trust)

| Area | Scenarios |
|---|---|
| Sync | Reordered arrival; a duplicate ID with the same and with different content; late arrival before the projection checkpoint; a crash between the local write and the outbox (must be impossible: same transaction); a crash mid-upload; CKSyncEngine state restore |
| Accounts | iCloud sign-out and sign-in to a different account; no-iCloud → iCloud attach; quota exceeded |
| Deletion | Delete-everything while offline; interrupted deletion then relaunch; a stale second device reconnecting after deletion (must not resurrect); **the Codex round-2 interleaving: B fetches the generation, A deletes, B uploads, then B must fail with zoneNotFound and not recreate the zone (real CloudKit)**; a concurrent Meta update (change-tag retry); **a delayed zone-creation operation for a losing generation (the sweep removes it); two devices deleting at once; crash → deletion → relaunch with a pending import journal (the journal is discarded, nothing restored)**; memory tombstone versus a concurrent edit |
| Grants and scoring | Two offline devices granting the same entitlement; a correction after a grant (the grant stays); **two offline `dayPlanned` for one day; concurrent Spark swaps; days scored under different rulesVersions; device loss in `.phoneOnly` mode reproducing Depth, G and Vitality exactly, including zero-completion days** |
| Time | Lived-day v2 DST vectors (gap and repeated hour, including a 02:30 boundary); travel across time zones; backdating; Vitality decay with no new entries (`asOf`) |
| Health | Each `HealthFactSyncMode`; **device loss in `.phoneOnly` mode → Depth, G and grants identical after restore**; HealthKit denied, unavailable or sample deleted → `unknown`, never failure; untrusted-source samples stay `selfReported`; app-written samples stay `selfReported`; orphan reconciliation of HealthKit writes; backup exclusion after migration; the memory validator rejects H1 values |
| Import | Old-schema import; conflicting IDs; oversized or malicious archive; a retired-generation manifest; export → import → sync round trip with **no quarantine** (hash preserved); crash between the P and H2 commits (journal resume); both modes × H2 opt-in on and off |
| Relay | Assertion replay (counter reuse); a join after the acceptance deadline; duplicate joins; the kill switch; Relay down (queued joins sent later) |
| AI | Each row of the per-task outcome matrix (16 §B.4); invented source IDs rejected; validator fail-closed |
| Privacy | The `NetworkGate` blocks non-allowlisted hosts and redirects; no personal fields in diagnostics |

## B.5 Process conventions
- Planning uses the superpowers workflow: brainstorming → spec (chapter) → writing-plans → execution with TDD.
- Work happens on feature branches (git worktrees for isolation); `main` stays green.
- Small, focused commits, each with the co-author trailer.
- An agent never marks work "done" without running the verification commands and showing their output.
- Where the two AIs disagree, it gets surfaced to Mathis in plain language with a recommendation. Never resolved silently.
- **Codex invocation:** `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex exec -s read-only` with a review prompt that points to the files. Reports are saved to `docs/reviews/`.

## B.6 Testing layers (detail in chapter 21)
- **Unit:** `Domain` (golden vectors, permutations), `Data` (append-only triggers, export/import round trip, deletion), `Companion` (validators, routing matrix, source resolution).
- **Scenario:** B.4.
- **Snapshot:** key screens under several theme states.
- **UI tests:** the tracking moment, offline mode, iCloud-off mode.
- **Evals:** Companion task quality per model tier (these decide routing).
