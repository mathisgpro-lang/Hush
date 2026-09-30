# M1a: Growth Engine Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-Swift `Domain` target that computes the lived day, Depth, day completion, Ascent (the growth number) and Vitality exactly as chapter 04 specifies, proven by the reference golden vectors.

**Architecture:** One local Swift package `Core` at `app/Packages/Core` with a single library target `Domain` (Foundation only, no Apple UI or storage frameworks) and a Swift Testing target `DomainTests`. The engine is a set of small, pure, deterministic functions, each in its own file, with every constant in `RuleSetV1`. This plan covers the math core only. Entry parsing, corrections, day assembly, levels and grants come in plan M1b, and storage (GRDB) in M1c.

**Tech Stack:** Swift 6 (strict concurrency), Swift Package Manager, Swift Testing (`import Testing`), Xcode 27 toolchain, run on the Mac host with `swift test`.

**Spec:**
- `docs/master-plan/04-growth-model.md` (Part B, rev 7)
- `docs/master-plan/17-data-model.md` §B.6 (lived-day v2)
- `docs/master-plan/16-system-architecture.md` §B.2–B.3
- `docs/master-plan/reference/growth_reference_v1.py`: **the oracle**. Every expected number below was computed by it.

## Global Constraints

- `Domain` imports **Foundation only** (chapter 16 §B.2, rule 1). No GRDB, CloudKit, HealthKit, FoundationModels, SwiftUI or UIKit.
- Platforms: iOS 27.0 and macOS 27.0 (macOS only so that tests run on the host).
- Swift language mode 6, strict concurrency. All public types are `Sendable`.
- Numeric contract: the Swift results must match the reference script within **1e-9** (chapter 04 §B.8).
- All rule constants live in `RuleSetV1`; no magic numbers in the formulas.
- No third-party dependencies in `Domain`.
- Mathis can't read code: every behavior must be proven by a test whose name states the behavior in plain words.

## Review Focus

1. **Daylight-saving nights and travel:** a lived day must never move backward as time passes, and must follow the wall clock of the zone where the Action happened. Covered in Task 1 (Paris gap/repeat vectors, New York travel).
2. **A brand-new user with little or no history:** the Flame must be born bright, never in embers. Covered in Task 4 (V14).
3. **The same occurrence logged twice with different weights:** no pillar may ever go down. Covered in Task 2 (V12 plus an insertion property test).
4. **Corrupt numbers reaching the engine** (NaN, infinity, negative difficulty, presence above 1): they must contribute nothing, or be clamped, never crash or poison totals. Covered in Tasks 2, 3 and 4 ("defensive" tests).
5. **Two phones offline dealing different plans for the same day:** earned growth must never be retracted. Covered in Task 3 (V10).

---

## File Structure

```
app/Packages/Core/
  Package.swift                         package manifest (one library, one test target)
  Sources/Domain/
    RuleSetV1.swift                     every constant of rule set v1
    LivedDay.swift                      LocalDate, DayBoundary, LivedDayRule (algorithm v2)
    Pillar.swift                        Pillar enum
    Depth.swift                         ScoredAction, Depth (curve, effort, total)
    DayScore.swift                      Slot, DayScore (completion), Ascent
    Vitality.swift                      Vitality (forgiveness, comeback, window)
  Tests/DomainTests/
    TestSupport.swift                   expectClose helper, utc() helper, SplitMix64 RNG
    LivedDayTests.swift
    DepthTests.swift
    DayScoreTests.swift
    VitalityTests.swift
```

---

### Task 1: Package, rule set and the lived day

**Files:**
- Create: `app/Packages/Core/Package.swift`
- Create: `app/Packages/Core/Sources/Domain/RuleSetV1.swift`
- Create: `app/Packages/Core/Sources/Domain/LivedDay.swift`
- Create: `app/Packages/Core/Tests/DomainTests/TestSupport.swift`
- Test: `app/Packages/Core/Tests/DomainTests/LivedDayTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `RuleSetV1` (static constants listed in Step 3)
  - `struct LocalDate: Hashable, Comparable, Sendable { let year, month, day: Int }`
  - `struct DayBoundary: Sendable, Equatable { let hour, minute: Int; static let default }`
  - `enum LivedDayRule { static let version = 2; static func livedDay(at: Date, in: TimeZone, boundary: DayBoundary = .default) -> LocalDate }`
  - Test helpers `utc(_:)`, `expectClose(_:_:tolerance:)`, `SplitMix64`

- [ ] **Step 1: Create the package manifest and test support**

`app/Packages/Core/Package.swift`:
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [.library(name: "Domain", targets: ["Domain"])],
    targets: [
        .target(name: "Domain"),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
    ]
)
```

