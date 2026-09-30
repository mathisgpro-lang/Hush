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
    /// The permanent record on the phone. Never silently replaced by anything else (Codex code review).
    private let realStore: RecordStore?
    /// Time-travel testing happens in a throwaway copy, never in the real record.
    private var sandbox: RecordStore?
    private var store: RecordStore? { sandbox ?? realStore }
    private(set) var entries: [Entry] = []
    private(set) var state: DerivedState
    private(set) var devOffset: TimeInterval = 0
    /// Set when the record can't be read or written; the UI shows it and nothing pretends to succeed.
    private(set) var storageProblem: String?
    var inSandbox: Bool { sandbox != nil }

    init() {
        do { realStore = try RecordStore.onDevice() } catch {
            realStore = nil
            storageProblem = "Your record couldn't be opened, so nothing is being saved right now. Your history is safe on the phone; please restart the app."
        }
        let settings = EngineSettings(timeZone: .current)
        state = GrowthEngine.compute(entries: [], asOf: .now, settings: settings)
        reload()
        // Simulator testing only: `-demoBirth` fast-forwards through the birth (never used on device).
        if ProcessInfo.processInfo.arguments.contains("-demoBirth") && !isBorn {
            witnessBirth()
            chooseFirstPath(Catalog.paths[0])
            if let first = cards.first(where: { $0.id == Catalog.firstSparkKey }) { _ = complete(first) }
        }
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-demoAdvance"), i + 1 < args.count, let n = Int(args[i + 1]) { devAdvance(days: n) }
        // Simulator testing only: `-demoLive N` lives N more days, completing every card each day.
        if let i = args.firstIndex(of: "-demoLive"), i + 1 < args.count, let n = Int(args[i + 1]) {
            for _ in 0..<n {
                devAdvance(days: 1)
                for card in cards where !card.done { _ = complete(card) }
            }
            if args.contains("-demoWitness"), let step = pendingUnlock { witnessUnlock(step) }
            if args.contains("-demoForged"), forgeReady { witnessForge() }
        }
    }

    var now: Date { Date().addingTimeInterval(devOffset) }
    var settings: EngineSettings { EngineSettings(timeZone: .current) }
    var isBorn: Bool { entries.contains { if case .flameBorn = $0.payload { true } else { false } } }
    var seed: String { entries.compactMap { if case .flameBorn(let s) = $0.payload { s } else { nil } }.first ?? "seed" }
    var sparkUnlocked: Bool { journeyStep >= 1 }
    var ownsMetal: Bool { state.witnessed.contains("milestone:stage-2") }
    /// First Journey step (index into Catalog.journey); opens by living (Domain.Journey).
    var journeyStep: Int {
        Journey.step(daysSinceBirth: state.daysSinceBirth, activeDays: state.activeDays, ownsMetal: ownsMetal)
    }
    /// The newest step not yet celebrated, if any (the Forge has its own ceremony).
    var pendingUnlock: Int? {
        let step = journeyStep
        guard step > 0, step < 5, !state.witnessed.contains("journey:\(step)") else { return nil }
        return step
    }

    // MARK: Eras and the Forge (chapter 03 §A.4, step VI)

    var era: Int { ownsMetal ? 2 : 1 }
    /// Earned and not yet witnessed: the ceremony plays, then the Metal Era is owned forever.
    var forgeReady: Bool {
        !ownsMetal && Journey.metalEligible(activeDays: state.activeDays, totalDepth: state.totalDepth)
    }
    func witnessForge() {
        append(.momentWitnessed(key: "milestone:stage-2"))
        for s in 1...5 where !state.witnessed.contains("journey:\(s)") { append(.momentWitnessed(key: "journey:\(s)")) }
        reload()
    }
    func witnessUnlock(_ step: Int) {
        for s in 1...step where !state.witnessed.contains("journey:\(s)") { append(.momentWitnessed(key: "journey:\(s)")) }
        reload()
    }

    // MARK: record

    func reload() {
        if let store {
            do { entries = try store.allEntries() } catch {
                storageProblem = "Your record couldn't be read just now. Nothing was lost; please restart the app."
            }
        }
        state = GrowthEngine.compute(entries: entries, asOf: now, settings: settings)
    }

    /// Writes one entry. Returns nil (and surfaces the problem) if it couldn't be saved: never a false success.
    @discardableResult
    private func append(_ payload: Payload, at date: Date? = nil) -> Entry? {
        guard let store else { return nil }
        let e = Entry.make(payload, at: date ?? now, settings: settings)
        do { try store.append(e) } catch {
            storageProblem = "That couldn't be saved. Please try again."
            return nil
        }
        return e
    }

    /// If the lived day changed while the app stayed open (e.g. across 04:00), move to the new day
    /// before any action, so yesterday's cards can never be credited to today (Codex code review).
    func refreshDay() {
        let today = LivedDayRule.livedDay(at: now, in: settings.timeZone, boundary: settings.boundary)
        if today != state.today { dealTodayIfNeeded() }
    }

    // MARK: onboarding (the birth can be interrupted and resumed)

    var firstSparkDone: Bool { state.completedEver.contains(Catalog.firstSparkKey) }
    var firstSparkStillToday: Bool { state.todayPlan.contains { $0.occurrenceKey == Catalog.firstSparkKey } }
    var onboarded: Bool { isBorn && !activePaths.isEmpty && (firstSparkDone || !firstSparkStillToday) }

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
        var slots = Dealer.plan(day: today, paths: activePaths, sparks: Catalog.sparkCandidates, seed: seed,
                                sparkUnlocked: sparkUnlocked, recentlyDealt: recentlyDealtSparks())
        if sparkUnlocked, let hidden = eligibleHiddenSpark(on: today) {
            slots.removeAll(where: \.isSpark)
            slots.append(PlannedSlot(occurrenceKey: Dealer.sparkKey(hidden.id, today), pillarWeights: [hidden.pillar: 1],
                                     d: Dealer.sparkStretch, isSpark: true))
        }
        append(.dayPlanned(isPlannedRest: false, slots: slots))
        reload()
    }

    /// A Hidden Spark arrives about once a week when a pillar is deep enough, and never twice (chapter 28 §B.1).
    private func eligibleHiddenSpark(on day: LocalDate) -> SparkContent? {
        guard Dealer.fnv1a("\(seed)|hidden|\(day)") % 7 == 0 else { return nil }
        let everDealt = recentlyDealtSparks(allTime: true)
        return Catalog.hiddenSparks.first { (state.depth[$0.spark.pillar] ?? 0) >= $0.minDepth && !everDealt.contains($0.spark.id) }?.spark
    }

    func isHidden(_ card: DayCard) -> Bool { card.id.contains(":x-") }

    private func recentlyDealtSparks(allTime: Bool) -> Set<String> {
        let horizon = allTime ? LocalDate(year: 1, month: 1, day: 1) : state.today.adding(days: -30)
        var ids = Set<String>()
        for e in entries where e.livedDay >= horizon {
            if case .dayPlanned(_, let slots) = e.payload {
                for s in slots where s.isSpark { ids.insert(String(s.occurrenceKey.split(separator: ":").last ?? "")) }
            }
        }
        return ids
    }

    private func recentlyDealtSparks() -> Set<String> { recentlyDealtSparks(allTime: false) }

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
                let text = Catalog.anySpark(id)?.text ?? "Today's Spark"
                let hidden = id.hasPrefix("x-")
                return DayCard(id: slot.occurrenceKey, pillar: pillar, label: hidden ? "Hidden Spark · \(pillar.name)" : "Spark · \(pillar.name)",
                               title: text, detail: hidden ? "It appeared because you've grown" : "Your edge today", isSpark: true, done: done)
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
        refreshDay()
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
        refreshDay()
        guard let slot = state.todayPlan.first(where: { $0.occurrenceKey == card.id }),
              !state.completedToday.contains(card.id) else { return nil }
        let before = state
        guard let e = append(.actionCompleted(occurrenceKey: slot.occurrenceKey, pillarWeights: slot.pillarWeights,
                                              d: slot.d, isSpark: slot.isSpark)) else { return nil }
        reload()
        let comebackKey = "comeback:\(state.today)"
        let comeback = state.comebackActive && before.completedToday.isEmpty && !state.witnessed.contains(comebackKey)
        if comeback { append(.momentWitnessed(key: comebackKey)); reload() }
        return CompletionOutcome(entryId: e.id, pillar: card.pillar,
                                 gainPercent: (state.ascent / before.ascent - 1) * 100,
                                 dayComplete: before.todayCompletion < 1 && state.todayCompletion >= 1,
                                 comeback: comeback, isSpark: slot.isSpark)
    }

    // MARK: the Ritual (step III)

    var week: String { Journey.isoWeek(state.today) }
    var ritual: SparkContent { Catalog.ritual(forWeek: week) }
    var ritualKey: String { "ritual:\(week)" }
    var ritualDone: Bool { state.completedEver.contains(ritualKey) }
    var ritualCard: DayCard? {
        guard journeyStep >= 2 else { return nil }
        return DayCard(id: ritualKey, pillar: ritual.pillar, label: "Ritual · Week \(week.suffix(2))",
                       title: ritual.text, detail: "Everyone, this week", isSpark: false, done: ritualDone)
    }

    func completeRitual() -> CompletionOutcome? {
        refreshDay()
        guard !ritualDone else { return nil }
        let before = state
        guard let e = append(.actionCompleted(occurrenceKey: ritualKey, pillarWeights: [ritual.pillar: 1], d: 1, isSpark: false)) else { return nil }
        reload()
        return CompletionOutcome(entryId: e.id, pillar: ritual.pillar, gainPercent: (state.ascent / before.ascent - 1) * 100,
                                 dayComplete: before.todayCompletion < 1 && state.todayCompletion >= 1,
                                 comeback: false, isSpark: false)
    }

    // MARK: Paths (step IV)

    var canAddPath: Bool { journeyStep >= 3 && activePaths.count < Dealer.maxPaths }
    var availablePaths: [PathTemplate] {
        let active = Set(activePaths.map(\.templateId))
        return Catalog.paths.filter { !active.contains($0.id) }
    }
    /// A new Path starts tomorrow: today's contract never changes (decision 58).
    func addPath(_ template: PathTemplate) {
        guard canAddPath else { return }
        append(.pathStarted(pathId: "path-\(template.id)", templateId: template.id, pillar: template.pillar))
        reload()
    }

    // MARK: the Chronicle (step V), derived from the record, written in the Sanctuary's voice

    func chronicle(weeksAgo: Int = 1) -> String? {
        guard journeyStep >= 4 else { return nil }
        let end = state.today.adding(days: -7 * (weeksAgo - 1) - 1)
        let start = end.adding(days: -6)
        let weekEntries = GrowthEngine.effectiveEntries(entries).filter { $0.livedDay >= start && $0.livedDay <= end }
        var perPillar: [Pillar: Int] = [:]
        var days = Set<LocalDate>()
        var seen = Set<String>()
        for e in weekEntries {
            if case .actionCompleted(let key, let w, _, _) = e.payload, seen.insert(key).inserted {
                days.insert(e.livedDay)
                if let p = w.max(by: { $0.value < $1.value })?.key { perPillar[p, default: 0] += 1 }
            }
        }
        let week = Journey.isoWeek(end).replacingOccurrences(of: "-W", with: ", week ")
        guard !days.isEmpty else { return "\(week). The embers held, waiting. The fire remembers." }
        let top = perPillar.sorted { $0.value > $1.value }
        let lines = top.prefix(3).map { p, n in "\(p.name): \(n) \(n == 1 ? "spark" : "sparks")" }
        let mood = days.count >= 6 ? "You showed up almost every day." : days.count >= 3 ? "You kept the fire fed." : "A few sparks, and they count."
        let lead = top.first.map { "Your vessel carries new lines of \($0.key.name.lowercased())." } ?? ""
        return "\(week). \(mood) \(lines.joined(separator: " · ")). \(lead)"
    }

    func undo(_ entryId: UUID) {
        append(.correctionVoid(targetId: entryId))
        reload()
    }

    /// Ascent at the end of yesterday, for "Close the day".
    var ascentYesterday: Double { state.ascent / (1 + 0.01 * state.todayCompletion) }

    // MARK: developer tools (time travel, reset), hidden behind a long press on the date

    func devAdvance(days: Int) {
        if sandbox == nil, let copy = try? RecordStore.inMemory() {
            for e in entries { try? copy.append(e) }
            sandbox = copy
        }
        devOffset += Double(days) * 86_400
        dealTodayIfNeeded()
    }

    /// Leaves the simulation: the real record was never touched.
    func devResetTime() {
        devOffset = 0
        sandbox = nil
        reload()
        dealTodayIfNeeded()
    }

    func devDeleteEverything() {
        try? store?.deleteEverything()
        if sandbox == nil { devOffset = 0 }
        reload()
    }
}
