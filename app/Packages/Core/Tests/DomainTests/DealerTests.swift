import Foundation
import Testing
@testable import Domain

struct DealerTests {
    let day = LocalDate(year: 2026, month: 10, day: 2)
    let paths = [ActivePath(pathId: "p1", templateId: "move", pillar: .body)]
    let sparks = [SparkCandidate(id: "s-body", pillar: .body), SparkCandidate(id: "s-heart", pillar: .heart),
                  SparkCandidate(id: "s-mind", pillar: .mind)]

    @Test func dayOneHasOnlyYourPathSteps() {
        let slots = Dealer.plan(day: day, paths: paths, sparks: sparks, seed: "x", sparkUnlocked: false, recentlyDealt: [])
        #expect(slots.map(\.occurrenceKey) == ["path:p1:2026-10-02"])
    }

    @Test func fromDayTwoASparkWidensTheAdventureBeyondYourPaths() {
        let slots = Dealer.plan(day: day, paths: paths, sparks: sparks, seed: "x", sparkUnlocked: true, recentlyDealt: [])
        #expect(slots.count == 2)
        let spark = slots.last!
        #expect(spark.isSpark && spark.d == 1.25)
        #expect(spark.pillarWeights[.body] == nil)          // not the pillar you already walk
    }

    @Test func theSameDayAlwaysDealsTheSameSpark() {
        let a = Dealer.pickSpark(day: day, paths: paths, sparks: sparks, seed: "seed", recentlyDealt: [])
        let b = Dealer.pickSpark(day: day, paths: paths, sparks: sparks.reversed(), seed: "seed", recentlyDealt: [])
        #expect(a == b)
    }

    @Test func aSwapNeverReturnsTheSameSpark() {
        let first = Dealer.pickSpark(day: day, paths: paths, sparks: sparks, seed: "s", recentlyDealt: [])!
        let swap = Dealer.pickSpark(day: day, paths: paths, sparks: sparks, seed: "s", recentlyDealt: [], excluding: [first.id])!
        #expect(swap.id != first.id)
    }

    @Test func atMostThreePathsAreActive() {
        let tz = TimeZone(identifier: "UTC")!
        let s = EngineSettings(timeZone: tz)
        let entries = (0..<5).map { i in
            Entry.make(.pathStarted(pathId: "p\(i)", templateId: "t", pillar: .mind),
                       at: Date(timeIntervalSince1970: 1_790_000_000 + Double(i)), settings: s)
        }
        #expect(Dealer.activePaths(entries).map(\.pathId) == ["p0", "p1", "p2"])
    }
}