`app/Packages/Core/Tests/DomainTests/TestSupport.swift`:
```swift
import Foundation
import Testing

/// Parses an ISO 8601 UTC instant, e.g. "2026-03-28T23:30:00Z".
func utc(_ s: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)!
}

/// The chapter 04 numeric contract: equal within 1e-9.
func expectClose(_ got: Double, _ want: Double, tolerance: Double = 1e-9,
                 sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(abs(got - want) <= tolerance, "got \(got), want \(want)", sourceLocation: sourceLocation)
}

/// Deterministic RNG for property tests (Swift's default RNG can't be seeded).
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
```

- [ ] **Step 2: Write the failing lived-day tests**

`app/Packages/Core/Tests/DomainTests/LivedDayTests.swift`:
```swift
import Foundation
import Testing
@testable import Domain

struct LivedDayTests {
    let paris = TimeZone(identifier: "Europe/Paris")!
    let newYork = TimeZone(identifier: "America/New_York")!

    @Test func halfPastMidnightCountsForThePreviousDay() {
        // 00:30 on the DST-start night (29 Mar 2026, Paris, still CET = UTC+1)
        #expect(LivedDayRule.livedDay(at: utc("2026-03-28T23:30:00Z"), in: paris)
                == LocalDate(year: 2026, month: 3, day: 28))
    }

    @Test func oneMinuteBeforeTheBoundaryIsStillYesterday() {
        // 03:59 CEST on 10 Apr 2026 = 01:59Z
        #expect(LivedDayRule.livedDay(at: utc("2026-04-10T01:59:00Z"), in: paris)
                == LocalDate(year: 2026, month: 4, day: 9))
    }

    @Test func theBoundaryItselfStartsTheNewDay() {
        // 04:00 CEST on 10 Apr 2026 = 02:00Z
        #expect(LivedDayRule.livedDay(at: utc("2026-04-10T02:00:00Z"), in: paris)
                == LocalDate(year: 2026, month: 4, day: 10))
    }

    @Test func boundaryInsideTheSpringGapStartsAtTheFirstValidTime() {
        let b = DayBoundary(hour: 2, minute: 30)          // 02:00–03:00 doesn't exist on 29 Mar 2026
        // 03:10 CEST = 01:10Z → after B(29 Mar) = 03:00 CEST
        #expect(LivedDayRule.livedDay(at: utc("2026-03-29T01:10:00Z"), in: paris, boundary: b)
                == LocalDate(year: 2026, month: 3, day: 29))
        // 01:50 CET = 00:50Z → before the boundary
        #expect(LivedDayRule.livedDay(at: utc("2026-03-29T00:50:00Z"), in: paris, boundary: b)
                == LocalDate(year: 2026, month: 3, day: 28))
    }

    @Test func repeatedAutumnHourNeverMovesTheDayBackward() {
        let b = DayBoundary(hour: 2, minute: 30)          // 02:00–03:00 happens twice on 25 Oct 2026
        // 02:20 CEST (first pass) = 00:20Z → before the first 02:30
        #expect(LivedDayRule.livedDay(at: utc("2026-10-25T00:20:00Z"), in: paris, boundary: b)
                == LocalDate(year: 2026, month: 10, day: 24))
        // 02:40 CEST (first pass) = 00:40Z → new day
        #expect(LivedDayRule.livedDay(at: utc("2026-10-25T00:40:00Z"), in: paris, boundary: b)
                == LocalDate(year: 2026, month: 10, day: 25))
        // 02:10 CET (second pass) = 01:10Z → must stay on the new day
        #expect(LivedDayRule.livedDay(at: utc("2026-10-25T01:10:00Z"), in: paris, boundary: b)
                == LocalDate(year: 2026, month: 10, day: 25))
    }

    @Test func travelUsesTheWallClockWhereTheActionHappened() {
        // 02:00 EDT in New York on 15 Jun 2026 = 06:00Z → the previous New York date
        #expect(LivedDayRule.livedDay(at: utc("2026-06-15T06:00:00Z"), in: newYork)
                == LocalDate(year: 2026, month: 6, day: 14))
    }

    @Test func livedDayNeverDecreasesAcrossAFullDSTWeekend() {
        let b = DayBoundary(hour: 2, minute: 30)
        var previous = LocalDate(year: 2026, month: 10, day: 23)
        var t = utc("2026-10-23T22:00:00Z")
        let end = utc("2026-10-26T06:00:00Z")
        while t < end {
            let d = LivedDayRule.livedDay(at: t, in: paris, boundary: b)
            #expect(d >= previous, "went backward at \(t)")
            previous = d
            t = t.addingTimeInterval(60)
        }
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd app/Packages/Core && swift test --filter LivedDayTests`
Expected: FAIL to compile, with "cannot find 'LivedDayRule' in scope".

