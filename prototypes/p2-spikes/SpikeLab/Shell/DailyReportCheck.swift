// The daily screen's numbers, proved (decision 183): `-dailycheck` runs DailyReport over made-up histories, prints
// DAILYCHECK PASS / FAIL for each case and quits. Nothing here touches your real progress.
import Foundation

enum DailyReportCheck {
    private static var failures = 0

    static func runIfAsked() {
        guard CommandLine.arguments.contains("-dailycheck") else { return }
        run()
        print("DAILYCHECK DONE failures=\(failures)")
        exit(failures == 0 ? 0 : 1)
    }

    private static func expect<T: Equatable>(_ name: String, _ got: T, _ want: T) {
        if got == want { print("DAILYCHECK PASS \(name)") }
        else { failures += 1; print("DAILYCHECK FAIL \(name): got \(got), want \(want)") }
    }

    /// Made-up histories for showing each version of the daily screen (test flags `-welcomestate <name>`, `-welcomelit`,
    /// `-welcomeform`): alive (12 days, today waiting), kept (13, today lived), shield, repair, comeback, first, allforms,
    /// and almostform (13 days, Kindled waiting for today's quest).
    static func sample(_ name: String, now: Date = Date()) -> [Deed] {
        let cal = Calendar.current
        func lived(_ days: [Int], realm: RealmID = .highlands, xp: Int = 30) -> [Deed] {
            days.map { Deed(date: cal.date(byAdding: .day, value: -$0, to: now)!, realm: realm.rawValue, title: "q", xp: xp) }
        }
        switch name {
        case "kept": return lived(Array(1...12)) + lived([0], realm: .stillwater)
        case "shield": return lived(Array(2...12))
        case "repair": return lived(Array(2...5))
        case "comeback": return lived(Array(4...15))
        case "first": return []
        case "allforms": return lived(Array(1...95))
        case "almostform": return lived(Array(1...13))
        case "formkept": return lived(Array(1...13)) + lived([0], realm: .stillwater)
        default:   // alive: 12 days after an older 10-day streak (best 12, a shield), Level 4 crossed no level this week
            return lived(Array(16...25), xp: 50) + lived(Array(8...12)) + lived(Array(1...7), realm: .stillwater)
        }
    }

