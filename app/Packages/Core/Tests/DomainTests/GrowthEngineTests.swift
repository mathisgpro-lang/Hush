import Foundation
import Testing
@testable import Domain

struct GrowthEngineTests {
    let paris = TimeZone(identifier: "Europe/Paris")!
    var settings: EngineSettings { EngineSettings(timeZone: paris, boundary: .default) }

    private func entry(_ payload: Payload, at iso: String, id: UUID = UUID()) -> Entry {
        let t = utc(iso)
        return Entry(id: id, occurredAt: t, recordedAt: t, timeZone: paris.identifier,
                     livedDay: LivedDayRule.livedDay(at: t, in: paris), payload: payload)
    }

    private let walk = PlannedSlot(occurrenceKey: "walk", pillarWeights: [.body: 1], d: 1, isSpark: false)
    private let read = PlannedSlot(occurrenceKey: "read", pillarWeights: [.mind: 1], d: 1, isSpark: false)

    @Test func aNewbornFlameIsBrightAndAtOne() {
        let s = GrowthEngine.compute(entries: [entry(.flameBorn(seed: "abc"), at: "2026-10-01T07:00:00Z")],
                                     asOf: utc("2026-10-01T08:00:00Z"), settings: settings)
        expectClose(s.ascent, 1.0)
        expectClose(s.vitality, 1.0)
        #expect(s.daysSinceBirth == 0)
    }

    @Test func completingHalfTheDayEarnsHalfAPercentToday() {
        let entries = [
            entry(.flameBorn(seed: "abc"), at: "2026-10-01T07:00:00Z"),
            entry(.dayPlanned(isPlannedRest: false, slots: [walk, read]), at: "2026-10-01T07:01:00Z"),
            entry(.actionCompleted(occurrenceKey: "walk", pillarWeights: [.body: 1], d: 1, isSpark: false), at: "2026-10-01T08:00:00Z"),
        ]
        let s = GrowthEngine.compute(entries: entries, asOf: utc("2026-10-01T09:00:00Z"), settings: settings)
        expectClose(s.todayCompletion, 0.5)
        expectClose(s.ascent, 1.005)
        #expect(s.completedToday == ["walk"])
        expectClose(s.depth[.body] ?? 0, 1.0)
    }

    @Test func undoVoidsTheCompletionAndUndoingTheUndoRestoresIt() {
        let done = UUID(), undo = UUID()
        var entries = [
            entry(.flameBorn(seed: "abc"), at: "2026-10-01T07:00:00Z"),
            entry(.dayPlanned(isPlannedRest: false, slots: [walk]), at: "2026-10-01T07:01:00Z"),
            entry(.actionCompleted(occurrenceKey: "walk", pillarWeights: [.body: 1], d: 1, isSpark: false), at: "2026-10-01T08:00:00Z", id: done),
            entry(.correctionVoid(targetId: done), at: "2026-10-01T08:00:03Z", id: undo),
        ]
        var s = GrowthEngine.compute(entries: entries, asOf: utc("2026-10-01T09:00:00Z"), settings: settings)
        expectClose(s.ascent, 1.0)
        entries.append(entry(.correctionVoid(targetId: undo), at: "2026-10-01T08:01:00Z"))
        s = GrowthEngine.compute(entries: entries, asOf: utc("2026-10-01T09:00:00Z"), settings: settings)
        expectClose(s.ascent, 1.01)
    }

    @Test func daysAwayDimTheFlameAndTheComebackRelightsIt() {
        var entries = [entry(.flameBorn(seed: "abc"), at: "2026-09-01T07:00:00Z")]
        // live fully for 14 days
        for day in 1...14 {
            let iso = String(format: "2026-09-%02dT08:00:00Z", day)
            entries.append(entry(.actionCompleted(occurrenceKey: "w\(day)", pillarWeights: [.body: 1], d: 2, isSpark: false), at: iso))
        }
        // away from 15 Sep to 30 Sep, check on 1 Oct morning
        let away = GrowthEngine.compute(entries: entries, asOf: utc("2026-10-01T06:00:00Z"), settings: settings)
        expectClose(away.vitality, 0.15)
        entries.append(entry(.actionCompleted(occurrenceKey: "back", pillarWeights: [.body: 1], d: 2, isSpark: false), at: "2026-10-01T07:00:00Z"))
        let back = GrowthEngine.compute(entries: entries, asOf: utc("2026-10-01T07:05:00Z"), settings: settings)
        expectClose(back.vitality, 0.60)
        #expect(back.comebackActive)
    }

    @Test func theSameEntriesInAnyOrderGiveTheSameState() {
        var entries = [
            entry(.flameBorn(seed: "abc"), at: "2026-10-01T07:00:00Z"),
            entry(.dayPlanned(isPlannedRest: false, slots: [walk, read]), at: "2026-10-01T07:01:00Z"),
            entry(.actionCompleted(occurrenceKey: "walk", pillarWeights: [.body: 1], d: 1, isSpark: false), at: "2026-10-01T08:00:00Z"),
            entry(.actionCompleted(occurrenceKey: "read", pillarWeights: [.mind: 1], d: 1, isSpark: false), at: "2026-10-02T08:00:00Z"),
        ]
        let asOf = utc("2026-10-03T09:00:00Z")
        let a = GrowthEngine.compute(entries: entries, asOf: asOf, settings: settings)
        entries.reverse()
        let b = GrowthEngine.compute(entries: entries, asOf: asOf, settings: settings)
        #expect(a == b)
    }
}