- [ ] **Step 4: Implement the rule set and the lived day**

`app/Packages/Core/Sources/Domain/RuleSetV1.swift`:
```swift
/// Every constant of growth rule set v1 (chapter 04 Part B). Changing any value = a new rule set.
public enum RuleSetV1 {
    public static let version = 1
    public static let edgeMultiplier = 1.2
    public static let edgeDifficulty = 1.2
    public static let fillCap = 0.5
    public static let emptyScheduleFullDay = 2.0
    public static let restGrowthCredit = 1.0
    public static let vitalityWindow = 14
    public static let vitalityDecay = 0.8
    public static let freeDaySpan = 7
    public static let liveBoost = 0.3
    public static let vitalityFloor = 0.15
    public static let embersThreshold = 0.25
    public static let absenceForComeback = 3
    public static let relight: [Int: Double] = [1: 0.60, 2: 0.80, 3: 1.00]
    public static let consistencyWindow = 27
    public static let consistencyBonus = 0.5
}
```

`app/Packages/Core/Sources/Domain/LivedDay.swift`:
```swift
import Foundation

public struct LocalDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year; self.month = month; self.day = day
    }

    public static func < (a: LocalDate, b: LocalDate) -> Bool {
        (a.year, a.month, a.day) < (b.year, b.month, b.day)
    }

    public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }
}

/// The wall-clock time at which a lived day starts (chapter 04: default 04:00; whole or half hours only).
public struct DayBoundary: Sendable, Equatable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        precondition((0..<24).contains(hour) && (minute == 0 || minute == 30), "boundary must be a whole or half hour")
        self.hour = hour; self.minute = minute
    }

    public static let `default` = DayBoundary(hour: 4, minute: 0)
}

/// Lived-day algorithm v2 (chapter 17 §B.6): B(X) = the earliest instant on date X whose wall clock is at or
/// after the boundary; livedDay(t) = the latest date X with B(X) ≤ t. Monotonic across DST gaps and repeats.
public enum LivedDayRule {
    public static let version = 2

    public static func livedDay(at instant: Date, in timeZone: TimeZone,
                                boundary: DayBoundary = .default) -> LocalDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: instant)
        let calendarDate = LocalDate(year: c.year!, month: c.month!, day: c.day!)
        if boundaryInstant(on: calendarDate, calendar: cal, boundary: boundary) <= instant {
            return calendarDate
        }
        let startOfDay = cal.date(from: c)!
        let previous = cal.date(byAdding: .day, value: -1, to: startOfDay)!
        let p = cal.dateComponents([.year, .month, .day], from: previous)
        return LocalDate(year: p.year!, month: p.month!, day: p.day!)
    }

    static func boundaryInstant(on date: LocalDate, calendar cal: Calendar, boundary: DayBoundary) -> Date {
        let start = cal.date(from: DateComponents(year: date.year, month: date.month, day: date.day))!
        return cal.nextDate(after: start.addingTimeInterval(-1),
                            matching: DateComponents(hour: boundary.hour, minute: boundary.minute, second: 0),
                            matchingPolicy: .nextTime,
                            repeatedTimePolicy: .first,
                            direction: .forward)!
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd app/Packages/Core && swift test --filter LivedDayTests`
Expected: PASS (7 tests).

- [ ] **Step 6: Commit**

```bash
git add app/Packages/Core
git commit -m "feat(domain): Core package, RuleSetV1 and lived-day algorithm v2 with DST tests"
```

---

### Task 2: Depth

**Files:**
- Create: `app/Packages/Core/Sources/Domain/Pillar.swift`
- Create: `app/Packages/Core/Sources/Domain/Depth.swift`
- Test: `app/Packages/Core/Tests/DomainTests/DepthTests.swift`

**Interfaces:**
- Consumes: `RuleSetV1` (Task 1).
- Produces:
  - `enum Pillar: Int, CaseIterable, Sendable, Hashable { case body, mind, heart, spirit, craft, world }`
  - `struct ScoredAction: Sendable, Equatable { let occurrenceKey: String; let pillarWeights: [Pillar: Double]; let d: Double; let isSpark: Bool; var isEdge: Bool; func contribution(to: Pillar) -> Double }`
  - `enum Depth { static func curve(_: Double) -> Double; static func effort(_: [ScoredAction], pillar: Pillar) -> Double; static func total(days: [[ScoredAction]], pillar: Pillar) -> Double }`

