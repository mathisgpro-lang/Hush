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
