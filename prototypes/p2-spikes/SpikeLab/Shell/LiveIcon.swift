// The bar's four icons, alive (corrections list #5): small painted objects that breathe on their own and answer a
// tap with a little hop. World: the map scroll floats and its compass star twinkles. Satchel: it breathes with the
// light inside, and hops now and then while quests wait. Book: its gem pulses. Your Flame: the Spark flickers.
// Built from SwiftUI's own repeating animations (no per-frame redraw of the view), so they cost almost nothing.
import SwiftUI

struct LiveIcon: View {
    enum Kind { case world, satchel, book, flame }
    let kind: Kind
    let image: UIImage?
    var calling = false              // something waits here: a livelier idle
    var taps = 0                     // bumps on each tap: the hop

    @State private var idle = false
    @State private var flicker = false

    var body: some View {
        ZStack {
            glow
            Image(uiImage: image ?? UIImage()).resizable().interpolation(PixelMode.world ? .none : .high).scaledToFit().frame(width: 30, height: 26)   // pixel icons stay crisp
                .scaleEffect(x: kind == .flame ? (flicker ? 0.97 : 1.02) : 1,
                             y: kind == .flame ? (flicker ? 1.06 : 0.98) : (kind == .satchel && idle ? 1.035 : 1), anchor: .bottom)
                .rotationEffect(.degrees(rotation), anchor: .bottom)
                .offset(y: kind == .world ? (idle ? -1.5 : 1) : 0)
            sparkle
        }
        .frame(width: 30, height: 26)
        .keyframeAnimator(initialValue: Hop(), trigger: taps) { v, h in
            v.scaleEffect(x: h.sx, y: h.sy, anchor: .bottom).offset(y: h.y)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                SpringKeyframe(-7, duration: 0.14, spring: .snappy)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            }
            KeyframeTrack(\.sy) {
                CubicKeyframe(0.88, duration: 0.06)
                SpringKeyframe(1.1, duration: 0.14, spring: .snappy)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
            KeyframeTrack(\.sx) {
                CubicKeyframe(1.1, duration: 0.06)
                SpringKeyframe(0.94, duration: 0.14, spring: .snappy)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: kind == .world ? 2.6 : 2.2).repeatForever(autoreverses: true)) { idle = true }
            if kind == .flame { withAnimation(.easeInOut(duration: 0.42).repeatForever(autoreverses: true)) { flicker = true } }
        }
        .allowsHitTesting(false)
    }

    private var rotation: Double {
        switch kind {
        case .world: idle ? 3 : -2
        case .book: idle ? -2.5 : 1.5
        case .flame: flicker ? -2 : 2
        case .satchel: calling ? (idle ? 4 : -4) : 0
        }
    }

    /// The light that lives in each object.
    @ViewBuilder private var glow: some View {
        let warm = Color(red: 1, green: 0.62, blue: 0.25)
        Circle().fill(RadialGradient(colors: [warm.opacity(calling ? 0.75 : 0.45), .clear], center: .center, startRadius: 0, endRadius: 22))
            .frame(width: 40, height: 40)
            .opacity(idle ? 1 : 0.45)
            .scaleEffect(kind == .flame && flicker ? 1.12 : 1)
    }

    /// A small twinkle where the object's magic sits (the compass star, the book's gem).
    @ViewBuilder private var sparkle: some View {
        if kind == .world || kind == .book {
            Circle().fill(RadialGradient(colors: [.white.opacity(0.95), Color(red: 1, green: 0.8, blue: 0.4).opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 6))
                .frame(width: 12, height: 12)
                .scaleEffect(idle ? 1.25 : 0.55).opacity(idle ? 1 : 0.35)
                .offset(kind == .world ? CGSize(width: -5, height: 1) : CGSize(width: 3, height: -6))
                .blendMode(.screen)
        }
    }

    private struct Hop { var y: CGFloat = 0; var sx: CGFloat = 1; var sy: CGFloat = 1 }
}