- [ ] **Step 1: Write the failing Depth tests**

`app/Packages/Core/Tests/DomainTests/DepthTests.swift`:
```swift
import Testing
@testable import Domain

struct DepthTests {
    private func body(_ key: String, d: Double = 1.0, spark: Bool = false) -> ScoredAction {
        ScoredAction(occurrenceKey: key, pillarWeights: [.body: 1.0], d: d, isSpark: spark)
    }

    @Test func consistencyReachesItsMaximumAfter27ActiveDays() {          // V1
        let days = (0..<28).map { [body("a\($0)")] }
        let day28 = Depth.total(days: days, pillar: .body) - Depth.total(days: Array(days.prefix(27)), pillar: .body)
        expectClose(day28, 1.5)
    }

    @Test func extraActionsInOneDayCountLessAndLess() {                   // V2
        let day = (0..<6).map { body("b\($0)") }
        expectClose(Depth.total(days: [day], pillar: .body), 3.25)
    }

    @Test func addingAnEasyActionNeverLowersDepth() {                     // V3
        let two = Depth.total(days: [[body("h1", d: 2), body("h2", d: 2)]], pillar: .body)
        let three = Depth.total(days: [[body("e", d: 0.5), body("h1", d: 2), body("h2", d: 2)]], pillar: .body)
        expectClose(two, 2.95)
        expectClose(three, 3.075)
        #expect(three > two)
    }

    @Test func aMultiPillarActionSplitsItsWeight() {                      // V4
        let hike = ScoredAction(occurrenceKey: "hike", pillarWeights: [.body: 0.5, .heart: 0.5], d: 1, isSpark: false)
        expectClose(Depth.total(days: [[hike]], pillar: .body), 0.5)
    }

    @Test func sparksAndHardActionsEarnTheEdgeBonus() {                  // V5
        expectClose(Depth.total(days: [[body("s", d: 1, spark: true)]], pillar: .body), 1.2)
        expectClose(Depth.total(days: [[body("p", d: 1.25)]], pillar: .body), 1.5)
    }

    @Test func aReweightedDuplicateNeverLowersAPillar() {                 // V12
        let original = ScoredAction(occurrenceKey: "o1", pillarWeights: [.body: 0.9, .heart: 0.1], d: 1.0, isSpark: false)
        let duplicate = ScoredAction(occurrenceKey: "o1", pillarWeights: [.body: 0.1, .heart: 0.9], d: 1.1, isSpark: false)
        expectClose(Depth.total(days: [[original]], pillar: .body), 0.9)
        expectClose(Depth.total(days: [[original, duplicate]], pillar: .body), 0.9)
        expectClose(Depth.total(days: [[original, duplicate]], pillar: .heart), 0.99)
    }

    @Test func insertingAnyActionAnywhereNeverLowersAnyPillar() {        // Review Focus 3 (property)
        var rng = SplitMix64(seed: 11)
        for _ in 0..<500 {
            var days: [[ScoredAction]] = (0..<Int.random(in: 1...20, using: &rng)).map { i in
                (0..<Int.random(in: 0...4, using: &rng)).map { j in
                    let p = Pillar.allCases.randomElement(using: &rng)!
                    return ScoredAction(occurrenceKey: "k\(i)-\(j % 3)", pillarWeights: [p: 1.0],
                                        d: Double.random(in: 0.5...2.0, using: &rng), isSpark: Bool.random(using: &rng))
                }
            }
            let before = Pillar.allCases.map { Depth.total(days: days, pillar: $0) }
            let i = Int.random(in: 0..<days.count, using: &rng)
            let p = Pillar.allCases.randomElement(using: &rng)!
            days[i].append(ScoredAction(occurrenceKey: "k\(i)-\(Int.random(in: 0...5, using: &rng))",
                                        pillarWeights: [p: Double.random(in: 0.1...1, using: &rng)],
                                        d: Double.random(in: 0.5...2.0, using: &rng), isSpark: false))
            let after = Pillar.allCases.map { Depth.total(days: days, pillar: $0) }
            for (b, a) in zip(before, after) { #expect(a >= b - 1e-12) }
        }
    }

    @Test func corruptNumbersContributeNothing() {                        // Review Focus 4 (defensive)
        let bad = [
            ScoredAction(occurrenceKey: "nan", pillarWeights: [.body: 1], d: .nan, isSpark: false),
            ScoredAction(occurrenceKey: "inf", pillarWeights: [.body: 1], d: .infinity, isSpark: false),
            ScoredAction(occurrenceKey: "neg", pillarWeights: [.body: 1], d: -1, isSpark: false),
            ScoredAction(occurrenceKey: "w", pillarWeights: [.body: .nan], d: 1, isSpark: false),
        ]
        expectClose(Depth.total(days: [bad], pillar: .body), 0)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd app/Packages/Core && swift test --filter DepthTests`
