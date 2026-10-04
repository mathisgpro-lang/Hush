// Your journey (decisions 128–129): what you've really lived, kept on the phone, from which the Book of Your Flame
// writes itself page by page and Your Flame sums up where you are. Nothing is written in advance: every page comes
// from something you did, on the day you did it. (Prototype store: UserDefaults. The real app keeps this in the record.)
import Foundation

struct BookPage: Codable, Identifiable, Hashable {
    let id: String              // one page per event (written once)
    let world: String           // RealmID raw value, or "emberlands"
    let date: Date
    let title: String
    let text: String
}

struct Deed: Codable, Hashable {
    let date: Date
    let realm: String           // where its light went (RealmID raw value)
    let title: String
    var xp: Int? = nil          // what it earned, fixed the moment it was done (older deeds: 20)
}

/// What one completed quest just did, for the moment it happens (the +XP, a level-up, a streak milestone, a shield).
struct DeedOutcome {
    let xp: Int
    let pillar: Pillar6
    let attributeBefore: Int, attributeAfter: Int
    let levelBefore: Int, levelAfter: Int
    let streakBefore: Int, streakAfter: Int
    let milestone: Int?
    let shieldEarned: Bool
}

@MainActor @Observable
final class Journey {
    private(set) var bornOn: Date?
    private(set) var name = ""
    private(set) var ember = ""
    private(set) var pages: [BookPage] = []
    private(set) var deeds: [Deed] = []
    private(set) var newPages = 0                     // written since you last opened the Book (its clasp glows)

    private let key = "journey.v1"
    private struct Saved: Codable { var bornOn: Date?; var name: String; var ember: String; var pages: [BookPage]; var deeds: [Deed] }

    init() {
        if CommandLine.arguments.contains("-freshjourney") { UserDefaults.standard.removeObject(forKey: key) }
        if let d = UserDefaults.standard.data(forKey: key), let s = try? JSONDecoder().decode(Saved.self, from: d) {
            bornOn = s.bornOn; name = s.name; ember = s.ember; pages = s.pages; deeds = s.deeds
        }
        if CommandLine.arguments.contains("-seedjourney") { seedForTesting() }
    }