    static func run() {
        let cal = Calendar.current
        // A Friday at noon: Monday to Thursday are behind it, Saturday and Sunday ahead.
        let now = cal.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 12))!
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        func lived(_ days: [Int], realm: RealmID = .highlands, xp: Int = 30) -> [Deed] {
            days.map { Deed(date: ago($0), realm: realm.rawValue, title: "q", xp: xp) }
        }
        func report(_ deeds: [Deed]) -> DailyReport { DailyReport.make(deeds: deeds, now: now, calendar: cal) }

        // 1. Alive: twelve days in a row, today not yet lived.
        var r = report(lived(Array(1...12)))
        expect("alive streak", r.streak, 12)
        expect("alive story", r.story, .waiting)
        expect("alive line", r.line, "12 days in a row. Today makes it 13.")
        expect("alive shields", r.shields, 1)
        expect("alive week", r.week, [.lived, .lived, .lived, .lived, .today, .future, .future])
        expect("alive next form", r.nextForm, .kindled)
        expect("alive form title", r.form.title, "Kindled in 2 days")
        expect("alive form detail", r.form.detail, "12 / 14")
        expect("alive form bar now", (r.form.now * 1000).rounded(), (12.0 / 14 * 1000).rounded())
        expect("alive form ghost", (r.form.before * 1000).rounded(), (6.0 / 14 * 1000).rounded())   // a week ago: 6 days
        expect("alive level", r.level.title, "Level 3")
        expect("alive level badge", r.level.badge, "+1 level")
        expect("alive level ghost", r.level.before, 0)
        expect("alive level detail", r.level.detail, "+180 XP this week")
        expect("alive skill", r.skill.title, "Strength · level 4")
        expect("alive skill detail", r.skill.detail, "+1 level this week")
        expect("alive quote", r.quote.isEmpty, false)

        // 2. Kept: the same, and today's first quest is done.
        r = report(lived(Array(0...12)))
        expect("kept streak", r.streak, 13)
        expect("kept story", r.story, .kept)
        expect("kept week today", r.week[4], .todayLit)
        expect("kept line", r.line, "13 days in a row. Kindled tomorrow.")
        expect("kept form title", r.form.title, "Kindled tomorrow")

        // 2b. One day from a form with today still open: it comes today.
        r = report(lived(Array(1...13)))
        expect("form today", r.form.title, "Kindled today")

        // 3. A shield caught yesterday.
        r = report(lived(Array(2...12)))
        expect("shield story", r.story, .shielded)
        expect("shield line", r.line, "A shield caught yesterday. Today keeps your 11-day flame going.")
        expect("shield week", r.week[3], .shielded)
        expect("shield used", r.shields, 0)

        // 4. Yesterday missed with no shield: two quests today save it; one done, one more.
        r = report(lived(Array(2...5)))
        expect("repair story", r.story, .repair(need: 2))
        expect("repair line", r.line, "You missed yesterday. Two quests today keep your 4-day streak going. Your forms and progress stay either way.")
        expect("repair week", r.week[3], .missed)
        r = report(lived([0] + Array(2...5)))
        expect("repair half line", r.line, "You missed yesterday. One quest today keeps your 4-day streak going. Your forms and progress stay either way.")
        expect("repair half today", r.week[4], .today)

        // 4b. Repaired: a missed day saved by two quests the next day.
        r = report(lived([1, 1] + Array(3...6)))
        expect("repaired streak", r.streak, 5)
        expect("repaired week", r.week[2], .repaired)
        expect("repaired story", r.story, .waiting)

        // 5. Comeback: twelve days, then three missed (a shield caught the first); best and forms stay.
        r = report(lived(Array(4...15)))
        expect("comeback story", r.story, .comeback(ended: 12))
        expect("comeback streak", r.streak, 0)
        expect("comeback best", r.best, 12)
        expect("comeback line", r.line, "Your 12-day flame is resting. Your best is 12, and your forms are yours forever.")
        expect("comeback form", r.form.title, "Kindled in 14 days")
        expect("comeback form detail", r.form.detail, "from day 1")
        expect("comeback form bar", r.form.now, 0)

        // 6. Nothing lived yet.
        r = report([])
        expect("first story", r.story, .first)
        expect("first line", r.line, "Your first flame starts today.")
        expect("first form", r.form.title, "Flame in 3 days")
        expect("first level", r.level.title, "Level 1")
        expect("first level detail", r.level.detail, "100 XP to level 2")
        expect("first skill", r.skill.detail, "50 XP to level 2")
        expect("first week", r.week, [.empty, .empty, .empty, .empty, .today, .future, .future])

        // 7. Every form reached.
        r = report(lived(Array(1...95)))
        expect("all forms next", r.nextForm, nil)
        expect("all forms title", r.form.title, "Every form is yours")

        // 8. The form fix: best 10, now 2 after a break: Kindled is 12 days away, not 4.
        let p = Progression.formProgress(current: 2, best: 10)
        expect("form fix next", p.next, .kindled)
        expect("form fix left", p.left, 12)
        r = report(lived([1, 2] + Array(13...22)))
        expect("form fix report", r.form.title, "Kindled in 12 days")    // today is day 3: twelve days, today included

        // 8b. A restarted streak pursuing the same form never jumps back (best 10, now 6 then 7: 6/14 then 7/14), and
        //     its ghost is not the old streak's (it all happened this week).
        r = report(lived(Array(1...6)) + lived(Array(9...18)))
        expect("restart bar", (r.form.now * 14).rounded(), 6)
        expect("restart ghost", r.form.before, 0)
        r = report(lived(Array(0...6)) + lived(Array(9...18)))
        expect("restart bar next day", (r.form.now * 14).rounded(), 7)

        // 9. The week's best skill: Calm grew, Strength did not.
        r = report(lived(Array(8...12)) + lived(Array(1...7), realm: .stillwater))
        expect("best skill", r.skill.pillar, .spirit)
        expect("best skill title", r.skill.title, "Calm · level 3")

        // 9b. Mathis's test (2026-10-20): a quest, the Next day button (the whole record moves one day back), a quest.
        var deeds = [Deed(date: now, realm: RealmID.highlands.rawValue, title: "q", xp: 30)]
        r = report(deeds)
        expect("day 1 kept", [r.streak, r.week[4] == .todayLit ? 1 : 0], [1, 1])
        deeds = deeds.map { Deed(date: cal.date(byAdding: .day, value: -1, to: $0.date)!, realm: $0.realm, title: $0.title, xp: $0.xp) }
        r = report(deeds)
        expect("next morning", [r.streak, r.week[3] == .lived ? 1 : 0, r.week[4] == .today ? 1 : 0], [1, 1, 1])
        expect("next morning line", r.line, "Your flame is lit. Today makes it 2 days.")
        deeds.append(Deed(date: now, realm: RealmID.library.rawValue, title: "q", xp: 30))
        r = report(deeds)
        expect("day 2 kept", [r.streak, r.week[3] == .lived ? 1 : 0, r.week[4] == .todayLit ? 1 : 0], [2, 1, 1])

        // 11. Decision 184 (Mathis, 2026-10-21): coming to the app lights the day. His test: the Next day button three
        //     times, no quest: 1, 2, 3, a flame in each day's box, and the Flame form reached by opening on day 3.
        func opened(_ days: [Int]) -> [Date] { days.map { ago($0) } }
        func reportOpen(_ deeds: [Deed], _ open: [Date]) -> DailyReport { DailyReport.make(deeds: deeds, checkIns: open, now: now, calendar: cal) }
        r = reportOpen([], opened([0]))
        expect("open day 1", [r.streak, r.week[4] == .todayLit ? 1 : 0], [1, 1])
        expect("open day 1 line", r.line, "Your flame is lit. Come back tomorrow to make it 2 days.")
        r = reportOpen([], opened([1, 0]))
        expect("open day 2", [r.streak, r.week[3] == .lived ? 1 : 0, r.week[4] == .todayLit ? 1 : 0], [2, 1, 1])
        r = reportOpen([], opened([2, 1, 0]))
        expect("open day 3", [r.streak, r.week[2] == .lived ? 1 : 0, r.week[3] == .lived ? 1 : 0], [3, 1, 1])
        expect("open day 3 form", Evolution.reached(best: r.best), .flame)
        expect("open day 3 line", r.line, "3 days in a row. Come back tomorrow to make it 4.")
        r = reportOpen([], opened([2, 1]))
        expect("before today's open", [r.streak, r.week[4] == .today ? 1 : 0], [2, 1])
        // Shields still catch a missed day; coming back plus one quest repairs one; after a break a new flame is lit.
        r = reportOpen(lived(Array(2...12)), opened([0]))
        expect("open after a shield", r.line, "A shield caught yesterday. 12 days in a row.")
        r = reportOpen(lived(Array(2...5)), opened([0]))
        expect("open after a miss", [r.streak, r.week[4] == .today ? 1 : 0], [4, 1])
        r = reportOpen(lived([0] + Array(2...5)), opened([0]))
        expect("open + one quest repairs", [r.streak, r.week[2] == .repaired ? 0 : 1, r.week[3] == .repaired ? 1 : 0, r.week[4] == .todayLit ? 1 : 0], [5, 1, 1, 1])
        r = reportOpen(lived(Array(4...15)), opened([0]))
        expect("open after a break", [r.streak, r.best], [1, 12])
        expect("open after a break line", r.line, "A new flame is lit. Your best is 12, and your forms are yours forever.")

        // 12. Decision 189: the islands sit along your Flame's level path, in road order, each a little further on.
        let built = roadOrder.filter { $0 != .veil }
        expect("islands rise along the road", zip(built, built.dropFirst()).allSatisfy { $0.islandLevel < $1.islandLevel }, true)
        expect("Stillwater at level 4", RealmID.stillwater.islandLevel, 4)
        expect("level 4 starts at 600 XP", [Progression.level(xp: 599).level, Progression.level(xp: 600).level], [3, 4])

        // 13. The map's path (decision 189): Flame at level 3, the Grove bought, the Stillwater next (level 4).
        let painted: Set<RealmID> = [.sanctuary, .grove, .stillwater, .highlands, .library, .wilds, .forge]
        var path = IslandPath.make(flameLevel: 3, open: [.sanctuary, .grove], built: painted, nextToBuy: .stillwater, embers: 205)
        expect("path stones", [path.stones.first?.level ?? 0, path.stones.last?.level ?? 0], [1, 15])
        expect("path flame stone", [path.flameStone, path.stones[1].state == IslandPath.StoneState.passed ? 1 : 0, path.stones[2].state == IslandPath.StoneState.current ? 1 : 0, path.stones[3].state == IslandPath.StoneState.ahead ? 1 : 0], [3, 1, 1, 1])
        expect("path island on its stone", path.stones[3].island, RealmID.stillwater)
        expect("path next not reached", path.islands[2].state, IslandPath.IslandState.toReach(level: 4))
        expect("path further waits", path.islands[3].state, IslandPath.IslandState.waiting(level: 6))
        expect("path veil sealed", path.islands.last?.state, IslandPath.IslandState.sealed)
        path = IslandPath.make(flameLevel: 4, open: [.sanctuary, .grove], built: painted, nextToBuy: .stillwater, embers: 205)
        expect("path next buyable", path.islands[2].state, IslandPath.IslandState.buyable(price: 150, affordable: true))
        path = IslandPath.make(flameLevel: 18, open: [.sanctuary], built: painted, nextToBuy: .grove, embers: 0)
        expect("path past the last island", [path.stones.last?.level ?? 0, path.flameStone], [18, 18])

        // 10. The streak itself is unchanged by the new walk.
        let s = Progression.streak(deeds: lived(Array(2...12)), now: now, calendar: cal)
        expect("streak walk", [s.current, s.best, s.shields], [11, 11, 0])
    }
}