Expected: FAIL to compile, with "cannot find 'ScoredAction' in scope".

- [ ] **Step 3: Implement Pillar and Depth**

`app/Packages/Core/Sources/Domain/Pillar.swift`:
```swift
/// The six universal pillars (chapter 04 §A.2). Order is normative (tie-breaks use it).
public enum Pillar: Int, CaseIterable, Sendable, Hashable {
    case body, mind, heart, spirit, craft, world
}
```

`app/Packages/Core/Sources/Domain/Depth.swift`:
```swift
/// One completed Action as the growth engine sees it (after corrections; chapter 04 §B.2).
public struct ScoredAction: Sendable, Equatable {
    public let occurrenceKey: String
    public let pillarWeights: [Pillar: Double]
    public let d: Double
    public let isSpark: Bool

    public init(occurrenceKey: String, pillarWeights: [Pillar: Double], d: Double, isSpark: Bool) {
        self.occurrenceKey = occurrenceKey
        self.pillarWeights = pillarWeights
        self.d = d
        self.isSpark = isSpark
    }

    public var isEdge: Bool { isSpark || d >= RuleSetV1.edgeDifficulty }

    /// w_p × d × edge. Non-finite or non-positive inputs contribute nothing (upstream validators should
    /// prevent them; the engine must never crash or be poisoned by them).
    public func contribution(to pillar: Pillar) -> Double {
        guard d.isFinite, d > 0, let w = pillarWeights[pillar], w.isFinite, w > 0 else { return 0 }
        return w * d * (isEdge ? RuleSetV1.edgeMultiplier : 1.0)
    }
}

/// Depth (chapter 04 §B.3): monotonic by construction.
public enum Depth {
    /// Concave, non-decreasing daily effort curve.
    public static func curve(_ x: Double) -> Double {
        min(x, 2.0) + 0.5 * min(max(x - 2.0, 0.0), 1.0) + 0.25 * max(x - 3.0, 0.0)
    }

    /// E(p, D): per occurrence, the max over its duplicates of w_p × d × edge; summed in key order.
    public static func effort(_ actions: [ScoredAction], pillar: Pillar) -> Double {
        var best: [String: Double] = [:]
        for a in actions {
            best[a.occurrenceKey] = max(best[a.occurrenceKey] ?? 0, a.contribution(to: pillar))
        }
        return best.keys.sorted().reduce(0.0) { $0 + best[$1]! }
    }

    /// Total Depth for a pillar. `days` = consecutive lived days, oldest first (empty days included).
    public static func total(days: [[ScoredAction]], pillar: Pillar) -> Double {
        let efforts = days.map { effort($0, pillar: pillar) }
        var total = 0.0
        for i in efforts.indices {
            let window = efforts[max(0, i - RuleSetV1.consistencyWindow)..<i]
            let active = Double(window.filter { $0 > 0 }.count)
            let consistency = 1.0 + RuleSetV1.consistencyBonus * active / Double(RuleSetV1.consistencyWindow)
            total += curve(efforts[i]) * consistency
        }
        return total
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd app/Packages/Core && swift test --filter DepthTests`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add app/Packages/Core
git commit -m "feat(domain): Depth with concave daily curve, per-pillar duplicate max, consistency; vectors V1-V5, V12"
```

---

### Task 3: Day completion and Ascent

**Files:**
- Create: `app/Packages/Core/Sources/Domain/DayScore.swift`
- Test: `app/Packages/Core/Tests/DomainTests/DayScoreTests.swift`

**Interfaces:**
- Consumes: `RuleSetV1` (Task 1).
- Produces:
  - `struct Slot: Sendable, Equatable { let slotId: String; let d: Double }`
  - `enum DayScore { static func completion(slots: [Double], doneSlots: [Double], fill: Double) -> Double; static func completion(contracts: [[Slot]], done: Set<String>, fill: Double, isPlannedRest: Bool = false) -> Double }`
  - `enum Ascent { static func value(completions: [Double]) -> Double }`

- [ ] **Step 1: Write the failing tests**

`app/Packages/Core/Tests/DomainTests/DayScoreTests.swift`:
```swift
import Testing
@testable import Domain

