# 22 — Building with AI Agents

**Status:** First pass (Phase B): Part A ✅ approved 2026-09-30 · Part B 🔎 in Codex review · **Last updated:** 2026-09-30
**Based on:** decisions 20, 38, 39

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

## A.2 A realistic rhythm at 1–2 hours a day

- **Planning phase (now):** conversation and chapter reviews, roughly one to two chapters a week at the depth we've been working at.
- **Building phase:** most days you give short feedback on something that just landed on your phone ("haptic too soft," "Flame too orange"). Some days are conversation days, when we plan the next feature. The AI agents work while you're away; you review when you're back.

## A.3 What you'll need to install (when building starts, not now)

| Tool | What it is | Cost |
|---|---|---|
| **Xcode 27** | Apple's app-building tool (large download, from the Mac App Store). It now includes AI agents built in. | Free |
| **Codex CLI** | OpenAI's coding agent, for the independent reviews. **It isn't installed on this Mac yet.** | Needs an OpenAI/ChatGPT account |
| **Apple Developer Program** | Required for TestFlight (your phone) and the App Store. | $99/year |
| **TestFlight app** | On your iPhone, to receive each new version. | Free |

---

# Part B — For the builders

## B.1 Repository layout (first pass)

```
/CLAUDE.md, /AGENTS.md          agent context (keep current)
/docs/vision/                   brief, decisions log, conversation log
/docs/master-plan/              chapters (the specification)
/docs/plans/                    build plans, one per feature (YYYY-MM-DD-<feature>.md)
/docs/dependencies.md           every third-party dependency, with justification
/app/                           Xcode project + local Swift packages (16 §B.2)
/relay/                         Cloudflare Worker (TypeScript)
/assets/flame/                  artist-made Flame source assets
```

## B.2 Definition of done (every feature)
1. It traces to an approved chapter section (link it in the plan).
2. Unit tests pass; `GrowthRules` changes include new or updated golden vectors.
3. UI is verified in the iOS Simulator, with screenshots attached to the plan's verification section.
4. No network calls in the tracking-moment path (test); no hard-coded look and feel (lint); no Class H data in payloads (test).
5. An independent Codex review is done and its findings resolved or explicitly waived with a reason.
6. Mathis approves the feel on device (TestFlight).
7. The decisions log and chapter are updated if anything changed.

## B.3 Process conventions
- Planning uses the superpowers workflow: brainstorming → spec (chapter) → writing-plans → execution with TDD.
- Work happens on feature branches (git worktrees for isolation); `main` stays green.
- Small, focused commits, each with the co-author trailer.
- An agent never marks work "done" without running the verification commands and showing their output.
- Where the two AIs disagree, it gets surfaced to Mathis in plain language with a recommendation. Never resolved silently.

## B.4 Testing layers (detail in chapter 21)
- **Unit:** `GrowthRules` (golden vectors), `RecordKit` (append-only invariants, export round-trip), `CompanionKit` (safety validators, routing policy).
- **Snapshot:** key screens under several theme states (early, deep and Transformation Flames).
- **UI tests:** the tracking-moment flow, offline mode, iCloud-off mode.
- **Evals:** Companion task quality per model tier (these decide routing, 16 §B.4).

## B.5 Open
- Install and authenticate the Codex CLI. **Mathis:** needs his OpenAI account login (Claude can run the install).
- Xcode 27 install. Needed before the first build (not during planning).
