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
