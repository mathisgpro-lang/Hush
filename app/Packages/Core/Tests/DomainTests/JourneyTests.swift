import Foundation
import Testing
@testable import Domain

struct JourneyTests {
    @Test func theJourneyStartsAtTheEmber() {
        #expect(Journey.step(daysSinceBirth: 0, activeDays: 1, ownsMetal: false) == 0)
    }

    @Test func theSparkOpensOnTheSecondDay() {
        #expect(Journey.step(daysSinceBirth: 1, activeDays: 1, ownsMetal: false) == 1)
    }

    @Test func stepsOpenByLivingNotByTheCalendar() {
        // Someone who was away 20 days but only lived 2 days is still at the Spark: never "behind", just earlier.
        #expect(Journey.step(daysSinceBirth: 20, activeDays: 2, ownsMetal: false) == 1)
        #expect(Journey.step(daysSinceBirth: 5, activeDays: 3, ownsMetal: false) == 2)
        #expect(Journey.step(daysSinceBirth: 9, activeDays: 7, ownsMetal: false) == 3)
        #expect(Journey.step(daysSinceBirth: 12, activeDays: 10, ownsMetal: false) == 4)
    }

    @Test func owningTheMetalEraMeansTheForge() {
        #expect(Journey.step(daysSinceBirth: 40, activeDays: 30, ownsMetal: true) == 5)
    }

    @Test func metalNeedsTimeLivedNotJustEffort() {
        #expect(!Journey.metalEligible(activeDays: 12, totalDepth: 500))
        #expect(Journey.metalEligible(activeDays: 30, totalDepth: 60))
    }

    @Test func isoWeeksMatchTheCalendar() {
        #expect(Journey.isoWeek(LocalDate(year: 2026, month: 10, day: 1)) == "2026-W40")
        #expect(Journey.isoWeek(LocalDate(year: 2027, month: 1, day: 1)) == "2026-W53")
    }
}