struct DayScoreTests {
    @Test func aFullDayEarnsOnePercent() {                                // V7a
        expectClose(Ascent.value(completions: [DayScore.completion(slots: [1, 1], doneSlots: [1, 1], fill: 0)]), 1.01)
    }

    @Test func aHalfDayEarnsHalf() {                                      // V7b
        expectClose(Ascent.value(completions: [DayScore.completion(slots: [1, 1], doneSlots: [1], fill: 0)]), 1.005)
    }

    @Test func extraEffortCanFillAtMostHalfTheDay() {                     // V7c
        expectClose(DayScore.completion(slots: [1, 1], doneSlots: [], fill: 4), 0.5)
    }

    @Test func withNoPlanTwoUnitsOfEffortMakeAFullDay() {                 // V7d
        expectClose(DayScore.completion(slots: [], doneSlots: [], fill: 1), 0.5)
    }

    @Test func aYearOfFullDaysIsTheTrueCeiling() {                        // V7e
        expectClose(Ascent.value(completions: Array(repeating: 1.0, count: 365)), 37.783434332887275)
    }

    @Test func voidingAScheduledItemLowersTheDayButVoidingSurplusDoesNot() { // V8a, V8b
        expectClose(DayScore.completion(slots: [1, 1], doneSlots: [1], fill: 0), 0.5)
        expectClose(DayScore.completion(slots: [1, 1], doneSlots: [1, 1], fill: 0), 1.0)
    }

    @Test func aCompetingOfflineContractNeverRetractsGrowth() {           // V10
        let a = [Slot(slotId: "a1", d: 1.0)]
        let b = [Slot(slotId: "b1", d: 1.0)]
        expectClose(DayScore.completion(contracts: [a], done: ["a1"], fill: 0), 1.0)
        expectClose(DayScore.completion(contracts: [a, b], done: ["a1"], fill: 0), 1.0)
    }

    @Test func aPlannedRestDayCountsAsAFullDay() {                        // decision 65
        expectClose(DayScore.completion(contracts: [[Slot(slotId: "r", d: 1)]], done: [], fill: 0, isPlannedRest: true), 1.0)
    }

