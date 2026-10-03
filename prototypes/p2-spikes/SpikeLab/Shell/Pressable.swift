// Instant press feedback (Duolingo/Finch-speed reactivity): every button squishes the moment your finger touches it,
// with a light haptic tap, before you even lift it, and springs back. Applied to the whole app from the shell.
import SwiftUI
import UIKit

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down { Haptic.touch() }
            }
    }
}

enum Haptic {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    static func touch() { light.impactOccurred(intensity: 0.7); light.prepare() }
}

/// The app's motion timing: quick and springy, like the best mobile games (screens ~0.3 s, sheets ~0.32 s).
extension Animation {
    static let screen = Animation.snappy(duration: 0.3)
    static let sheet = Animation.spring(response: 0.32, dampingFraction: 0.86)
}
