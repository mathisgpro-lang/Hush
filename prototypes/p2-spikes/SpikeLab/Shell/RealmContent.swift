// What lives in each realm (Plan 2.0 Part 2 §5): its Keeper, its places to explore, what its lights are called and
// what wakes them, and the page the Book writes the first time you come. One table, so the one realm engine
// (RealmScene + RealmView) can run every realm. Spot positions are painting uv (v up), set from each painting.
import Foundation

enum RealmContent {
    /// What the realm's lights are (they relight as you grow in its pillar).
    static func lights(_ r: RealmID) -> String {
        switch r {
        case .grove: "lanterns"
        case .stillwater: "lotus lights"
        case .highlands: "beacon fires"
        case .library: "reading lamps"
        case .wilds: "village windows"
        case .forge: "furnaces"
        default: "lights"
        }
    }

    /// Where your quests wait in each realm (on open ground, clear of its places to explore).
    static func questSpots(_ r: RealmID) -> [SIMD2<Float>]? {
        switch r {
        case .grove: [[0.27, 0.40], [0.73, 0.40], [0.6, 0.29]]
        case .stillwater: [[0.27, 0.39], [0.69, 0.37], [0.6, 0.27]]
        case .highlands: [[0.27, 0.35], [0.74, 0.34], [0.62, 0.275]]
        case .library: [[0.27, 0.36], [0.73, 0.36], [0.6, 0.28]]
        case .wilds: [[0.27, 0.46], [0.76, 0.45], [0.62, 0.33]]
        default: nil
        }
    }

