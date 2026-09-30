import Foundation
import Observation
import Domain
import Storage

/// What Today shows for one slot.
struct DayCard: Identifiable, Equatable {
    let id: String            // occurrence key
    let pillar: Pillar
    let label: String         // "Body" / "Spark · Heart"
    let title: String
    let detail: String
    let isSpark: Bool
    let done: Bool
}

/// The outcome of a completion, for the tracking moment.
struct CompletionOutcome {
    let entryId: UUID
    let pillar: Pillar
    let gainPercent: Double
    let dayComplete: Bool
    let comeback: Bool
    let isSpark: Bool
}

@Observable
final class AppModel {
    private let store: RecordStore
    private(set) var entries: [Entry] = []
    private(set) var state: DerivedState
    private(set) var devOffset: TimeInterval

    init() {
        store = (try? RecordStore.onDevice()) ?? (try! RecordStore.inMemory())
        devOffset = UserDefaults.standard.double(forKey: "dev.offset")
        let settings = EngineSettings(timeZone: .current)
        state = GrowthEngine.compute(entries: [], asOf: .now, settings: settings)
        reload()
        // Simulator testing only: `-demoBirth` fast-forwards through the birth (never used on device).
        if ProcessInfo.processInfo.arguments.contains("-demoBirth") && !isBorn {
            witnessBirth()
            chooseFirstPath(Catalog.paths[0])
            if let first = cards.first(where: { $0.id == Catalog.firstSparkKey }) { _ = complete(first) }
        }
    }

    var now: Date { Date().addingTimeInterval(devOffset) }
    var settings: EngineSettings { EngineSettings(timeZone: .current) }
    var isBorn: Bool { entries.contains { if case .flameBorn = $0.payload { true } else { false } } }
    var seed: String { entries.compactMap { if case .flameBorn(let s) = $0.payload { s } else { nil } }.first ?? "seed" }
    var sparkUnlocked: Bool { state.daysSinceBirth >= 1 }
    var journeyStep: Int { sparkUnlocked ? 1 : 0 }          // index into Catalog.journey

    // MARK: record

    func reload() {
        entries = (try? store.allEntries()) ?? []
        state = GrowthEngine.compute(entries: entries, asOf: now, settings: settings)
    }

    @discardableResult
    private func append(_ payload: Payload, at date: Date? = nil) -> Entry {
        let e = Entry.make(payload, at: date ?? now, settings: settings)
        try? store.append(e)
        return e
    }

    // MARK: the birth

    func witnessBirth() {
        guard !isBorn else { return }
        let seed = String(UInt64.random(in: .min ... .max), radix: 16) + String(UInt64.random(in: .min ... .max), radix: 16)
        append(.flameBorn(seed: seed))
        reload()
    }

    func chooseFirstPath(_ template: PathTemplate) {
        append(.pathStarted(pathId: "path-\(template.id)", templateId: template.id, pillar: template.pillar))
        let path = PlannedSlot(occurrenceKey: Dealer.pathKey("path-\(template.id)", state.today),
                               pillarWeights: [template.pillar: 1], d: 1, isSpark: false)
        let first = PlannedSlot(occurrenceKey: Catalog.firstSparkKey, pillarWeights: [.spirit: 1], d: 1, isSpark: true)
        append(.dayPlanned(isPlannedRest: false, slots: [path, first]))
        reload()
    }

    // MARK: your day

    var activePaths: [ActivePath] { Dealer.activePaths(entries) }

    func dealTodayIfNeeded() {
        guard isBorn else { return }
        reload()
        let today = state.today
        let alreadyDealt = entries.contains {
            if case .dayPlanned = $0.payload { $0.livedDay == today } else { false }
        }
        guard !alreadyDealt else { return }
        let slots = Dealer.plan(day: today, paths: activePaths, sparks: Catalog.sparkCandidates, seed: seed,
                                sparkUnlocked: sparkUnlocked, recentlyDealt: recentlyDealtSparks())
        append(.dayPlanned(isPlannedRest: false, slots: slots))
        reload()
    }

    private func recentlyDealtSparks() -> Set<String> {
        let horizon = state.today.adding(days: -30)
        var ids = Set<String>()
        for e in entries where e.livedDay >= horizon {
            if case .dayPlanned(_, let slots) = e.payload {
                for s in slots where s.isSpark { ids.insert(String(s.occurrenceKey.split(separator: ":").last ?? "")) }
            }
        }
        return ids
    }

