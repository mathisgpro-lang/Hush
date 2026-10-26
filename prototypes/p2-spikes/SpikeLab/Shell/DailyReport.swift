// The daily screen's numbers (decision 183, plan docs/plan-2.0/p33-daily-welcome.md): what the screen you meet on the
// first open of each day shows, and what it shows again when your first quest lights today. Everything is calculated
// from what you've really lived (the deeds), at a given moment: nothing is stored, nothing is made up to look good.
// "7 days ago" is everything lived before the start of the same day last week, so a bar's gain is the last seven days,
// today included.
import Foundation

struct DailyReport: Hashable {
    /// One day of the week row (Monday first).
    enum Day: Hashable {
        case lived, missed, shielded, repaired   // a past day (repaired: missed, then saved by two quests the next day)
        case empty                               // before your Spark's first quest
        case today                               // waiting for its first quest: a glowing empty ring
        case todayLit                            // lived today
        case future
    }
    /// Which story the screen tells today.
    enum Story: Hashable {
        case first                               // nothing lived yet: the first flame starts today
        case waiting                             // the streak is alive, today waits
        case shielded                            // a shield caught yesterday
        case repair(need: Int)                   // yesterday was missed: `need` quests today save it
        case comeback(ended: Int)                // the streak ended (your best and your forms stay)
        case kept                                // today is lived
    }
    /// A bar that slides right: `before` is where you stood 7 days ago (the ghost), `now` where you are (0…1).
    struct Bar: Hashable {
        var title: String
        var detail: String
        var before: Double
        var now: Double
        var badge: String? = nil                 // "+1 level" when the week crossed a level
        var level = 0                            // the level shown (Flame or skill)
        var pillar: Pillar6? = nil               // the skill's pillar (its medallion)
    }

    var streak = 0, best = 0, shields = 0
    var story = Story.first
    var week: [Day] = []
    var line = ""
    var form = Bar(title: "", detail: "", before: 0, now: 0)
    var nextForm: Evolution?                     // its dark silhouette sits at the end of the form bar
    var level = Bar(title: "", detail: "", before: 0, now: 0)
    var skill = Bar(title: "", detail: "", before: 0, now: 0)
    var quote = ""
    var pouch = 0
    var shieldCaughtYesterday = false             // today is lit and a shield caught yesterday

