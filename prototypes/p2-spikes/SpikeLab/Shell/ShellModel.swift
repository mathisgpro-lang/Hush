// The app shell (decision 105): one journey you move through — the intro, home (the cockpit), the road map,
// the worlds. Prototype state only; the real record and engine take over when this moves into app/ (P3).
import SwiftUI

enum Screen: Equatable { case intro, home, map, realm(RealmID) }

enum RealmID: String, CaseIterable, Identifiable {
    case sanctuary, grove, stillwater, highlands, library, wilds, forge, veil
    var id: String { rawValue }

    var name: String {
        switch self {
        case .sanctuary: "The Sanctuary"
        case .grove: "The Whispering Grove"
        case .stillwater: "The Stillwater"
        case .highlands: "The Ascent Highlands"
        case .library: "The Library of Embers"
        case .wilds: "The Wilds"
        case .forge: "Forge Mountain"
        case .veil: "Beyond the Veil"
        }
    }
    var pillar: String {
        switch self {
        case .sanctuary: "Home"
        case .grove: "Heart"
        case .stillwater: "Spirit"
        case .highlands: "Body"
        case .library: "Mind"
        case .wilds: "World"
        case .forge: "Craft"
        case .veil: "???"
        }
    }
    var symbol: String {
        switch self {
        case .sanctuary: "flame.fill"
        case .grove: "heart.fill"
        case .stillwater: "drop.fill"
        case .highlands: "figure.walk"
        case .library: "book.fill"
        case .wilds: "leaf.fill"
        case .forge: "hammer.fill"
        case .veil: "sparkles"
        }
    }
    var color: Color {
        switch self {
        case .sanctuary: Color(red: 1.0, green: 0.7, blue: 0.3)
        case .grove: Color(red: 0.95, green: 0.55, blue: 0.62)
        case .stillwater: Color(red: 0.75, green: 0.82, blue: 0.95)
        case .highlands: Color(red: 1.0, green: 0.55, blue: 0.2)
        case .library: Color(red: 0.5, green: 0.7, blue: 1.0)
        case .wilds: Color(red: 0.55, green: 0.85, blue: 0.45)
        case .forge: Color(red: 0.85, green: 0.6, blue: 0.35)
        case .veil: Color(red: 0.75, green: 0.6, blue: 1.0)
        }
    }
    /// Where it sits on Codex's world map (pixels of the 803 × 1958 painting).
    var mapPoint: CGPoint {
        switch self {
        case .sanctuary: CGPoint(x: 400, y: 1555)
        case .grove: CGPoint(x: 160, y: 905)
        case .stillwater: CGPoint(x: 690, y: 1005)
        case .highlands: CGPoint(x: 610, y: 640)
        case .library: CGPoint(x: 170, y: 470)
        case .wilds: CGPoint(x: 680, y: 400)
        case .forge: CGPoint(x: 450, y: 225)
        case .veil: CGPoint(x: 560, y: 70)
        }
    }
    /// What opens it (shown on locked nodes; Act I and the plan's conditions).
    var opensWhen: String {
        switch self {
        case .sanctuary: ""
        case .grove: "3 days lived"
        case .stillwater: "Spirit light"
        case .highlands: "Body light"
        case .library: "Mind light"
        case .wilds: "World light"
        case .forge: "30 days lived"
        case .veil: "three Beacons"
        }
    }
}

struct Call: Identifiable, Equatable {
    let id: String
    let title: String, detail: String, symbol: String
    let realm: RealmID
    var done = false
    /// Taken from the satchel for today: it then waits in the Sanctuary as an object.
    var chosen = false
    /// How long it takes, shown in the journal.
    var minutes: Int = 5
    /// The painted object it becomes in the world (Codex's props, iteration 2).
    var prop: String {
        if symbol == "sparkle" { return "prop-scroll" }
        switch realm {
        case .grove: return "prop-lantern"
        case .stillwater: return "prop-bloom"
        case .library: return "prop-scroll"
        default: return "prop-crystal"
        }
    }
}

