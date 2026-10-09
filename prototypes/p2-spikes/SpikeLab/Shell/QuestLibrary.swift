// The quest library and the picker (P3.0 step 1, decision 154). Every quest is small, concrete and safe, with a
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
    var realm: RealmID { pillar.realm }
}

enum QuestLibrary {
    static let all: [QuestDef] = [
        // Body (the Ascent Highlands)
        .init(id: "body-walk10", pillar: .body, level: 1, title: "Ten minutes outside", detail: "Walk at an easy pace. Look up at the sky once.", why: "Ten easy minutes a day is where lasting movement habits start.", symbol: "figure.walk", minutes: 10, target: 10, unit: "min"),
        .init(id: "body-stretch", pillar: .body, level: 1, title: "Five-minute stretch", detail: "Neck, shoulders, back, legs: slow, never painful.", why: "Gentle daily stretching eases stiffness from sitting.", symbol: "figure.flexibility", minutes: 5, target: 5, unit: "min"),
        .init(id: "body-water", pillar: .body, level: 1, title: "A glass of water now", detail: "Drink one full glass, slowly.", why: "Many of us start the day under-hydrated; a glass is the easiest win.", symbol: "drop.fill", minutes: 1),
        .init(id: "body-squats", pillar: .body, level: 2, title: "Twenty squats", detail: "In as many sets as you need. Knees over toes, back straight.", why: "Leg strength is one of the best predictors of staying active with age.", symbol: "figure.strengthtraining.functional", minutes: 4, target: 20, unit: "squats"),
        .init(id: "body-walk30", pillar: .body, level: 2, title: "A 30-minute walk", detail: "Brisk enough to talk but not sing.", why: "About 150 minutes of brisk walking a week is the WHO's baseline for health.", symbol: "figure.walk.motion", minutes: 30, target: 30, unit: "min"),
        .init(id: "body-workout", pillar: .body, level: 3, title: "A real workout", detail: "20 minutes of something that makes you breathe hard: run, cycle, a class.", why: "Vigorous exercise strengthens the heart and lifts mood for hours.", symbol: "figure.run", minutes: 20, target: 20, unit: "min"),
        // Mind (the Library of Embers)
        .init(id: "mind-page", pillar: .mind, level: 1, title: "One page", detail: "Read a single page of something you've meant to read.", why: "A tiny daily start is how reading habits come back.", symbol: "book.fill", minutes: 3),
        .init(id: "mind-10pages", pillar: .mind, level: 2, title: "Ten pages", detail: "Read ten pages of any book you like.", why: "Ten pages a day is about a book a month.", symbol: "book.fill", minutes: 15, target: 10, unit: "pages"),
        .init(id: "mind-learn", pillar: .mind, level: 1, title: "Learn one thing", detail: "Look up something you've wondered about. Explain it to yourself in one sentence.", why: "Explaining in your own words is how things stick.", symbol: "lightbulb.fill", minutes: 5),
        .init(id: "mind-notes", pillar: .mind, level: 2, title: "Three ideas on paper", detail: "Write three ideas about anything: work, life, a project.", why: "Writing ideas down frees the mind and they grow.", symbol: "pencil.and.scribble", minutes: 5, target: 3, unit: "ideas"),
        .init(id: "mind-course", pillar: .mind, level: 3, title: "A lesson of a course", detail: "Do one lesson of something you're learning: a language, a skill.", why: "Small regular sessions beat cramming for long-term memory.", symbol: "graduationcap.fill", minutes: 20, target: 20, unit: "min"),
        .init(id: "mind-noscreen", pillar: .mind, level: 3, title: "An evening without scrolling", detail: "No social feeds after dinner. Read, talk or rest instead.", why: "Less late scrolling means better sleep and a calmer mind.", symbol: "iphone.slash", minutes: 60),
        // Heart (the Whispering Grove)
        .init(id: "heart-lantern", pillar: .heart, level: 1, title: "A lantern for someone", detail: "Tell someone you love one thing you admire about them.", why: "Expressed appreciation is one of the strongest builders of close bonds.", symbol: "heart.fill", minutes: 5),
        .init(id: "heart-thanks", pillar: .heart, level: 1, title: "A thank-you", detail: "Thank someone who rarely hears it: a colleague, a neighbour, a driver.", why: "Gratitude lifts both the one who gives it and the one who hears it.", symbol: "hands.clap.fill", minutes: 2),
        .init(id: "heart-call", pillar: .heart, level: 2, title: "Call someone you miss", detail: "Ten minutes, just to hear how they are.", why: "Regular contact is what keeps friendships alive over the years.", symbol: "phone.fill", minutes: 10, target: 10, unit: "min"),
        .init(id: "heart-listen", pillar: .heart, level: 2, title: "Really listen", detail: "In one conversation today, only ask and listen. No advice.", why: "Feeling heard is one of the deepest forms of care.", symbol: "ear.fill", minutes: 10),
        .init(id: "heart-plan", pillar: .heart, level: 3, title: "Plan time together", detail: "Set a date with someone you love: a walk, a meal, a game.", why: "Shared time, planned ahead, is what close relationships are built on.", symbol: "calendar.badge.plus", minutes: 5),
        .init(id: "heart-letter", pillar: .heart, level: 3, title: "A letter that matters", detail: "Write a few honest lines to someone who shaped you. Send it.", why: "Gratitude letters are among the most studied happiness boosts.", symbol: "envelope.fill", minutes: 15),
        // Spirit (the Stillwater)
        .init(id: "spirit-breaths", pillar: .spirit, level: 1, title: "Three slow breaths", detail: "In for four, out for six. Eyes closed if you can.", why: "A longer out-breath calms the body within a minute.", symbol: "wind", minutes: 1, target: 3, unit: "breaths"),
        .init(id: "spirit-quiet", pillar: .spirit, level: 1, title: "A quiet moment", detail: "Two minutes of silence before bed. No phone.", why: "A calm wind-down helps you fall asleep sooner.", symbol: "moon.fill", minutes: 2, target: 2, unit: "min"),
        .init(id: "spirit-gratitude", pillar: .spirit, level: 1, title: "Three good things", detail: "Write three good things from today, however small.", why: "Noticing good moments trains attention away from worry.", symbol: "sparkles", minutes: 3, target: 3, unit: "things"),
        .init(id: "spirit-meditate", pillar: .spirit, level: 2, title: "Ten minutes of stillness", detail: "Sit, follow your breath, come back gently each time you drift.", why: "Regular short meditation lowers stress and sharpens focus.", symbol: "figure.mind.and.body", minutes: 10, target: 10, unit: "min"),
        .init(id: "spirit-journal", pillar: .spirit, level: 2, title: "Write it out", detail: "Five minutes of honest writing about how you feel.", why: "Putting feelings into words calms them.", symbol: "book.closed.fill", minutes: 5, target: 5, unit: "min"),
        .init(id: "spirit-sleep", pillar: .spirit, level: 3, title: "To bed on time", detail: "Lights out at the time you chose. Screens away 30 minutes before.", why: "Regular sleep is the foundation every other habit rests on.", symbol: "bed.double.fill", minutes: 30),
        // Craft (Forge Mountain)
        .init(id: "craft-block", pillar: .craft, level: 2, title: "One focused block", detail: "Twenty minutes on one thing that matters. Phone in another room.", why: "One protected block a day beats long sessions you can't keep up.", symbol: "hammer.fill", minutes: 20, target: 20, unit: "min"),
        .init(id: "craft-start", pillar: .craft, level: 1, title: "Five minutes on it", detail: "Start the thing you've been putting off. Just five minutes.", why: "Starting is the hardest part; five minutes is often enough to keep going.", symbol: "play.fill", minutes: 5, target: 5, unit: "min"),
        .init(id: "craft-tidy", pillar: .craft, level: 1, title: "Clear one surface", detail: "Your desk, a shelf, a drawer: just one.", why: "A clear space makes focus easier.", symbol: "tray.fill", minutes: 5),
        .init(id: "craft-plan", pillar: .craft, level: 1, title: "Tomorrow's one thing", detail: "Write the single most important thing for tomorrow.", why: "Deciding the night before makes the morning start itself.", symbol: "checklist", minutes: 2),
        .init(id: "craft-deep", pillar: .craft, level: 3, title: "An hour of deep work", detail: "60 minutes on your most important work, no interruptions.", why: "Deep, undistracted work is where most real progress happens.", symbol: "flame.fill", minutes: 60, target: 60, unit: "min"),
        .init(id: "craft-make", pillar: .craft, level: 2, title: "Make something", detail: "Draw, cook, build, write: 15 minutes making anything.", why: "Making things with your hands and mind is deeply satisfying.", symbol: "paintbrush.fill", minutes: 15, target: 15, unit: "min"),
        // World (the Wilds)
        .init(id: "world-alive", pillar: .world, level: 1, title: "Notice something alive", detail: "Step outside and look closely at one living thing.", why: "A few minutes of real attention to nature lifts the mood.", symbol: "leaf.fill", minutes: 5),
        .init(id: "world-kind", pillar: .world, level: 1, title: "A small kindness", detail: "Do one small kind thing for someone you don't know.", why: "Kindness to strangers raises your own well-being too.", symbol: "hand.raised.fill", minutes: 5),
        .init(id: "world-litter", pillar: .world, level: 1, title: "Pick up three things", detail: "Pick up three pieces of litter on your way.", why: "Small acts of care for shared places add up.", symbol: "trash.fill", minutes: 3, target: 3, unit: "pieces"),
        .init(id: "world-green", pillar: .world, level: 2, title: "Twenty minutes in green", detail: "A park, a garden, a forest: twenty unhurried minutes.", why: "About two hours a week in nature is linked to better health and mood.", symbol: "tree.fill", minutes: 20, target: 20, unit: "min"),
        .init(id: "world-help", pillar: .world, level: 2, title: "Help with something", detail: "Offer your time to someone who needs it today.", why: "Helping others is one of the surest sources of meaning.", symbol: "person.2.fill", minutes: 15),
        .init(id: "world-volunteer", pillar: .world, level: 3, title: "Find a cause", detail: "Look up one local group you could help, and contact them.", why: "Regular volunteering is linked to lasting happiness.", symbol: "globe.europe.africa.fill", minutes: 15),
    ]