    static func make(deeds: [Deed], checkIns: [Date] = [], xpBase: Int = 0, now: Date = Date(), pouch: Int = 0,
                     calendar cal: Calendar = .current) -> DailyReport {
        let walk = Progression.walk(deeds: deeds, checkIns: checkIns, now: now, calendar: cal)
        let s = walk.status
        let today = cal.startOfDay(for: now)
        let cutoff = cal.date(byAdding: .day, value: -6, to: today)!          // the 7 days shown as this week's gain
        let older = deeds.filter { $0.date < cutoff }
        let weekAgo = Progression.streak(deeds: older, checkIns: checkIns.filter { $0 < cutoff },
                                         now: cal.date(byAdding: .day, value: -1, to: cutoff)!, calendar: cal)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var r = DailyReport()
        r.streak = s.current; r.best = s.best; r.shields = s.shields; r.pouch = pouch
        r.quote = DailyWhy.today(now)

        // The story.
        switch s.state {
        case .livedToday: r.story = .kept; r.shieldCaughtYesterday = walk.marks[yesterday] == .shielded
        case .waiting: r.story = s.current > 0 ? .waiting : .first
        case .shieldedYesterday: r.story = .shielded
        case .repairable(let need): r.story = .repair(need: need)
        case .broken: r.story = s.best > 0 ? .comeback(ended: max(1, walk.ended)) : .first
        }

        // The week, Monday first.
        var iso = Calendar(identifier: .iso8601); iso.timeZone = cal.timeZone
        let monday = iso.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        r.week = (0..<7).map { i in
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: i, to: monday)!)
            if day > today { return .future }
            if day == today { return s.state == .livedToday ? .todayLit : .today }
            switch walk.marks[day] {
            case .lived: return .lived
            case .missed: return .missed
            case .shielded: return .shielded
            case .repaired: return .repaired
            case nil: return .empty
            }
        }

        // The next form: one honest scale, from 0 to its day count (as its "12 / 14" says), filled by the current
        // streak; it never jumps back while you pursue the same form (Codex review, 2026-10-20). If the streak
        // restarted this week, all of it is this week's: no ghost from the old one.
        let todayOpen = s.state != .livedToday                                // today's quest still counts toward it
        let p = Progression.formProgress(current: s.current, best: s.best)
        if let next = p.next {
            let span = Double(max(1, next.days))
            let now = Double(s.current) / span
            let then = weekAgo.current > s.current ? 0 : Double(weekAgo.current) / span
            r.nextForm = next
            r.form = Bar(title: p.left == 1 ? "\(next.name) \(todayOpen ? "today" : "tomorrow")" : "\(next.name) in \(p.left) days",
                         detail: s.current < 1 ? "from day 1" : "\(s.current) / \(next.days)",
                         before: then, now: min(1, now))
        } else {
            r.form = Bar(title: "Every form is yours", detail: "\(s.best) days at best", before: 1, now: 1)
        }

        // Your Flame's level, from its XP 7 days ago to now.
        let xpNow = max(0, deeds.reduce(0) { $0 + ($1.xp ?? 20) } - xpBase)
        let xpThen = max(0, older.reduce(0) { $0 + ($1.xp ?? 20) } - xpBase)
        r.level = bar(then: xpThen, now: xpNow, curve: Progression.level(xp:))
        r.level.title = "Level \(r.level.level)"
        if xpNow > xpThen { r.level.detail = "+\(xpNow - xpThen) XP this week" }
        else { let l = Progression.level(xp: xpNow); r.level.detail = "\(l.span - l.into) XP to level \(l.level + 1)" }

        // The skill that grew most this week (or, if none did, the one closest to its next level).
        func skillXP(_ p: Pillar6, _ ds: [Deed]) -> Int {
            ds.filter { Pillar6.of(RealmID(rawValue: $0.realm) ?? .grove) == p }.reduce(0) { $0 + ($1.xp ?? 20) }
        }
        let gains = Pillar6.allCases.map { p in (p, skillXP(p, older), skillXP(p, deeds)) }
        let grew = gains.max { ($0.2 - $0.1) < ($1.2 - $1.1) }!
        if grew.2 > grew.1 {
            r.skill = bar(then: grew.1, now: grew.2, curve: Progression.skill(xp:))
            let up = r.skill.level - Progression.skill(xp: grew.1).level
            r.skill.detail = up > 0 ? "+\(up) level\(up == 1 ? "" : "s") this week" : "+\(grew.2 - grew.1) XP this week"
            r.skill.badge = nil                                                   // (the detail already says it)
            r.skill.pillar = grew.0
        } else {
            let closest = gains.min { a, b in
                let la = Progression.skill(xp: a.2), lb = Progression.skill(xp: b.2)
                return (la.span - la.into) < (lb.span - lb.into)
            }!
            r.skill = bar(then: closest.2, now: closest.2, curve: Progression.skill(xp:))
            let l = Progression.skill(xp: closest.2)
            r.skill.detail = "\(l.span - l.into) XP to level \(l.level + 1)"
            r.skill.pillar = closest.0
        }
        r.skill.title = "\(r.skill.pillar!.attribute) · level \(r.skill.level)"

        r.line = line(r)
        return r
    }

    /// A bar between two XP totals on a level curve: if the week crossed a level, it starts from empty with a badge.
    private static func bar(then: Int, now: Int, curve: (Int) -> (level: Int, into: Int, span: Int)) -> Bar {
        let a = curve(then), b = curve(now)
        let fill = Double(b.into) / Double(max(1, b.span))
        let up = b.level - a.level
        return Bar(title: "", detail: "", before: up > 0 ? 0 : Double(a.into) / Double(max(1, a.span)), now: fill,
                   badge: up > 0 ? "+\(up) level\(up == 1 ? "" : "s")" : nil, level: b.level)
    }

    /// The one story line (plan §2): honest, warm, never a guilt trip. Coming to the app lights the day (decision 184),
    /// so the morning screen usually tells a day already kept.
    static func line(_ r: DailyReport) -> String {
        let c = r.streak
        switch r.story {
        case .first: return "Your first flame starts today."
        case .waiting: return c == 1 ? "Your flame is lit. Today makes it 2 days." : "\(c) days in a row. Today makes it \(c + 1)."
        case .shielded: return "A shield caught yesterday. Today keeps your \(c)-day flame going."
        case .repair(let need):
            return need >= 2 ? "You missed yesterday. Two quests today keep your \(c)-day streak going. Your forms and progress stay either way."
                             : "You missed yesterday. One quest today keeps your \(c)-day streak going. Your forms and progress stay either way."
        case .comeback(let ended):
            return "Your \(ended)-day flame is resting. Your best is \(r.best), and your forms are yours forever."
        case .kept:
            if c == 1 { return r.best > 1 ? "A new flame is lit. Your best is \(r.best), and your forms are yours forever."
                                          : "Your flame is lit. Come back tomorrow to make it 2 days." }
            if r.shieldCaughtYesterday { return "A shield caught yesterday. \(c) days in a row." }
            if let next = r.nextForm, next.days - c == 1 { return "\(c) days in a row. \(next.name) tomorrow." }
            return "\(c) days in a row. Come back tomorrow to make it \(c + 1)."
        }
    }
}
