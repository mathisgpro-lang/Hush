// The quest library and the picker (P3.0 step 1, decisions 154, 163). Every quest is short, concrete and safe, with a
// reason why (cited in plain words), a size (minutes, or a count to reach) and a level: 1 easy, 2 steady, 3 stretch.
// The picker builds your day like a good coach would, without ever shaming:
//   · one habit you're building (from why you came), the same each day so it becomes yours, a level up when it's easy;
//   · one for the part of your life you rated lowest (Day 1) or have lived least lately;
//   · one to explore (the pillar you've touched least recently);
//   · a surprise, and two more to swap in the satchel.
// A quest skipped three times in two weeks comes back one level easier.
import Foundation

struct QuestDef: Identifiable, Hashable {
    let id: String
    let pillar: Pillar6
    let level: Int
    let title: String
    let detail: String
    let why: String
    let symbol: String
    var minutes: Int = 5
    var target: Int = 1
    var unit: String = ""
    /// Done once, then never offered again (a set-up, like installing Opal).
    var once = false
    var realm: RealmID { pillar.realm }
}

enum QuestLibrary {
    // Short, readable at a glance, after Finch (Mathis, 2026-10-13: "do 10 push ups, read 20 pages, 10 min meditation").
    // Not life's basics but getting stronger as a whole: Body, Mind and Spirit first, and sustainability (the World).
    // The card shows the title; opening it shows how, and why (decision 163).
    static let all: [QuestDef] = [
        // Body (the Ascent Highlands)
        .init(id: "body-squats", pillar: .body, level: 1, title: "15 squats", detail: "In as many sets as you need. Feet shoulder-width, back straight, knees over toes.", why: "Leg strength is one of the best predictors of staying strong and independent with age.", symbol: "figure.strengthtraining.functional", minutes: 3, target: 15, unit: "squats"),
        .init(id: "body-walk", pillar: .body, level: 1, title: "15-min brisk walk", detail: "Fast enough to talk but not sing.", why: "Brisk walking every day is the simplest base for heart health (WHO: 150 min a week).", symbol: "figure.walk.motion", minutes: 15, target: 15, unit: "min"),
        .init(id: "body-stretch", pillar: .body, level: 1, title: "10-min mobility", detail: "Hips, shoulders, spine: slow and controlled, never painful.", why: "Daily mobility keeps joints moving freely and protects you from stiffness and injury.", symbol: "figure.flexibility", minutes: 10, target: 10, unit: "min"),
        .init(id: "body-pushups", pillar: .body, level: 2, title: "10 push-ups", detail: "Any sets you need. On your knees is fine: full range, body straight.", why: "Push-up capacity is linked to lower heart-disease risk; upper-body strength builds fast.", symbol: "figure.strengthtraining.traditional", minutes: 3, target: 10, unit: "push-ups"),
        .init(id: "body-plank", pillar: .body, level: 2, title: "1-min plank", detail: "Elbows under shoulders, body in one line. Rest and repeat until you reach a minute.", why: "A strong core supports your back and every other movement.", symbol: "figure.core.training", minutes: 2, target: 60, unit: "sec"),
        .init(id: "body-walk30", pillar: .body, level: 2, title: "30-min walk", detail: "Brisk, outside if you can.", why: "Thirty minutes a day, five days a week, meets the WHO's activity baseline.", symbol: "figure.walk", minutes: 30, target: 30, unit: "min"),
        .init(id: "body-run", pillar: .body, level: 3, title: "20-min run", detail: "An easy pace you could keep talking at. Walk breaks are fine.", why: "Regular running strengthens the heart and lifts mood for hours.", symbol: "figure.run", minutes: 20, target: 20, unit: "min"),
        .init(id: "body-pushups30", pillar: .body, level: 3, title: "30 push-ups", detail: "In sets of whatever you can do well. Stop before your form breaks.", why: "Building past your comfort zone, safely, is how strength keeps growing.", symbol: "figure.strengthtraining.traditional", minutes: 6, target: 30, unit: "push-ups"),
        // Mind (the Library of Embers)
        .init(id: "mind-read10", pillar: .mind, level: 1, title: "Read 10 pages", detail: "Any book that makes you think. Paper or e-reader, not a feed.", why: "Ten pages a day is about a book a month: a dozen new minds every year.", symbol: "book.fill", minutes: 15, target: 10, unit: "pages"),
        .init(id: "mind-words", pillar: .mind, level: 1, title: "Learn 5 words", detail: "In a language you're learning. Say each one out loud in a sentence.", why: "Short daily practice beats long sessions for memory (spaced repetition).", symbol: "character.book.closed.fill", minutes: 5, target: 5, unit: "words"),
        .init(id: "mind-ideas", pillar: .mind, level: 1, title: "Write 3 ideas", detail: "About anything: work, life, a project. Just get them on paper.", why: "Writing ideas down frees working memory, and ideas grow when you see them.", symbol: "pencil.and.scribble", minutes: 5, target: 3, unit: "ideas"),
        .init(id: "mind-read20", pillar: .mind, level: 2, title: "Read 20 pages", detail: "Somewhere quiet, phone in another room.", why: "Deep reading trains the focus that scrolling wears down.", symbol: "book.fill", minutes: 25, target: 20, unit: "pages"),
        .init(id: "mind-lesson", pillar: .mind, level: 2, title: "1 course lesson", detail: "One lesson of something you're learning: a language, an instrument, a skill.", why: "Regular small sessions are how real skills are built.", symbol: "graduationcap.fill", minutes: 20, target: 20, unit: "min"),
        .init(id: "mind-teach", pillar: .mind, level: 2, title: "Explain it simply", detail: "Pick something you learned this week and explain it in five sentences.", why: "Explaining in plain words is the surest way to truly understand (the Feynman technique).", symbol: "lightbulb.fill", minutes: 10),
        // Set up once, when you're ready for it (Mathis): the blocker that protects your focus and your nights.
        .init(id: "mind-opal", pillar: .mind, level: 2, title: "Set up Opal", detail: "Download Opal (free) and set two rules: social apps blocked during your focus time, and everything but calls after 22:00.", why: "Removing the temptation works far better than willpower: app blockers cut daily screen time.", symbol: "hourglass", minutes: 10, once: true),
        .init(id: "mind-offline", pillar: .mind, level: 3, title: "1 hour, no phone", detail: "Phone in another room for a whole hour. Read, think, make.", why: "An hour without notifications restores attention like nothing else.", symbol: "iphone.slash", minutes: 60, target: 60, unit: "min"),
        .init(id: "mind-read50", pillar: .mind, level: 3, title: "Read 50 pages", detail: "A long, uninterrupted session with one book.", why: "Long reading sessions build the deep concentration that great work needs.", symbol: "books.vertical.fill", minutes: 60, target: 50, unit: "pages"),
        // Spirit (the Stillwater)
        .init(id: "spirit-breaths", pillar: .spirit, level: 1, title: "10 slow breaths", detail: "In for four, out for six. Eyes closed if you can.", why: "A longer out-breath calms the nervous system within a minute.", symbol: "wind", minutes: 2, target: 10, unit: "breaths"),
        .init(id: "spirit-gratitude", pillar: .spirit, level: 1, title: "3 gratitudes", detail: "Write three things you're grateful for today, however small.", why: "A daily gratitude practice is one of the most studied ways to lift well-being.", symbol: "sparkles", minutes: 3, target: 3, unit: "things"),
        .init(id: "spirit-med5", pillar: .spirit, level: 1, title: "5-min meditation", detail: "Sit, follow your breath, come back gently each time you drift.", why: "Even five minutes a day lowers stress and trains attention.", symbol: "figure.mind.and.body", minutes: 5, target: 5, unit: "min"),
        .init(id: "spirit-med10", pillar: .spirit, level: 2, title: "10-min meditation", detail: "Same practice, a little longer. Notice, then return.", why: "Ten minutes a day over weeks measurably reduces anxiety and improves focus.", symbol: "figure.mind.and.body", minutes: 10, target: 10, unit: "min"),
        .init(id: "spirit-journal", pillar: .spirit, level: 2, title: "5-min journal", detail: "Write honestly about how you feel and why.", why: "Putting feelings into words calms them (expressive writing research).", symbol: "book.closed.fill", minutes: 5, target: 5, unit: "min"),
        .init(id: "spirit-screens", pillar: .spirit, level: 2, title: "No screens at bed", detail: "Screens away 30 minutes before sleep. Read or rest instead.", why: "Less light and stimulation before bed means deeper, faster sleep.", symbol: "moon.fill", minutes: 30),
        // A rule for the strong (Mathis): from 22:00 the phone sleeps outside the bedroom.
        .init(id: "spirit-bedroom", pillar: .spirit, level: 3, title: "Phone out at 22:00", detail: "From 22:00 your phone stays outside your bedroom all night. Use a real alarm clock.", why: "Phones in the bedroom delay sleep and cut its quality; keeping them out is one of the simplest sleep upgrades.", symbol: "bed.double.fill", minutes: 1),
        .init(id: "spirit-med20", pillar: .spirit, level: 3, title: "20-min meditation", detail: "A longer sit. Stay with the breath through the restless parts.", why: "Longer sits build the calm you can carry into hard moments.", symbol: "figure.mind.and.body", minutes: 20, target: 20, unit: "min"),
        .init(id: "spirit-silence", pillar: .spirit, level: 3, title: "30-min silent walk", detail: "No music, no podcast, no phone: just walk and notice.", why: "Silence and nature together are among the best resets for the mind.", symbol: "figure.walk", minutes: 30, target: 30, unit: "min"),
        // World: sustainability (the Wilds)
        .init(id: "world-litter", pillar: .world, level: 1, title: "Pick up 5 litter", detail: "Five pieces on your way. Bin or recycle them.", why: "Litter harms wildlife and waterways; small acts of care add up and spread.", symbol: "trash.fill", minutes: 5, target: 5, unit: "pieces"),
        .init(id: "world-bottle", pillar: .world, level: 1, title: "No plastic bottles", detail: "Carry a refillable bottle all day.", why: "A refillable bottle saves hundreds of single-use bottles a year.", symbol: "waterbottle.fill", minutes: 1),
        .init(id: "world-unplug", pillar: .world, level: 1, title: "Unplug standby", detail: "Switch off chargers and devices on standby at home.", why: "Standby power can be up to 10% of a home's electricity.", symbol: "powerplug.fill", minutes: 5),
        .init(id: "world-meatfree", pillar: .world, level: 2, title: "Meat-free day", detail: "All your meals plant-based today.", why: "Eating less meat is one of the biggest personal cuts to emissions and water use.", symbol: "leaf.fill", minutes: 5),
        .init(id: "world-bike", pillar: .world, level: 2, title: "Walk or bike it", detail: "One trip you'd usually drive: on foot, by bike or transit.", why: "Short car trips are the least efficient; swapping them cuts emissions and moves you.", symbol: "bicycle", minutes: 20),
        .init(id: "world-shower", pillar: .world, level: 2, title: "4-min shower", detail: "Time it. Off while you soap.", why: "Shorter showers save water and the energy that heats it.", symbol: "shower.fill", minutes: 4, target: 4, unit: "min"),
        .init(id: "world-nothingnew", pillar: .world, level: 3, title: "Buy nothing new", detail: "A whole day without buying anything new. Repair, borrow or wait.", why: "Most of our footprint hides in the things we buy.", symbol: "bag.badge.minus", minutes: 5),
        .init(id: "world-zerowaste", pillar: .world, level: 3, title: "Zero-waste day", detail: "Nothing in the general bin today: refuse, reuse, recycle, compost.", why: "One day shows you exactly where your waste comes from, and how to cut it.", symbol: "arrow.3.trianglepath", minutes: 10),
        // Heart (the Whispering Grove): fewer, still about growing
        .init(id: "heart-text", pillar: .heart, level: 1, title: "Text a friend", detail: "Tell them one thing you appreciate about them.", why: "Expressed appreciation is one of the strongest builders of close bonds.", symbol: "message.fill", minutes: 2),
        .init(id: "heart-call", pillar: .heart, level: 2, title: "10-min call", detail: "Someone you miss. Just to hear how they are.", why: "Regular contact is what keeps friendships alive over the years.", symbol: "phone.fill", minutes: 10, target: 10, unit: "min"),
        .init(id: "heart-listen", pillar: .heart, level: 2, title: "Listen, no advice", detail: "In one conversation today, only ask and listen.", why: "Feeling truly heard is one of the deepest forms of care.", symbol: "ear.fill", minutes: 10),
        .init(id: "heart-letter", pillar: .heart, level: 3, title: "Write a letter", detail: "A few honest lines to someone who shaped you. Send it.", why: "Gratitude letters are among the most studied happiness boosts.", symbol: "envelope.fill", minutes: 15),
        // Craft (Forge Mountain): fewer, still about growing
        .init(id: "craft-start", pillar: .craft, level: 1, title: "5 min on it", detail: "Start the thing you've been putting off. Just five minutes.", why: "Starting is the hardest part; five minutes is often enough to keep going.", symbol: "play.fill", minutes: 5, target: 5, unit: "min"),
        .init(id: "craft-focus", pillar: .craft, level: 2, title: "25-min focus", detail: "One task, phone in another room, timer on.", why: "Short protected blocks are how deep work becomes a habit (the Pomodoro method).", symbol: "timer", minutes: 25, target: 25, unit: "min"),
        .init(id: "craft-make", pillar: .craft, level: 2, title: "Make something", detail: "Draw, code, cook, build, write: 20 minutes making anything.", why: "Making things trains skill and patience, and it feels good.", symbol: "paintbrush.fill", minutes: 20, target: 20, unit: "min"),
        .init(id: "craft-deep", pillar: .craft, level: 3, title: "1 hour deep work", detail: "Sixty minutes on your most important work, no interruptions.", why: "Deep, undistracted work is where most real progress happens.", symbol: "flame.fill", minutes: 60, target: 60, unit: "min"),
    ]