    @Test func corruptNumbersAreIgnoredAndCompletionStaysInRange() {       // Review Focus 4
        expectClose(DayScore.completion(slots: [1, 1], doneSlots: [1], fill: .nan), 0.5)
        expectClose(DayScore.completion(slots: [1], doneSlots: [1], fill: -3), 1.0)
        expectClose(DayScore.completion(slots: [0, 0], doneSlots: [], fill: 1), 0.5)
        expectClose(Ascent.value(completions: [.nan, 2.0, -1.0]), 1.01)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd app/Packages/Core && swift test --filter DayScoreTests`
Expected: FAIL to compile, with "cannot find 'DayScore' in scope".

- [ ] **Step 3: Implement**

`app/Packages/Core/Sources/Domain/DayScore.swift`:
```swift
/// A scheduled slot in a day contract (a `dayPlanned` or materialized schedule, chapter 04 §B.1).
public struct Slot: Sendable, Equatable {
    public let slotId: String
    public let d: Double
    public init(slotId: String, d: Double) { self.slotId = slotId; self.d = d }
}

/// Day completion (chapter 04 §B.4).
public enum DayScore {
    /// One contract. `fill` = Σ d of completed non-scheduled Actions (capped at half the day).
    public static func completion(slots: [Double], doneSlots: [Double], fill: Double) -> Double {
        let f = fill.isFinite ? max(0, fill) : 0
        let total = slots.filter { $0.isFinite && $0 > 0 }.reduce(0, +)
        guard total > 0 else { return min(1, f / RuleSetV1.emptyScheduleFullDay) }
        let done = doneSlots.filter { $0.isFinite && $0 > 0 }.reduce(0, +)
        return min(1, (done + min(f, RuleSetV1.fillCap * total)) / total)
    }

    /// Every issued contract for the day is scored; the day takes the max, so nothing is ever retracted.
    public static func completion(contracts: [[Slot]], done: Set<String>, fill: Double,
                                  isPlannedRest: Bool = false) -> Double {
        if isPlannedRest { return RuleSetV1.restGrowthCredit }
        guard !contracts.isEmpty else { return completion(slots: [], doneSlots: [], fill: fill) }
        return contracts.map { c in
            completion(slots: c.map(\.d), doneSlots: c.filter { done.contains($0.slotId) }.map(\.d), fill: fill)
        }.max()!
    }
}

/// Ascent, the growth number (chapter 04 §B.4): starts at ×1.00, at most +1% a day, never subtracted.
public enum Ascent {
    public static func value(completions: [Double]) -> Double {
        completions.reduce(1.0) { g, c in
            let clamped = c.isFinite ? min(1, max(0, c)) : 0
            return g * (1 + 0.01 * clamped)
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd app/Packages/Core && swift test --filter DayScoreTests`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add app/Packages/Core
git commit -m "feat(domain): day completion (fill cap, contracts max, rest credit) and Ascent; vectors V7, V8, V10"
```

---

### Task 4: Vitality

**Files:**
- Create: `app/Packages/Core/Sources/Domain/Vitality.swift`
- Test: `app/Packages/Core/Tests/DomainTests/VitalityTests.swift`

**Interfaces:**
- Consumes: `RuleSetV1` (Task 1).
- Produces:
  - `enum Vitality { static func value(history: [Double], today: Double = 0) -> Double; static func forgivenDays(_ history: [Double]) -> Set<Int>; static func isEmbers(_ v: Double) -> Bool }`
  - `history` = the presence of finalized lived days, oldest first (planned rest and pause already = 1.0); `today` = the presence of the provisional current day so far.

- [ ] **Step 1: Write the failing tests**

`app/Packages/Core/Tests/DomainTests/VitalityTests.swift`:
```swift
import Testing
@testable import Domain

struct VitalityTests {
    let full = Array(repeating: 1.0, count: 30)
    var away: [Double] { Array(full.prefix(16)) + Array(repeating: 0.0, count: 14) }

    @Test func livingFullyKeepsTheFlameBright() {                         // V6a
        expectClose(Vitality.value(history: full), 1.0)
    }

    @Test func oneDayOffIsFree() {                                        // V6b
        expectClose(Vitality.value(history: Array(full.dropLast()) + [0.0]), 1.0)
    }

    @Test func threeDaysAwayVisiblyDimsTheFlame() {                       // V6c
        expectClose(Vitality.value(history: Array(full.dropLast(3)) + [0, 0, 0]), 0.6987509255933241)
    }

    @Test func twoWeeksAwayOrMoreRestsInEmbersAtTheFloor() {              // V6d, V6e
        expectClose(Vitality.value(history: away), 0.15)
        expectClose(Vitality.value(history: Array(repeating: 0.0, count: 30)), 0.15)
        #expect(Vitality.isEmbers(Vitality.value(history: away)))
    }

    @Test func theComebackRelightsInThreeDays() {                         // V6f–h
        expectClose(Vitality.value(history: away, today: 1), 0.60)
        expectClose(Vitality.value(history: away + [1], today: 1), 0.80)
        expectClose(Vitality.value(history: away + [1, 1], today: 1), 1.00)
    }

    @Test func completingDayFourOfAComebackNeverDims() {                  // V9a–c
        expectClose(Vitality.value(history: away + [1, 1, 1]), 1.0)
        expectClose(Vitality.value(history: away + [1, 1, 1], today: 1), 1.0)
        expectClose(Vitality.value(history: away + [1, 1, 1, 1], today: 1), 1.0)
    }

    @Test func aRealNewAbsenceAfterAComebackDimsHonestly() {              // V9d
        expectClose(Vitality.value(history: away + [1, 1, 1, 1, 0, 0, 0]), 0.6355744157043132)
    }

    @Test func halfDaysDuringAComebackNeverDimOnCompletion() {            // V11
        let half = away + [0.5, 0.5, 0.5]
        let morning = Vitality.value(history: half)
        let completed = Vitality.value(history: half, today: 1)
        expectClose(morning, 1.0)
        expectClose(completed, 1.0)
        #expect(completed >= morning)
        expectClose(Vitality.value(history: half + [1.0]), 0.8048780487804877)
    }

    @Test func theFlameIsBornBright() {                                   // V14
        expectClose(Vitality.value(history: []), 1.0)
        expectClose(Vitality.value(history: [1.0]), 1.0)
        expectClose(Vitality.value(history: [0.0, 0.0]), 0.8326394031074023)
    }

    @Test func withinADayDoingMoreNeverLowersVitality() {                 // V13 (property)
        var rng = SplitMix64(seed: 7)
        for _ in 0..<2000 {
            let h = (0..<Int.random(in: 0...40, using: &rng)).map { _ in [0.0, 0.0, 0.5, 1.0].randomElement(using: &rng)! }
            let values = [0.0, 0.25, 0.5, 1.0].map { Vitality.value(history: h, today: $0) }
            for (a, b) in zip(values, values.dropFirst()) { #expect(a <= b + 1e-12, "history \(h)") }
        }
    }

    @Test func corruptPresenceIsClampedNotPropagated() {                  // Review Focus 4
        let v = Vitality.value(history: [1, .nan, 2.5, -1] + Array(full.prefix(10)), today: .infinity)
        #expect(v.isFinite && v >= 0.15 && v <= 1.0)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd app/Packages/Core && swift test --filter VitalityTests`
Expected: FAIL to compile, with "cannot find 'Vitality' in scope".

- [ ] **Step 3: Implement**

`app/Packages/Core/Sources/Domain/Vitality.swift`:
```swift
import Foundation

/// Vitality (chapter 04 §B.5, rev 7). Mirrors `reference/growth_reference_v1.py::vitality` exactly.
public enum Vitality {
    public static func isEmbers(_ v: Double) -> Bool { v <= RuleSetV1.embersThreshold }

    /// Absence days (runs of ≥ 3 zeros) immediately followed by ≥ 3 finalized days with presence > 0.
    public static func forgivenDays(_ history: [Double]) -> Set<Int> {
        var out = Set<Int>()
        var i = 0
        while i < history.count {
            guard history[i] == 0 else { i += 1; continue }
            var j = i
            while j < history.count && history[j] == 0 { j += 1 }
            var k = j
            while k < history.count && history[k] > 0 { k += 1 }
            if j - i >= RuleSetV1.absenceForComeback && k - j >= 3 { out.formUnion(i..<j) }
            i = j
        }
        return out
    }

    public static func value(history rawHistory: [Double], today rawToday: Double = 0) -> Double {
        let clamp: (Double) -> Double = { $0.isFinite ? min(1, max(0, $0)) : 0 }
        let history = rawHistory.map(clamp)
        let today = clamp(rawToday)

        // Comeback state from finalized days only.
        var nFin = 0
        var k = history.count - 1
        while k >= 0 && history[k] > 0 { nFin += 1; k -= 1 }
        var absence = 0
        while k >= 0 && history[k] == 0 { absence += 1; k -= 1 }
        let inComeback = absence >= RuleSetV1.absenceForComeback && nFin <= 3 && (nFin >= 1 || today > 0)

        // Window: the last 14 finalized days, minus forgiven days; days before birth count as 1.0.
        let forgiven = forgivenDays(history)
        let lastIndices = history.isEmpty ? [] :
            Array(stride(from: history.count - 1, through: max(0, history.count - RuleSetV1.vitalityWindow), by: -1))
        let missing = RuleSetV1.vitalityWindow - lastIndices.count
        var past = lastIndices.filter { !forgiven.contains($0) }.map { history[$0] }
            + Array(repeating: 1.0, count: missing)

        let raw = (0..<past.count).map { pow(RuleSetV1.vitalityDecay, Double($0)) }
        let totalWeight = raw.reduce(0, +)
        let weights = totalWeight > 0 ? raw.map { $0 / totalWeight } : []

        let span = min(RuleSetV1.freeDaySpan, past.count)
        if span > 0 && past[0..<span].contains(where: { $0 > 0 }) {
            let j = (0..<span).min { (past[$0], $0) < (past[$1], $1) }!
            past[j] = 1.0
        }

        let vHist = zip(weights, past).reduce(0.0) { $0 + $1.0 * $1.1 }
        var v = vHist + (1.0 - vHist) * RuleSetV1.liveBoost * today
        if inComeback {
            let nEff = min(3, nFin + (today > 0 ? 1 : 0))
            if nEff >= 1, let relight = RuleSetV1.relight[nEff] { v = max(v, relight) }
        }
        return max(RuleSetV1.vitalityFloor, v)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd app/Packages/Core && swift test --filter VitalityTests`
Expected: PASS (11 tests).

- [ ] **Step 5: Run the full suite and the reference oracle together**

Run: `cd app/Packages/Core && swift test && python3 ../../../docs/master-plan/reference/growth_reference_v1.py | tail -1`
Expected: all Swift tests pass (35 tests), and the reference prints `all vectors pass`.

- [ ] **Step 6: Commit**

```bash
git add app/Packages/Core
git commit -m "feat(domain): Vitality with forgiveness, comeback state machine, born-bright window; vectors V6, V9, V11, V13, V14"
```

---

## After the plan

- **Independent review:** run Codex read-only over `app/Packages/Core` against chapter 04 Part B and the reference script (chapter 22 §B.2, item 6). Save the report to `docs/reviews/`.
- **Next plans:** M1b (entries → engine: corrections graph, occurrence de-duplication, day assembly and materialization, levels, grants, `GrowthEngine.compute(entries:asOf:settings:)`) and M1c (`RecordStore` on GRDB).
