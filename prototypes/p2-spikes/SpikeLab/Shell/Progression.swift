// The streak at the core, and numbers that climb (decision 134, from the Life Reset study). Everything here is
// calculated from what you've really lived (the deeds): nothing is stored that could drift or be lost, so a streak can
// never vanish to a bug (Life Reset's most-hated failure).
//
// The protected streak:
//  - every day you live one real quest, the streak grows by one;
//  - shields are earned by living (one per 7 days in a row, at most 2), never bought: a missed day uses one, and the
//    streak carries on;
//  - with no shield, a missed day can still be repaired the next day by living two quests;
//  - otherwise it starts again from 1. A broken streak only dims your Spark's brightness; it never touches what you've
//    built (Depth, the worlds, the Book).
import Foundation

enum StreakState: Equatable {
    case livedToday                    // today counts already
    case waiting                       // not yet today: still alive until midnight
    case shieldedYesterday             // yesterday was missed, a shield caught it
    case repairable(need: Int)         // yesterday was missed: live `need` more today to save it
    case broken                        // it ended; it starts again with your next quest
}

struct StreakStatus {
    var current = 0
    var best = 0
    var shields = 0
    var state: StreakState = .waiting
    /// The streak just reached one of these (a celebration in the world, a page in the Book).
    static let milestones = [3, 7, 14, 30, 66, 100, 365]
}

enum Pillar6: String, CaseIterable {
    case body = "Body", mind = "Mind", heart = "Heart", spirit = "Spirit", craft = "Craft", world = "World"
    var realm: RealmID {
        switch self { case .body: .highlands; case .mind: .library; case .heart: .grove; case .spirit: .stillwater; case .craft: .forge; case .world: .wilds }
    }
    static func of(_ r: RealmID) -> Pillar6 {
        switch r { case .highlands: .body; case .library: .mind; case .stillwater: .spirit; case .forge: .craft; case .wilds: .world; default: .heart }
    }
    var attribute: String {       // the number that climbs, Life Reset-style, named for what it builds
        switch self { case .body: "Strength"; case .mind: "Wisdom"; case .heart: "Warmth"; case .spirit: "Calm"; case .craft: "Focus"; case .world: "Care" }
    }
}

/// The Flame's forms (decision 152, Mathis's notes): each is reached by the streak (your best streak, so a form is
/// never taken away; a broken streak only dims the Flame). Once reached, you can choose to show any of them.
enum Evolution: Int, CaseIterable, Identifiable {
    case spark, flame, blaze, kindled, radiant, beyond
    var id: Int { rawValue }
    var name: String { ["Spark", "Flame", "Blaze", "Kindled", "Radiant", "Beyond"][rawValue] }
    var days: Int { [0, 3, 7, 14, 30, 90][rawValue] }
    /// The sprite's base name (pixel art: <base>-keyed/-blink/-happy.png).
    var base: String { "depth-" + name.lowercased() }
    /// How tall it stands next to the Spark.
    var growth: Float { [1, 1.18, 1.32, 1.44, 1.55, 1.66][rawValue] }
    /// The art is in the app (Codex paints them one by one).
    var available: Bool { Bundle.main.url(forResource: base + "-keyed", withExtension: "png") != nil }
    static func reached(best: Int) -> Evolution { allCases.last { $0.days <= best } ?? .spark }
    /// For now (Mathis, 2026-10-13): every form can be chosen in Your Flame, whatever the streak. Turn off for launch.
    static let allOpen = true
    var next: Evolution? { Evolution(rawValue: rawValue + 1) }
}

enum Progression {

    /// XP for one quest: more for longer ones, a little more while your streak is alive (up to +50% at 30 days).
    static func xp(minutes: Int, streak: Int) -> Int {
        let base = 10 + max(1, minutes) * 2
        return Int((Double(base) * (1 + Double(min(streak, 30)) / 60)).rounded())
    }

    /// Level from total XP: level 2 at 100, 3 at 300, 4 at 600, 5 at 1,000… (gentle at first, then slower).
    static func level(xp: Int) -> (level: Int, into: Int, span: Int) {
        var n = 1
        while 50 * n * (n + 1) <= xp { n += 1 }
        let start = 50 * (n - 1) * n, end = 50 * n * (n + 1)
        return (n, xp - start, end - start)
    }

    /// The streak, walked day by day through what you've lived.
    static func streak(deeds: [Deed], now: Date = Date(), calendar cal: Calendar = .current) -> StreakStatus {
        var perDay: [Date: Int] = [:]
        for d in deeds { perDay[cal.startOfDay(for: d.date), default: 0] += 1 }
        guard let first = perDay.keys.min() else { return StreakStatus() }
        let today = cal.startOfDay(for: now)
        var s = StreakStatus()
        var pendingMiss = false
        var day = first
        while day <= today {
            let n = perDay[day] ?? 0
            let isToday = day == today
            if n > 0 {
                if pendingMiss {
                    if n >= 2 { pendingMiss = false; s.current += 1 }             // repaired
                    else if isToday { s.state = .repairable(need: 1); s.current += 0; break }
                    else { pendingMiss = false; s.current = 1 }                   // not repaired: begins again
                } else {
                    s.current += 1
                }
                if s.current > 0 && s.current % 7 == 0 && !pendingMiss { s.shields = min(2, s.shields + 1) }
                s.best = max(s.best, s.current)
                s.state = isToday ? .livedToday : .waiting
            } else if !isToday {
                if pendingMiss { s.current = 0; pendingMiss = false; s.state = .broken }      // two missed days
                else if s.current > 0 {
                    if s.shields > 0 { s.shields -= 1; s.state = .shieldedYesterday }          // a shield catches it
                    else { pendingMiss = true }
                }
            } else {
                // Today, nothing yet.
                if pendingMiss { s.state = .repairable(need: 2) }
                else if s.state == .shieldedYesterday { }                                      // keep the message
                else if s.current > 0 { s.state = .waiting } else { s.state = .broken }
            }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return s
    }

    /// How many days in a row this quest has been done (its own small streak, "9d" on its card).
    static func questStreak(title: String, deeds: [Deed], now: Date = Date(), calendar cal: Calendar = .current) -> Int {
        let days = Set(deeds.filter { $0.title == title }.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: now)
        if !days.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day)! }   // today not done yet: count to yesterday
        var n = 0
        while days.contains(day) { n += 1; day = cal.date(byAdding: .day, value: -1, to: day)! }
        return n
    }
}

/// The Flame's vitality stages (P3.2 step 3): how much light it has, from the days since you last lived a quest.
enum Vitality: Int, CaseIterable {
    case full, dimmed, faded, almostOut
    /// 1 day away: a first loss; 3 days: a second; 7 days: almost all lost (never zero).
    static func after(daysAway d: Int) -> Vitality { d >= 7 ? .almostOut : d >= 3 ? .faded : d >= 1 ? .dimmed : .full }
    /// How much light, 0…1 (what the world and the Flame will show).
    var light: Float { [1.0, 0.7, 0.4, 0.12][rawValue] }
}

