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
    /// The one accent, calm (decision 146, "minimalist and subtle"): a soft champagne gold, used sparingly.
    static let champagne = Color(red: 0.95, green: 0.84, blue: 0.62)
    static let champagneDeep = Color(red: 0.86, green: 0.7, blue: 0.45)
    /// Shadows carry the world's warm hue, never pure black.
    static let warmShadow = Color(red: 0.25, green: 0.12, blue: 0.04)
}

/// One motion language: soft springs, nothing snappy or bouncy-loud.
enum Motion {
    static let soft = Animation.spring(response: 0.45, dampingFraction: 0.9)
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.95)
    static let tap = Animation.spring(response: 0.25, dampingFraction: 0.8)
}

/// The one material every sheet is made of (Satchel, Book, Your Flame, a quest's card): warm parchment with a
/// single hairline of gold and a soft warm shadow, so the whole app reads as one quiet object (decision 146).
struct SheetPaper: View {
    var corner: CGFloat = 28
    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(LinearGradient(colors: [Theme.paperTop, Theme.paperBottom.opacity(0.97)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(Theme.paperEdge.opacity(0.45), lineWidth: 0.75))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 0.5).padding(1).mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)))
            .shadow(color: Theme.warmShadow.opacity(0.22), radius: 18, y: 8)
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
