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
