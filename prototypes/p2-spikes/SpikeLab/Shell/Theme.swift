// The visual identity (P2.6 step 1, decision 135): two fonts, one type scale, one set of colors, used everywhere.
//  - Fraunces (a warm storybook serif, soft) for titles, the Book, the Keepers' words.
//  - Nunito (soft and rounded) for the interface, numbers, XP, the streak, buttons.
// Both are free (SIL Open Font License, Fonts/OFL-*.txt), bundled and registered at launch.
import SwiftUI
import CoreText

enum Theme {
    /// Registers the bundled fonts once (no Info.plist entry needed).
    static func registerFonts() {
        for name in ["Fraunces", "Nunito"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    // Colors of the world (one palette, everywhere).
    static let gold = Color(red: 1, green: 0.78, blue: 0.42)
    static let ember = Color(red: 0.95, green: 0.52, blue: 0.22)
    static let cream = Color(red: 1, green: 0.95, blue: 0.86)
    static let ink = Color(red: 0.27, green: 0.17, blue: 0.1)
    static let night = Color(red: 0.09, green: 0.065, blue: 0.08)
    /// The accent on parchment (a deep ember brown-orange): big numbers, highlights.
    static let accent = Color(red: 0.72, green: 0.36, blue: 0.1)
    static let paperTop = Color(red: 0.98, green: 0.93, blue: 0.82)
    static let paperBottom = Color(red: 0.93, green: 0.85, blue: 0.7)
    static let paperEdge = Color(red: 0.75, green: 0.58, blue: 0.3)
}

/// The one material every sheet is made of (Satchel, Book, Your Flame, a quest's card): warm parchment with a
/// thin gold double rule, so the whole app reads as one object.
struct SheetPaper: View {
    var corner: CGFloat = 28
    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(LinearGradient(colors: [Theme.paperTop, Theme.paperBottom], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Theme.paperEdge.opacity(0.7), lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: corner - 6).stroke(Theme.paperEdge.opacity(0.3), lineWidth: 1).padding(6))
    }
}

extension View {
    /// A card set into the parchment (a slightly deeper page with a faint rule).
    func paperCard(_ corner: CGFloat = 18) -> some View {
        background(RoundedRectangle(cornerRadius: corner).fill(Theme.paperEdge.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Theme.paperEdge.opacity(0.35), lineWidth: 1))
    }
}

extension Font {
    /// Storybook serif (Fraunces): titles, names, the Book, the Keepers.
    static func story(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Fraunces", size: size).weight(weight)
    }
    /// The interface (Nunito): labels, buttons, small text.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .custom("Nunito", size: size).weight(weight)
    }
    /// Numbers that climb (Nunito, heavy, even digits): XP, levels, the streak.
    static func num(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .custom("Nunito", size: size).weight(weight).monospacedDigit()
    }
}
