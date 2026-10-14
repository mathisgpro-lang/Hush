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

    // MARK: Daily intentions (decision 166, Mathis: "showing up every day for tasks which participate to all pillars,
    // regardless of what they are"). Each pillar is one intention you fulfil your own way (your sport counts); the
    // library above becomes its ideas, for when you don't know where to start, and they climb slowly with the days
    // you keep that pillar (the ladder lives in the ideas, not in the quest).
    struct Intention { let pillar: Pillar6; let title, detail, why, symbol: String }
    static let intentions: [Intention] = [
        .init(pillar: .body, title: "Move your body", detail: "Any movement counts: your sport, the gym, a walk, a ride, a dance.", why: "Moving every day, in any way, is the strongest habit there is for body and mood.", symbol: "figure.run"),
        .init(pillar: .mind, title: "Feed your mind", detail: "Read, learn, practise: anything that makes you think.", why: "A mind fed a little every day stays sharp and curious for life.", symbol: "book.fill"),
        .init(pillar: .spirit, title: "Find your calm", detail: "Meditate, breathe, journal, or walk without your phone.", why: "A few calm minutes every day lower stress and steady you for everything else.", symbol: "figure.mind.and.body"),
        .init(pillar: .world, title: "One for the planet", detail: "One sustainable act: refuse plastic, walk instead of driving, eat plants, pick up litter.", why: "Small acts, repeated every day by many people, are how the planet heals.", symbol: "leaf.fill"),
        .init(pillar: .heart, title: "Reach out", detail: "Someone you love, a friend, a stranger: one real moment of connection.", why: "Close relationships are the strongest predictor of a long, happy life.", symbol: "heart.fill"),
        .init(pillar: .craft, title: "Work on your craft", detail: "Time on the thing you're building or getting better at.", why: "A little focused work every day is how skills and projects grow.", symbol: "hammer.fill"),
    ]
    /// On your list every day: the four core pillars (Body, Mind, Spirit, the planet) and any milestone challenge.
    static func onTheList(_ id: String) -> Bool { core.map(\.rawValue).contains(id) || id.hasPrefix("special-") }
    /// Days you've kept a pillar (one per day, whatever you did).
    static func daysKept(_ p: Pillar6, _ j: Journey) -> Int {
        Set(j.deeds.filter { Pillar6.of(RealmID(rawValue: $0.realm) ?? .grove) == p }.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    /// The level of a pillar's ideas: easy for the first two weeks kept, steady until ~45 days, then stretch.
    static func ideaLevel(_ p: Pillar6, _ j: Journey) -> Int { let d = daysKept(p, j); return d < 14 ? 1 : d < 45 ? 2 : 3 }
    /// Three ideas for a pillar today, at your level (the same three all day).
    static func ideas(for p: Pillar6, journey j: Journey, on date: Date = Date()) -> [QuestDef] {
        let lv = ideaLevel(p, j)
        let usable = all.filter { q in q.pillar == p && !(q.once && j.deeds.contains { $0.title == q.title }) }
        var pool = usable.filter { $0.level == lv }
        if pool.count < 3 { pool += usable.filter { $0.level == lv - 1 || $0.level == lv + 1 } }
        let salt = UInt64(p.rawValue.unicodeScalars.reduce(0) { $0 + Int($1.value) })      // (stable across launches)
        var rng = SeededRandom(seed: UInt64(max(1, j.dayNumber(of: date))) &* 7919 &+ salt)
        return Array(pool.shuffled(using: &rng).prefix(3))
    }
    /// Milestone challenges (Mathis): offered once they've opened (by the days you've kept their pillar), until done.
    static let specials: [(id: String, quest: String, pillar: Pillar6, afterDays: Int)] = [
        ("special-opal", "mind-opal", .mind, 6),
        ("special-bedroom", "spirit-bedroom", .spirit, 20),
    ]

    /// Today's list (deterministic for the day): the six intentions (four on your list, Heart and Craft in the
    /// satchel), any milestone challenge that has opened, and a surprise from the world in the satchel.
    static func today(journey j: Journey, interest: String, on date: Date = Date()) -> [Call] {
        var rng = SeededRandom(seed: UInt64(max(1, j.dayNumber(of: date))) &* 2654435761)
        var calls: [Call] = intentions.map { i in
            var c = Call(id: i.pillar.rawValue, title: i.title, detail: i.detail, symbol: i.symbol, realm: i.pillar.realm, minutes: 10,
                         difficulty: "Your way", reason: i.why)
            c.pillar = i.pillar
            return c
        }
        for s in specials where daysKept(s.pillar, j) >= s.afterDays {
            guard let q = all.first(where: { $0.id == s.quest }), !j.deeds.contains(where: { $0.title == q.title }) else { continue }
            calls.append(Call(id: s.id, title: q.title, detail: q.detail, symbol: q.symbol, realm: q.realm, minutes: q.minutes,
                              difficulty: "Challenge", reason: "A new challenge has opened. " + q.why))
        }
        let s = surprises[Int(rng.next() % UInt64(surprises.count))]
        calls.append(Call(id: "b", title: s.0, detail: s.1, symbol: "sparkle", realm: .grove, minutes: 5, reason: "A surprise from the world."))
        return calls
    }
}

extension Journey {
    /// How many times a quest was skipped in the last days (the picker lightens it after three).
    func skipCount(_ title: String, days: Int) -> Int {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return (skipLog[title] ?? []).filter { $0 >= since }.count
    }
}