    static func spots(_ r: RealmID) -> [Spot] {
        switch r {
        case .grove: groveSpots
        case .stillwater: [
            Spot(id: "lotus", title: "The Lotus Path", line: "Stepping stones appear one by one, each time you stop and breathe. Today the water is a little clearer.", symbol: "leaf.circle.fill", uv: [0.47, 0.545], action: "Sit by the water (a real calm moment)"),
            Spot(id: "ilo", title: "Ilo", line: "A silver heron on one leg, whispering: “…be still… and you'll see yourself…”", symbol: "bird.fill", uv: [0.86, 0.45]),
            Spot(id: "pavilion", title: "The Pavilion of Breath", line: "Far out on the water, a pavilion floats. One day the path will reach it.", symbol: "wind", uv: [0.62, 0.64]),
            Spot(id: "shore", title: "The Gratitude Shore", line: "Smooth stones you've written on, warm to the touch. Each one, a thing you were grateful for.", symbol: "heart.text.square.fill", uv: [0.15, 0.29]),
        ]
        case .highlands: [
            Spot(id: "stairs", title: "The Foot of the Stairs", line: "Where every road begins. One step today is one stair of the mountain.", symbol: "figure.stairs", uv: [0.5, 0.46], action: "Take a walk (a real Body action)"),
            Spot(id: "brakka", title: "Brakka", line: "An ancient stone tortoise with a small mountain on her back. “The mountain didn't grow in a day. Neither will you. Walk.”", symbol: "tortoise.fill", uv: [0.15, 0.47]),
            Spot(id: "falls", title: "The Waterfall Steps", line: "The waterfalls tumble down the terraces. They roar louder as you grow stronger.", symbol: "drop.triangle.fill", uv: [0.79, 0.6]),
            Spot(id: "summit", title: "The Summit Observatory", line: "Far above, the old observatory watched the First Hearth. Its beacon is still dark.", symbol: "binoculars.fill", uv: [0.66, 0.775]),
        ]
        case .library: [
            Spot(id: "shelf", title: "The Unread Shelf", line: "Books waiting for a reader. Each page you read lights another lamp between the shelves.", symbol: "books.vertical.fill", uv: [0.25, 0.6], action: "Read a few pages (a real Mind action)"),
            Spot(id: "quill", title: "Quill", line: "An owl folded from living paper. “Every question you ask writes a new page. Ask more.”", symbol: "bird.fill", uv: [0.73, 0.54]),
            Spot(id: "reading", title: "The Reading Room", line: "A fireplace among the shelves, cold for years. Reading relights it.", symbol: "flame.fill", uv: [-0.3, 0.38]),
            Spot(id: "lantern", title: "The Lantern of Thought", line: "Atop the tallest tower, the great lantern waits to be lit.", symbol: "lightbulb.max.fill", uv: [0.42, 0.8]),
            Spot(id: "maproom", title: "The Map Room", line: "A great globe and star charts. Each subject or language you learn draws itself here, coast by coast.", symbol: "globe.europe.africa.fill", uv: [1.8, 0.49]),
        ]
        case .wilds: [
            Spot(id: "village", title: "The Empty Village", line: "Cottages with dark windows. Each time you help someone, one window lights up again.", symbol: "house.fill", uv: [0.34, 0.67], action: "Help someone (a real World action)"),
            Spot(id: "mossbeard", title: "Mossbeard", line: "A walking forest-giant with a village of birds in his beard. “Care for a place, and it cares for you back. Simple.”", symbol: "tree.fill", uv: [0.03, 0.56]),
            Spot(id: "river", title: "The River of Return", line: "The river winds back to where it began. Things you plant here come back to you.", symbol: "water.waves", uv: [0.84, 0.29]),
            Spot(id: "lookout", title: "The Far Lookout", line: "From the hill, one day, you'll see other travellers' lights on the horizon.", symbol: "binoculars.fill", uv: [0.76, 0.72]),
        ]
        case .forge: [
            Spot(id: "bench", title: "The Apprentice's Bench", line: "Every focused hour leaves a mark here. The furnaces glow brighter with your work.", symbol: "hammer.fill", uv: [0.32, 0.28], action: "Do a focused block (a real Craft action)"),
            Spot(id: "orrin", title: "Orrin", line: "A soot-black salamander smith with spectacles. “Every hour leaves a mark. I can see yours.”", symbol: "lizard.fill", uv: [0.74, 0.4]),
            Spot(id: "hall", title: "The Hall of Unfinished Work", line: "Your projects take shape here, piece by piece, as you return to them.", symbol: "gearshape.2.fill", uv: [0.2, 0.55]),
            Spot(id: "anvil", title: "The Great Anvil", line: "Where keepsakes are forged at the end of a journey. It hasn't rung in a long time.", symbol: "seal.fill", uv: [0.58, 0.22]),
        ]
        default: []
        }
    }

    /// The Book's page the first time you come (decision 129).
    static func firstVisit(_ r: RealmID) -> (title: String, text: String)? {
        switch r {
        case .grove: ("Into the Whispering Grove", "You dived into the Grove for the first time. Giant trees full of lanterns, most of them dark. From somewhere in the roots, two small voices whispered: “Someone came.” Nim and Ro had been waiting a long time.")
        case .stillwater: ("The Stillwater", "You came to a lake so still it held the whole sky. On one leg in the shallows stood a silver heron. It didn't move. It only whispered: “…you found us…”")
        case .highlands: ("The foot of the mountain", "You stood at the foot of the wind-carved stairs. Waterfalls thundered on every side. A great stone tortoise opened one eye, looked at you for a long time, and said: “Good. Now walk.”")
        case .library: ("The Library of Embers", "Books drifted over your head like birds. A paper owl landed on the nearest shelf, ruffled its pages, and asked: “Did you bring a question? Everyone brings a question.”")
        case .wilds: ("Into the Wilds", "Meadows, a winding river, and a village where no window was lit. Somewhere behind you, a tree laughed. It was not a tree. It was Mossbeard, and birds were living in his beard.")
        case .forge: ("Forge Mountain", "The mountain breathed heat. Somewhere deep inside, a hammer rang once, then stopped. A small black salamander pushed up its spectacles: “Another apprentice. Let's see your hands.”")
        default: nil
        }
    }
}