    /// Small surprises (the Spark): playful, short, from the world's lore.
    static let surprises: [(String, String)] = [
        ("The fox's dare", "A little fox dares you: 20 jumping jacks, right now."),
        ("The owl's question", "Quill asks: what's one thing you're proud of this week? Say it out loud."),
        ("The heron's pause", "Ilo stands still for a whole minute. Can you, wherever you are?"),
        ("Orrin's spark", "Fix one broken thing today instead of replacing it."),
    ]
    /// The pillars the quests grow around (Mathis): Body, Mind, Spirit, and the World (sustainability).
    static let core: [Pillar6] = [.body, .mind, .spirit, .world]

    static func pillar(forInterest i: String) -> Pillar6 {
        Pillar6.of(emberChoices.first { $0.interest == i }?.realm ?? .grove)
    }

    /// Builds today's offer. Deterministic for a given day (the same list all day).
    static func today(journey j: Journey, interest: String, on date: Date = Date()) -> [Call] {
        var rng = SeededRandom(seed: UInt64(max(1, j.dayNumber(of: date))) &* 2654435761)
        let main = pillar(forInterest: interest)
        let done = Dictionary(grouping: j.deeds, by: { Pillar6.of(RealmID(rawValue: $0.realm) ?? .grove) })
        func experience(_ p: Pillar6) -> Int { done[p]?.count ?? 0 }
        func lastDone(_ p: Pillar6) -> Date { done[p]?.map(\.date).max() ?? .distantPast }
        func level(for p: Pillar6) -> Int { experience(p) < 6 ? 1 : experience(p) < 20 ? 2 : 3 }
        func pick(_ p: Pillar6, avoid: Set<String>, stable: Bool) -> QuestDef {
            var lv = level(for: p)
            var pool = all.filter { q in q.pillar == p && !avoid.contains(q.id) && !(q.once && j.deeds.contains { $0.title == q.title }) }
            // Skipped three times in two weeks: one level easier (never shamed, just lighter).
            if let hard = pool.first(where: { j.skipCount($0.title, days: 14) >= 3 }) { lv = max(1, hard.level - 1) }
            pool = pool.filter { j.skipCount($0.title, days: 14) < 3 }
            let atLevel = pool.filter { $0.level == lv }
            let choices = atLevel.isEmpty ? pool : atLevel
            if stable, let habit = choices.first(where: { j.questStreak($0.title) > 0 }) ?? choices.first { return habit }   // the habit stays the same
            return choices.isEmpty ? all.first { $0.pillar == p }! : choices[Int(rng.next() % UInt64(choices.count))]
        }
        // The pillar you rated lowest on Day 1, or lived least lately.
        let weakest = core.filter { $0 != main }.min { a, b in
            let ra = j.dayOne[a.rawValue] ?? 1, rb = j.dayOne[b.rawValue] ?? 1
            return ra != rb ? ra < rb : experience(a) < experience(b)
        } ?? .spirit
        let explore = core.filter { $0 != main && $0 != weakest }.min { lastDone($0) < lastDone($1) } ?? .world
        var used: Set<String> = []
        func take(_ p: Pillar6, stable: Bool = false) -> QuestDef { let q = pick(p, avoid: used, stable: stable); used.insert(q.id); return q }
        let a = take(main, stable: true), c = take(weakest), d = take(explore)
        let rest = core.filter { ![main, weakest, explore].contains($0) }.shuffled(using: &rng)        // the core four first,
            + [Pillar6.heart, .craft].filter { $0 != main }.shuffled(using: &rng)                   // then the Grove and the Forge
        let e = take(rest.first ?? .mind), f = take(rest.dropFirst().first ?? .body)
        let s = surprises[Int(rng.next() % UInt64(surprises.count))]
        func call(_ q: QuestDef, _ id: String, reason: String = "") -> Call {
            Call(id: id, title: q.title, detail: q.detail, symbol: q.symbol, realm: q.realm, minutes: q.minutes,
                 difficulty: ["Easy", "Steady", "Stretch"][max(0, min(2, q.level - 1))], target: q.target, unit: q.unit,
                 reason: reason.isEmpty ? q.why : reason)
        }
        return [call(a, "a", reason: "Your habit for \(main.rawValue.lowercased()). " + a.why),
                Call(id: "b", title: s.0, detail: s.1, symbol: "sparkle", realm: .grove, minutes: 5, reason: "A surprise from the world."),
                call(c, "c"), call(d, "d"), call(e, "e"), call(f, "f")]
    }
}

extension Journey {
    /// How many times a quest was skipped in the last days (the picker lightens it after three).
    func skipCount(_ title: String, days: Int) -> Int {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return (skipLog[title] ?? []).filter { $0 >= since }.count
    }
}
