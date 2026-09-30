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