    private func save() {
        let s = Saved(bornOn: bornOn, name: name, ember: ember, pages: pages, deeds: deeds)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key) }
    }

    private func write(_ id: String, world: String, title: String, _ text: String, on date: Date = Date()) {
        guard !pages.contains(where: { $0.id == id }) else { return }
        pages.append(BookPage(id: id, world: world, date: date, title: title, text: text))
        newPages += 1
        save()
    }

    func bookOpened() { newPages = 0 }

    // MARK: Moments that write pages

    /// The night your Spark was born (the end of the introduction).
    func born(name: String, ember: String, on date: Date = Date()) {
        guard bornOn == nil else { return }
        bornOn = date; self.name = name; self.ember = ember.lowercased()
        let who = name.isEmpty ? "You" : name
        write("born", world: RealmID.sanctuary.rawValue, title: "The night the runes woke",
              "\(who) came to the Sanctuary while it slept in the Hush, and held an ember of \(self.ember) close until it cracked. A small Spark rose above the stone circle, blinked, and said hello. For the first time in a long while, the runes glowed.", on: date)
    }

    /// You took quests from the satchel for the first time.
    func firstQuests(_ titles: [String]) {
        guard !titles.isEmpty else { return }
        let list = ListFormatter.localizedString(byJoining: titles.map { "“\($0)”" })
        write("satchel", world: RealmID.sanctuary.rawValue, title: "The satchel",
              "Your Spark opened the old satchel and you chose your first quests: \(list). They waited for you on the stones, glowing softly.")
    }

    /// You did something real: XP, your streak and your attribute grow; the day's page in the Sanctuary grows, and the
    /// realm it lit gets its own line. Returns what just happened, for the moment itself.
    @discardableResult
    func did(_ title: String, detail: String, realm: RealmID, minutes: Int = 5, on date: Date = Date()) -> DeedOutcome {
        let before = streak(at: date)
        let pillar = Pillar6.of(realm)
        let attrBefore = attribute(pillar), lvlBefore = Progression.level(xp: totalXP).level
        let gain = Progression.xp(minutes: minutes, streak: before.current)
        deeds.append(Deed(date: date, realm: realm.rawValue, title: title, xp: gain))
        let after = streak(at: date)
        let milestone = StreakStatus.milestones.first { $0 > before.current && $0 <= after.current }
        if let m = milestone {
            write("streak-\(m)", world: RealmID.sanctuary.rawValue, title: "\(m) days in a row",
                  m >= 66 ? "Sixty-six days. The runes around the circle burned gold all night, and your Spark could not stop glowing. Something had changed for good: not a streak anymore, a part of who you are."
                          : "For \(m) days in a row, you kept your word to yourself. Your Spark burned a little steadier each morning, and the Sanctuary noticed.", on: date)
        }
        defer { save() }
        let outcome = DeedOutcome(xp: gain, pillar: pillar, attributeBefore: attrBefore, attributeAfter: attribute(pillar),
                                  levelBefore: lvlBefore, levelAfter: Progression.level(xp: totalXP).level,
                                  streakBefore: before.current, streakAfter: after.current,
                                  milestone: milestone, shieldEarned: after.shields > before.shields)
        let n = dayNumber(of: date)
        let today = deeds.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let lines = today.map { "“\($0.title)”" }
        let text = today.count == 1
            ? "You lived your \(ordinal(n)) day with your Spark. You did “\(title)”, and a thread of light flew from it to the stone circle."
            : "You lived your \(ordinal(n)) day with your Spark, and kept your word \(today.count) times: \(ListFormatter.localizedString(byJoining: lines)). Each one sent a thread of light to the stone circle."
        // The day's page is rewritten as the day goes on (it is still being lived).
        let id = "day-\(n)"
        if let i = pages.firstIndex(where: { $0.id == id }) {
            pages[i] = BookPage(id: id, world: RealmID.sanctuary.rawValue, date: pages[i].date, title: "Day \(n)", text: text)
            save()
        } else {
            write(id, world: RealmID.sanctuary.rawValue, title: "Day \(n)", text, on: date)
        }
        if realm == .grove {
            let k = deeds.filter { $0.realm == RealmID.grove.rawValue }.count
            write("grove-lantern-\(k)", world: realm.rawValue, title: k == 1 ? "The first lantern" : "A lantern relit",
                  k == 1 ? "Because of “\(title)”, the first lantern in the old trees flickered and caught. Nim and Ro gasped. One small light, in a forest that had been dark for so long."
                         : "“\(title)”: another lantern relit in the Grove, higher in the branches. The path below it is a little easier to see now.", on: date)
        }
        return outcome
    }

    // MARK: The streak and the numbers (decision 134), always calculated from the deeds

    func streak(at date: Date = Date()) -> StreakStatus { Progression.streak(deeds: deeds, now: date) }
    var totalXP: Int { deeds.reduce(0) { $0 + ($1.xp ?? 20) } }
    /// A pillar's attribute: the XP its quests have earned (Strength, Wisdom, Warmth, Calm, Focus, Care).
    func attribute(_ p: Pillar6) -> Int { deeds.filter { Pillar6.of(RealmID(rawValue: $0.realm) ?? .grove) == p }.reduce(0) { $0 + ($1.xp ?? 20) } }
    func questStreak(_ title: String) -> Int { Progression.questStreak(title: title, deeds: deeds) }
    /// Skipped quests (honest, never punished): today only.
    private(set) var skippedToday: Set<String> = []
    func skip(_ title: String) { skippedToday.insert(title) }

    /// The first time you looked out over the Emberlands.
    func sawTheWorld() {
        write("emberlands", world: "emberlands", title: "Out there",
              "Your Spark showed you the Emberlands for the first time. From high above, almost all of it still slept under the grey Hush, except a soft glow among old trees to the west.")
    }

    /// The first time you entered a realm.
    func entered(_ realm: RealmID) {
        guard let page = RealmContent.firstVisit(realm) else { return }
        write("\(realm.rawValue)-entered", world: realm.rawValue, title: page.title, page.text)
    }

    // MARK: Your Flame

    var daysLived: Int { Set(deeds.map { Calendar.current.startOfDay(for: $0.date) }).count }
    /// Day number since your Spark was born (day 1 = the day it was born).
    func dayNumber(of date: Date = Date()) -> Int {
        guard let b = bornOn else { return 1 }
        let d = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: b), to: Calendar.current.startOfDay(for: date)).day ?? 0
        return d + 1
    }
    /// This week (Monday first): which days you lived.
    var thisWeek: [Bool] {
        var cal = Calendar(identifier: .iso8601); cal.firstWeekday = 2
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return Array(repeating: false, count: 7) }
        return (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i, to: start)!
            return deeds.contains { cal.isDate($0.date, inSameDayAs: day) }
        }
    }
    /// How many things you've done for each pillar (its light).
    func light(for realm: RealmID) -> Int { deeds.filter { $0.realm == realm.rawValue }.count }
    /// Days lived out of the last seven (Vitality).
    var lastSeven: Int {
        let cal = Calendar.current
        return (0..<7).filter { i in
            let day = cal.date(byAdding: .day, value: -i, to: Date())!
            return deeds.contains { cal.isDate($0.date, inSameDayAs: day) }
        }.count
    }

    private func ordinal(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: n)) ?? "\(n)th"
    }

    /// A few days of history, to see the Book and Your Flame grown (test flag only).
    private func seedForTesting() {
        guard bornOn == nil else { return }
        let cal = Calendar.current
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: Date())! }
        born(name: "Mathis", ember: "Love", on: ago(9))
        write("satchel", world: RealmID.sanctuary.rawValue, title: "The satchel",
              "Your Spark opened the old satchel and you chose your first quests: “A lantern for someone”, “A quiet moment” and “Ten minutes outside”. They waited for you on the stones, glowing softly.", on: ago(9))
        // Nine days in a row (a shield earned at 7), today not yet lived.
        let plan: [(String, RealmID, Int)] = [("A lantern for someone", .grove, 5), ("Ten minutes outside", .highlands, 10), ("A quiet moment", .stillwater, 2), ("One page", .library, 5)]
        for d in stride(from: 9, through: 1, by: -1) {
            let q = plan[d % plan.count]; did(q.0, detail: "", realm: q.1, minutes: q.2, on: ago(d))
            if d % 3 == 0 { let r = plan[(d + 1) % plan.count]; did(r.0, detail: "", realm: r.1, minutes: r.2, on: ago(d)) }
        }
        write("emberlands", world: "emberlands", title: "Out there",
              "Your Spark showed you the Emberlands for the first time. From high above, almost all of it still slept under the grey Hush, except a soft glow among old trees to the west.", on: ago(8))
        newPages = 2
    }
}
