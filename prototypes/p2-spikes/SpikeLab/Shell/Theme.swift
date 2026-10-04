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
