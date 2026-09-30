import SwiftUI
import Domain

extension Pillar {
    /// Pillar colors (chapter 12 §A.4).
    var color: Color {
        switch self {
        case .body: Color(red: 0.91, green: 0.46, blue: 0.17)
        case .mind: Color(red: 0.29, green: 0.61, blue: 0.88)
        case .heart: Color(red: 0.85, green: 0.55, blue: 0.48)
        case .spirit: Color(red: 0.90, green: 0.91, blue: 0.94)
        case .craft: Color(red: 0.72, green: 0.54, blue: 0.23)
        case .world: Color(red: 0.37, green: 0.66, blue: 0.35)
        }
    }
    var toneHz: Double { [98, 523, 196, 659, 330, 262][rawValue] }
    var sharpness: Float { [0.25, 0.85, 0.35, 0.15, 0.95, 0.5][rawValue] }
}

/// Stone Era theme tokens (chapter 12 §A.3–A.4, decision 35). Screens read these, never raw values.
enum Theme {
    static let dawn = Color(red: 0.95, green: 0.70, blue: 0.42)
    static let gain = Color(red: 1.0, green: 0.80, blue: 0.50)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static func ceremonial(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static let flight = 0.7
    static let hold = 0.25
}
