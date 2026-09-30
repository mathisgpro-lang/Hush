import SwiftUI
import Domain

/// The world, v1 (chapter 29 §A.3). Positions are on a 0–1 map; art will replace the drawn islands (U3/U4).
struct Place: Identifiable {
    let location: Location
    let name: String
    let blurb: String
    let veiledHint: String
    let icon: String
    let color: Color
    let at: CGPoint
    let lore: String
    var id: String { location.id }
}

enum WorldCatalog {
    static let places: [Place] = [
        Place(location: Location(id: "sanctuary", realm: "The Sanctuary", unlock: .always),
              name: "The Sanctuary", blurb: "Home. Ancient ruins, still water, green life. Your hearth.",
              veiledHint: "", icon: "house", color: Color(red: 0.95, green: 0.7, blue: 0.42), at: CGPoint(x: 0.5, y: 0.82),
              lore: "The first builders carved these arches for those who remembered their flame. You are the first in a long time."),
        Place(location: Location(id: "grove", realm: "The Whispering Grove", unlock: .journeyStep(2)),
              name: "The Whispering Grove", blurb: "Lanterns in the trees. Here, everyone gathers for the Ritual.",
              veiledHint: "Opens when you are no longer alone (journey step III).", icon: "tree", color: Color(red: 0.45, green: 0.78, blue: 0.5),
              at: CGPoint(x: 0.25, y: 0.62),
              lore: "Each lantern in the Grove is someone who kept a promise to themselves this week. They shine for each other."),
        Place(location: Location(id: "stillwater", realm: "The Stillwater", unlock: .pillarDepth(.spirit, 12)),
              name: "The Stillwater", blurb: "A lake that reflects the sky, and the one who looks into it.",
              veiledHint: "Opens as your Spirit deepens.", icon: "drop", color: Color(red: 0.55, green: 0.75, blue: 0.95),
              at: CGPoint(x: 0.75, y: 0.62),
              lore: "The old ones came here to be quiet. They said the water only shows the truth to those who are still."),
        Place(location: Location(id: "library", realm: "The Library of Embers", unlock: .pillarDepth(.mind, 12)),
              name: "The Library of Embers", blurb: "Floating books, quiet light, every question ever asked.",
              veiledHint: "Opens as your Mind deepens.", icon: "books.vertical", color: Color(red: 0.45, green: 0.65, blue: 0.95),
              at: CGPoint(x: 0.22, y: 0.38),
              lore: "Every book here was written by a flame that learned something. Some pages are still blank."),
        Place(location: Location(id: "road", realm: "The Proving Road", unlock: .pillarDepth(.body, 12)),
              name: "The Proving Road", blurb: "A path up into the hills. Each step is yours.",
              veiledHint: "Opens as your Body deepens.", icon: "figure.hiking", color: Color(red: 0.95, green: 0.55, blue: 0.3),
              at: CGPoint(x: 0.78, y: 0.38),
              lore: "Travellers carved a mark on this road for every hill they climbed. The marks go higher than anyone can see."),
        Place(location: Location(id: "forge", realm: "The Forge", unlock: .witnessed("milestone:stage-2")),
              name: "The Forge", blurb: "A glowing workshop in the mountain, where flames are forged.",
              veiledHint: "Opens with the Forge (journey step VI).", icon: "hammer", color: Color(red: 0.95, green: 0.45, blue: 0.2),
              at: CGPoint(x: 0.5, y: 0.24),
              lore: "The smith says every flame that reaches the Forge has lived thirty true days. No one has ever cheated the fire."),
        Place(location: Location(id: "wilds", realm: "The Wilds", unlock: .activeDays(90)),
              name: "The Wilds", blurb: "Wide lands. Far away, the lights of other travellers.",
              veiledHint: "Opens after a season of living.", icon: "mountain.2", color: Color(red: 0.6, green: 0.8, blue: 0.55),
              at: CGPoint(x: 0.3, y: 0.1),
              lore: "You are not the only one walking. Out here, you can see their lights on the horizon."),
        Place(location: Location(id: "beyond", realm: "Beyond the Veil", unlock: .activeDays(365)),
              name: "Beyond the Veil", blurb: "No one knows.",
              veiledHint: "No one knows how to get there yet.", icon: "sparkles", color: Color(red: 0.8, green: 0.7, blue: 0.95),
              at: CGPoint(x: 0.72, y: 0.08),
              lore: "…"),
    ]

    /// Paths between places (map order).
    static let paths: [(String, String)] = [("sanctuary", "grove"), ("sanctuary", "stillwater"), ("grove", "library"),
                                            ("stillwater", "road"), ("library", "forge"), ("road", "forge"),
                                            ("forge", "wilds"), ("forge", "beyond")]

    static func place(_ id: String) -> Place? { places.first { $0.id == id } }
}