    var cards: [DayCard] {
        state.todayPlan.map { slot in
            let pillar = slot.pillarWeights.max { $0.value < $1.value }?.key ?? .body
            let done = state.completedToday.contains(slot.occurrenceKey)
            if slot.occurrenceKey == Catalog.firstSparkKey {
                return DayCard(id: slot.occurrenceKey, pillar: pillar, label: "Your first spark", title: Catalog.firstSpark.title,
                               detail: Catalog.firstSpark.detail, isSpark: true, done: done)
            }
            if slot.isSpark {
                let id = String(slot.occurrenceKey.split(separator: ":").last ?? "")
                let text = Catalog.spark(id)?.text ?? "Today's Spark"
                return DayCard(id: slot.occurrenceKey, pillar: pillar, label: "Spark · \(pillar.name)", title: text,
                               detail: "Your edge today", isSpark: true, done: done)
            }
            let pathId = slot.occurrenceKey.split(separator: ":").dropFirst().first.map(String.init) ?? ""
            let template = activePaths.first { $0.pathId == pathId }.flatMap { Catalog.path($0.templateId) }
            return DayCard(id: slot.occurrenceKey, pillar: pillar, label: pillar.name, title: template?.stepTitle ?? "Your Path",
                           detail: template?.stepDetail ?? "", isSpark: false, done: done)
        }
    }

    var sparkSwapUsed: Bool {
        entries.filter { if case .dayPlanned = $0.payload { $0.livedDay == state.today } else { false } }.count > 1
    }

    func swapSpark() {
        guard !sparkSwapUsed, let current = state.todayPlan.first(where: \.isSpark),
              !state.completedToday.contains(current.occurrenceKey) else { return }
        let currentId = String(current.occurrenceKey.split(separator: ":").last ?? "")
        guard let next = Dealer.pickSpark(day: state.today, paths: activePaths, sparks: Catalog.sparkCandidates,
                                          seed: seed, recentlyDealt: recentlyDealtSparks(), excluding: [currentId])
        else { return }
        let slots = state.todayPlan.filter { !$0.isSpark } +
            [PlannedSlot(occurrenceKey: Dealer.sparkKey(next.id, state.today), pillarWeights: [next.pillar: 1],
                         d: Dealer.sparkStretch, isSpark: true)]
        append(.dayPlanned(isPlannedRest: false, slots: slots))
        reload()
    }

    func complete(_ card: DayCard) -> CompletionOutcome? {
        guard let slot = state.todayPlan.first(where: { $0.occurrenceKey == card.id }),
              !state.completedToday.contains(card.id) else { return nil }
        let before = state
        let e = append(.actionCompleted(occurrenceKey: slot.occurrenceKey, pillarWeights: slot.pillarWeights,
                                        d: slot.d, isSpark: slot.isSpark))
        reload()
        let comeback = state.comebackActive && before.completedToday.isEmpty && before.vitality < 0.5
        return CompletionOutcome(entryId: e.id, pillar: card.pillar,
                                 gainPercent: (state.ascent / before.ascent - 1) * 100,
                                 dayComplete: before.todayCompletion < 1 && state.todayCompletion >= 1,
                                 comeback: comeback, isSpark: slot.isSpark)
    }

    func undo(_ entryId: UUID) {
        append(.correctionVoid(targetId: entryId))
        reload()
    }

    /// Ascent at the end of yesterday, for "Close the day".
    var ascentYesterday: Double { state.ascent / (1 + 0.01 * state.todayCompletion) }

    // MARK: developer tools (time travel, reset), hidden behind a long press on the date

    func devAdvance(days: Int) {
        devOffset += Double(days) * 86_400
        UserDefaults.standard.set(devOffset, forKey: "dev.offset")
        dealTodayIfNeeded()
    }

    func devResetTime() {
        devOffset = 0
        UserDefaults.standard.set(0.0, forKey: "dev.offset")
        dealTodayIfNeeded()
    }

    func devDeleteEverything() {
        try? store.deleteEverything()
        devResetTime()
        reload()
    }
}