@MainActor @Observable
final class ShellModel {
    var screen: Screen = CommandLine.arguments.contains("-grove") ? .realm(.grove) : CommandLine.arguments.contains("-map") ? .map : (CommandLine.arguments.contains("-skipintro") ? .home : .intro)
    var interest: String = "Be closer to people I love"
    var open: Set<RealmID> = [.sanctuary, .grove]
    var newHere: Set<RealmID> = [.grove]              // the glow + badge: "something new waits here"
    var flameAt: RealmID = .sanctuary
    var calls: [Call] = []
    var light: Int = 0                                // today's light sent into the world
    /// Set when a realm is entered by the map's dive: the realm then opens out of the dive's light.
    var arrivingByDive = false
    /// The guided tour right after the introduction: the Sanctuary's options, the world map, the Grove.
    enum TourStep { case satchel, world, map, grove }
    var tour: TourStep?

    init() {
        makeCalls()
        if CommandLine.arguments.contains("-quests") { for id in ["a", "c", "d"] { toggleChosen(id) } }   // (test: three taken)
    }

    func chose(_ interest: String) {
        self.interest = interest
        makeCalls()
    }

    func makeCalls() {
        let first: Call = switch interest {
        case "Read again": Call(id: "a", title: "Ten pages", detail: "Read ten pages of any book you like.", symbol: "book.fill", realm: .library)
        case "Find calm": Call(id: "a", title: "Three slow breaths", detail: "Sit, close your eyes, breathe in for four, out for six.", symbol: "drop.fill", realm: .stillwater)
        case "Move a little every day": Call(id: "a", title: "A moment outside", detail: "Walk for ten minutes, at an easy pace.", symbol: "figure.walk", realm: .highlands)
        case "Make something / focus": Call(id: "a", title: "One focused block", detail: "Twenty minutes on one thing that matters to you.", symbol: "hammer.fill", realm: .forge)
        case "Spend time in nature": Call(id: "a", title: "Notice something alive", detail: "Step outside and find one living thing to look at closely.", symbol: "leaf.fill", realm: .wilds)
        default: Call(id: "a", title: "A lantern for someone", detail: "Tell someone you love one thing you admire about them.", symbol: "heart.fill", realm: .grove)
        }
        // The day's quests, offered in the satchel (iteration 2): you choose up to three; they wait in the world.
        calls = [first,
                 Call(id: "b", title: "A small challenge", detail: "A little fox is curious about kindness: thank someone who rarely hears it.", symbol: "sparkle", realm: .grove, minutes: 3),
                 Call(id: "c", title: "A quiet moment", detail: "Two minutes of silence by the hearth before bed.", symbol: "moon.fill", realm: .stillwater, minutes: 2),
                 Call(id: "d", title: "Ten minutes outside", detail: "Step out and walk at an easy pace. Notice the sky.", symbol: "figure.walk", realm: .highlands, minutes: 10),
                 Call(id: "e", title: "One page", detail: "Read a single page of something you've been meaning to read.", symbol: "book.fill", realm: .library, minutes: 5)]
    }

    static let maxChosen = 3
    var chosenCount: Int { calls.filter { $0.chosen && !$0.done }.count }
    func toggleChosen(_ id: String) {
        guard let i = calls.firstIndex(where: { $0.id == id }), !calls[i].done else { return }
        if calls[i].chosen {
            // Put back in the satchel: it goes to the end, so the quests still out keep their spots.
            var c = calls.remove(at: i); c.chosen = false; calls.append(c)
        }
        else if chosenCount < Self.maxChosen { calls[i].chosen = true }
    }

    func complete(_ id: String) {
        guard let i = calls.firstIndex(where: { $0.id == id }) else { return }
        calls[i].done = true
        light += 1
    }

    func go(_ s: Screen) {
        if case .realm(let r) = s { newHere.remove(r); flameAt = r }
        if s == .home { flameAt = .sanctuary }
        screen = s
    }
}