    /// Small surprises (the Spark): playful, from the world's lore.
    static let surprises: [(String, String)] = [
        ("A small challenge", "A little fox is curious about kindness: thank someone who rarely hears it."),
        ("The owl's question", "Quill asks: what's one thing you're proud of this week? Say it out loud."),
        ("The heron's pause", "Ilo stands still for a whole minute. Can you, wherever you are?"),
        ("Orrin's spark", "Fix one small broken thing today: a button, a squeaky door, a bug."),
    ]

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
            var pool = all.filter { $0.pillar == p && !avoid.contains($0.id) }
            // Skipped three times in two weeks: one level easier (never shamed, just lighter).
            if let hard = pool.first(where: { j.skipCount($0.title, days: 14) >= 3 }) { lv = max(1, hard.level - 1) }
            pool = pool.filter { j.skipCount($0.title, days: 14) < 3 }
            let atLevel = pool.filter { $0.level == lv }
            let choices = atLevel.isEmpty ? pool : atLevel
            if stable, let habit = choices.first(where: { j.questStreak($0.title) > 0 }) ?? choices.first { return habit }   // the habit stays the same
            return choices.isEmpty ? all.first { $0.pillar == p }! : choices[Int(rng.next() % UInt64(choices.count))]
        }
        // The pillar you rated lowest on Day 1, or lived least lately.
        let weakest = Pillar6.allCases.filter { $0 != main }.min { a, b in
            let ra = j.dayOne[a.rawValue] ?? 1, rb = j.dayOne[b.rawValue] ?? 1
            return ra != rb ? ra < rb : experience(a) < experience(b)
        } ?? .spirit
        let explore = Pillar6.allCases.filter { $0 != main && $0 != weakest }.min { lastDone($0) < lastDone($1) } ?? .world
        var used: Set<String> = []
        func take(_ p: Pillar6, stable: Bool = false) -> QuestDef { let q = pick(p, avoid: used, stable: stable); used.insert(q.id); return q }
        let a = take(main, stable: true), c = take(weakest), d = take(explore)
        let rest = Pillar6.allCases.filter { ![main, weakest, explore].contains($0) }.shuffled(using: &rng)
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
