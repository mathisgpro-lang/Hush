import Domain

/// Bundled content for Slice 1 (chapter 28 §B.1, catalog v0). Deliberately gentle, safe Paths only:
/// no training or health plans until the Companion's safety contracts are in place (decision 72).
struct PathTemplate: Identifiable, Equatable {
    let id: String
    let pillar: Pillar
    let name: String
    let promise: String
    let stepTitle: String
    let stepDetail: String
}

struct SparkContent: Identifiable, Equatable {
    let id: String
    let pillar: Pillar
    let text: String
}

enum Catalog {
    static let paths: [PathTemplate] = [
        PathTemplate(id: "move", pillar: .body, name: "Move every day", promise: "Your body, awake again.",
                     stepTitle: "A 20-minute walk", stepDetail: "Any pace. Outside if you can."),
        PathTemplate(id: "read", pillar: .mind, name: "Read again", promise: "A quieter, sharper mind.",
                     stepTitle: "Read for 15 minutes", stepDetail: "Any book. Phone in another room."),
        PathTemplate(id: "close", pillar: .heart, name: "Be closer to the people you love", promise: "The people who matter, nearer.",
                     stepTitle: "Reach out to someone", stepDetail: "A call, a message, a moment together."),
        PathTemplate(id: "calm", pillar: .spirit, name: "Find calm", promise: "Space inside the noise.",
                     stepTitle: "Five minutes of quiet", stepDetail: "Sit. Breathe. Let the day settle."),
        PathTemplate(id: "craft", pillar: .craft, name: "Build something of your own", promise: "Work that is truly yours.",
                     stepTitle: "25 minutes of focused work", stepDetail: "One thing that matters. Notifications off."),
        PathTemplate(id: "world", pillar: .world, name: "Care for your world", promise: "Your space, alive and cared for.",
                     stepTitle: "Ten minutes for your space", stepDetail: "Tidy a corner, water a plant, step into nature."),
    ]

    static func path(_ id: String) -> PathTemplate? { paths.first { $0.id == id } }

    static let sparks: [SparkContent] = [
        SparkContent(id: "b1", pillar: .body, text: "Take the stairs every time today"),
        SparkContent(id: "b2", pillar: .body, text: "Walk somewhere you'd normally drive or ride"),
        SparkContent(id: "b3", pillar: .body, text: "Drink a full glass of water before each meal"),
        SparkContent(id: "m1", pillar: .mind, text: "Learn one thing you never understood, and explain it to someone"),
        SparkContent(id: "m2", pillar: .mind, text: "Spend one hour without your phone"),
        SparkContent(id: "m3", pillar: .mind, text: "Write down three ideas before noon"),
        SparkContent(id: "h1", pillar: .heart, text: "Tell someone why you admire them"),
        SparkContent(id: "h2", pillar: .heart, text: "Call someone you haven't spoken to in a year"),
        SparkContent(id: "h3", pillar: .heart, text: "Eat a meal with someone, phones away"),
        SparkContent(id: "s1", pillar: .spirit, text: "Watch the sky change for five minutes, doing nothing else"),
        SparkContent(id: "s2", pillar: .spirit, text: "Write down three things you're grateful for tonight"),
        SparkContent(id: "s3", pillar: .spirit, text: "Do one thing today that scares you a little"),
        SparkContent(id: "c1", pillar: .craft, text: "Finish the task you've been avoiding"),
        SparkContent(id: "c2", pillar: .craft, text: "Make something with your hands"),
        SparkContent(id: "c3", pillar: .craft, text: "Teach someone a skill you have"),
        SparkContent(id: "w1", pillar: .world, text: "Do a kind thing for a stranger, unasked"),
        SparkContent(id: "w2", pillar: .world, text: "Pick up litter on your way somewhere"),
        SparkContent(id: "w3", pillar: .world, text: "Spend twenty minutes among trees"),
    ]

    static func spark(_ id: String) -> SparkContent? { sparks.first { $0.id == id } }
    static var sparkCandidates: [SparkCandidate] { sparks.map { SparkCandidate(id: $0.id, pillar: $0.pillar) } }

    static let firstSpark = (title: "Three slow breaths", detail: "Close your eyes. Breathe in, and out, three times.")
    static let firstSparkKey = "first-spark"

    static let myth = [
        "Every person carries a flame.",
        "Most never see it.",
        "Here, yours is given a vessel.",
    ]

    /// The First Journey (chapter 28 §A.8). Slice 1 lives steps I–II; later steps stay veiled.
    static let journey = ["The Ember", "The Spark", "The Others", "The Voice", "The Chronicle", "The Forge"]
    static let roman = ["I", "II", "III", "IV", "V", "VI"]
}

extension Pillar {
    var name: String { ["Body", "Mind", "Heart", "Spirit", "Craft", "World"][rawValue] }
}
