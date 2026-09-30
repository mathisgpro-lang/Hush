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
