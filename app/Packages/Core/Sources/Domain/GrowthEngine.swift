import Foundation

public struct EngineSettings: Sendable, Equatable {
    public let timeZone: TimeZone
    public let boundary: DayBoundary
    public init(timeZone: TimeZone, boundary: DayBoundary = .default) {
        self.timeZone = timeZone
        self.boundary = boundary
    }
}

/// Everything the Flame, the Sanctuary and Today need, derived from the record (never stored as truth).
public struct DerivedState: Sendable, Equatable {
    public var today: LocalDate
    public var bornDay: LocalDate?
    public var daysSinceBirth: Int
    public var ascent: Double
    public var vitality: Double
    public var comebackActive: Bool
    public var depth: [Pillar: Double]
    public var recentMix: [Pillar: Double]
    public var activeDays: Int
    public var todayCompletion: Double
    public var todayPlan: [PlannedSlot]
    public var completedToday: Set<String>
    /// Every non-voided completed occurrence key, all time (e.g. this week's Ritual).
    public var completedEver: Set<String>
    public var witnessed: Set<String>

    public var isEmbers: Bool { Vitality.isEmbers(vitality) }
    public var totalDepth: Double { depth.values.reduce(0, +) }
}

/// The front door of the growth engine (chapter 16 §B.3): pure, deterministic, order-independent.
public enum GrowthEngine {
    public static func compute(entries rawEntries: [Entry], asOf: Date, settings: EngineSettings) -> DerivedState {
        let entries = rawEntries.sorted { ($0.livedDay, $0.occurredAt, $0.id.uuidString) < ($1.livedDay, $1.occurredAt, $1.id.uuidString) }
        let today = LivedDayRule.livedDay(at: asOf, in: settings.timeZone, boundary: settings.boundary)
        let voided = effectiveVoids(entries)
        let live = entries.filter { !voided.contains($0.id) && $0.livedDay <= today }

        let bornDay = live.compactMap { if case .flameBorn = $0.payload { $0.livedDay } else { nil } }.min()
            ?? live.map(\.livedDay).min()

        var state = DerivedState(today: today, bornDay: bornDay, daysSinceBirth: 0, ascent: 1, vitality: 1,
                                 comebackActive: false, depth: [:], recentMix: [:], activeDays: 0,
                                 todayCompletion: 0, todayPlan: [], completedToday: [], completedEver: [], witnessed: [])
        state.witnessed = Set(live.compactMap { if case .momentWitnessed(let k) = $0.payload { k } else { nil } })
        guard let born = bornDay else { return state }
        let dayCount = born.days(to: today) + 1
        state.daysSinceBirth = dayCount - 1

        // Group by lived day.
        var contracts: [LocalDate: [[PlannedSlot]]] = [:]
        var rest: [LocalDate: Bool] = [:]
        var actions: [LocalDate: [ScoredAction]] = [:]
        for e in live {
            switch e.payload {
            case .dayPlanned(let isRest, let slots):
                contracts[e.livedDay, default: []].append(slots)
                if isRest { rest[e.livedDay] = true }
            case .actionCompleted(let key, let weights, let d, let spark):
                actions[e.livedDay, default: []].append(ScoredAction(occurrenceKey: key, pillarWeights: weights, d: d, isSpark: spark))
            default: break
            }
        }

        var completions: [Double] = []
        var dayActions: [[ScoredAction]] = []
        for i in 0..<dayCount {
            let day = born.adding(days: i)
            let acts = actions[day] ?? []
            let done = Set(acts.map(\.occurrenceKey))
            let dayContracts = (contracts[day] ?? []).map { $0.map { Slot(slotId: $0.occurrenceKey, d: $0.d) } }
            let scheduled = Set((contracts[day] ?? []).flatMap { $0.map(\.occurrenceKey) })
            let fill = Dictionary(grouping: acts.filter { !scheduled.contains($0.occurrenceKey) }, by: \.occurrenceKey)
                .values.map { $0.map(\.d).max() ?? 0 }.reduce(0, +)
            completions.append(DayScore.completion(contracts: dayContracts, done: done, fill: fill,
                                                   isPlannedRest: rest[day] ?? false))
            dayActions.append(acts)
        }

        let history = Array(completions.dropLast())
        let todayPresence = completions.last ?? 0
        state.todayCompletion = todayPresence
        state.ascent = Ascent.value(completions: completions)
        state.vitality = Vitality.value(history: history, today: todayPresence)
        state.comebackActive = isComeback(history: history, today: todayPresence)
        state.activeDays = dayActions.filter { !$0.isEmpty }.count
        for p in Pillar.allCases {
            let d = Depth.total(days: dayActions, pillar: p)
            if d > 0 { state.depth[p] = d }
        }
        let recent = dayActions.suffix(28).flatMap { $0 }
        let mixTotal = Pillar.allCases.map { p in recent.reduce(0) { $0 + $1.contribution(to: p) } }
        let sum = mixTotal.reduce(0, +)
        if sum > 0 { for p in Pillar.allCases where mixTotal[p.rawValue] > 0 { state.recentMix[p] = mixTotal[p.rawValue] / sum } }
        state.todayPlan = (contracts[today] ?? []).last ?? []    // the latest contract (after a swap) is what Today shows
        state.completedToday = Set((actions[today] ?? []).map(\.occurrenceKey))
        state.completedEver = Set(actions.values.flatMap { $0.map(\.occurrenceKey) })
        return state
    }

    /// A correction voids its target unless the correction itself is voided (undo of undo).
    static func effectiveVoids(_ entries: [Entry]) -> Set<UUID> {
        var targets: [UUID: [UUID]] = [:]   // target → corrections targeting it
        for e in entries { if case .correctionVoid(let t) = e.payload { targets[t, default: []].append(e.id) } }
        var memo: [UUID: Bool] = [:]
        func isVoided(_ id: UUID, depth: Int = 0) -> Bool {
            if let m = memo[id] { return m }
            guard depth < 64 else { return false }
            let r = (targets[id] ?? []).contains { !isVoided($0, depth: depth + 1) }
            memo[id] = r
            return r
        }
        return Set(entries.map(\.id).filter { isVoided($0) })
    }

    static func isComeback(history: [Double], today: Double) -> Bool {
        var nFin = 0, k = history.count - 1
        while k >= 0 && history[k] > 0 { nFin += 1; k -= 1 }
        var absence = 0
        while k >= 0 && history[k] == 0 { absence += 1; k -= 1 }
        return absence >= RuleSetV1.absenceForComeback && nFin <= 3 && (nFin >= 1 || today > 0)
    }
}
