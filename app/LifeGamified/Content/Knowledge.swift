import Foundation

/// The Voice v1 (chapter 07, decision 18): curated, cited guidance for each Path. No generative AI:
/// every claim here maps to a named public source, and nothing is a medical prescription.
struct Source: Identifiable, Equatable {
    let id: String
    let title: String
    let publisher: String
    let year: String
    let url: URL
}

struct PathKnowledge {
    let why: String
    let howToStick: [String]
    let sourceIds: [String]
}

enum Knowledge {
    static let sources: [Source] = [
        Source(id: "who-2020", title: "Guidelines on physical activity and sedentary behaviour", publisher: "World Health Organization",
               year: "2020", url: URL(string: "https://www.who.int/publications/i/item/9789240015128")!),
        Source(id: "lally-2010", title: "How are habits formed: modelling habit formation in the real world",
               publisher: "European Journal of Social Psychology (Lally et al.)", year: "2010",
               url: URL(string: "https://doi.org/10.1002/ejsp.674")!),
        Source(id: "holt-lunstad-2010", title: "Social relationships and mortality risk: a meta-analytic review",
               publisher: "PLOS Medicine (Holt-Lunstad et al.)", year: "2010",
               url: URL(string: "https://doi.org/10.1371/journal.pmed.1000316")!),
        Source(id: "goyal-2014", title: "Meditation programs for psychological stress and well-being: a systematic review",
               publisher: "JAMA Internal Medicine (Goyal et al.)", year: "2014",
               url: URL(string: "https://doi.org/10.1001/jamainternmed.2013.13018")!),
        Source(id: "white-2019", title: "Spending at least 120 minutes a week in nature is associated with good health and wellbeing",
               publisher: "Scientific Reports (White et al.)", year: "2019",
               url: URL(string: "https://doi.org/10.1038/s41598-019-44097-3")!),
    ]

    static func source(_ id: String) -> Source? { sources.first { $0.id == id } }

    static let byPath: [String: PathKnowledge] = [
        "move": PathKnowledge(
            why: "The WHO recommends that adults get at least 150 minutes of moderate activity a week, and says any activity is better than none. A brisk daily walk of about 20 minutes already covers most of that.",
            howToStick: ["Walk at the same moment every day, e.g. right after lunch.",
                         "Leave the house without deciding the route; just start.",
                         "If you have a health condition, check with a doctor before stepping up."],
            sourceIds: ["who-2020", "lally-2010"]),
        "read": PathKnowledge(
            why: "Reading is one of the simplest ways to feed a quieter, sharper mind. The hard part isn't the reading. It's making it a daily reflex, which is exactly what this Path trains.",
            howToStick: ["Tie it to something you already do every day (coffee, bed).",
                         "Keep the book where your phone usually is.",
                         "Habits take about two months on average to feel automatic, with wide variation. Missing a day doesn't reset that."],
            sourceIds: ["lally-2010"]),
        "close": PathKnowledge(
            why: "A large review of 148 studies found that people with stronger social relationships had about a 50% higher likelihood of survival over the studies' follow-up. Connection isn't a luxury.",
            howToStick: ["Keep a short list of three people you want to be closer to.",
                         "A two-line message counts. So does a voice note.",
                         "Reach out before you feel ready; the feeling usually follows."],
            sourceIds: ["holt-lunstad-2010", "lally-2010"]),
        "calm": PathKnowledge(
            why: "A systematic review found that mindfulness meditation programs show moderate evidence of improving anxiety, depression and pain. A few quiet minutes a day is a real practice, not a waste of time.",
            howToStick: ["Same place, same time. Sit, set a timer, breathe.",
                         "When your mind wanders, noticing it is the practice.",
                         "If you're struggling with your mental health, please talk to a professional. This practice isn't a replacement."],
            sourceIds: ["goyal-2014", "lally-2010"]),
        "craft": PathKnowledge(
            why: "Work that is truly yours grows through focused, regular sessions rather than rare heroic efforts. This Path builds that rhythm, 25 minutes at a time.",
            howToStick: ["Decide the one thing before you start the timer.",
                         "Notifications off, phone in another room.",
                         "Stop while you still know the next step; it makes tomorrow easier."],
            sourceIds: ["lally-2010"]),
        "world": PathKnowledge(
            why: "A study of about 20,000 people found that spending at least 120 minutes a week in nature was associated with better reported health and wellbeing. Caring for your own space and the places around you counts too.",
            howToStick: ["Ten minutes is enough: one corner, one plant, one walk among trees.",
                         "Pair it with something you enjoy: music, a call, a coffee.",
                         "Notice what changed afterwards. That's the reward."],
            sourceIds: ["white-2019", "lally-2010"]),
    ]
}
