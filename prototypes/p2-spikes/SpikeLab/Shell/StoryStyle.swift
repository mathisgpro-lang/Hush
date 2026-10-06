// The storybook look of the introduction and every dialogue (Mathis, 2026-10-06: "high end… it should match the
// style of the game now"): painted gold buttons, parchment choices and cards, the Spark's words on a parchment
// scroll in ink, your name written on a plaque, and the hatching as a real moment (a ring of light filling as you
// warm the egg, embers spiralling in, then the burst: flash, shockwave, glowing shards, rays).
import SwiftUI

/// Codex's painted gold plate, stretched to any width (its rounded ends kept).
struct GoldButtonLabel: View {
    let text: String
    /// The plate at a scale where its rounded ends are ~27 points (it's painted at ~4× a button's height).
    private static let plate: UIImage? = UIImage(named: "button-gold.png").flatMap { $0.cgImage }.map { UIImage(cgImage: $0, scale: 4, orientation: .up) }
    var body: some View {
        Text(text).font(.story(19, .semibold)).foregroundStyle(Color(red: 0.3, green: 0.14, blue: 0.04))
            .shadow(color: .white.opacity(0.35), radius: 0, y: 1)
            .frame(maxWidth: .infinity).padding(.vertical, 17)
            .background {
                if let img = Self.plate {
                    Image(uiImage: img).resizable(capInsets: EdgeInsets(top: 0, leading: 27, bottom: 0, trailing: 27), resizingMode: .stretch)
                } else {
                    Capsule().fill(LinearGradient(colors: [Theme.gold, Color(red: 0.95, green: 0.58, blue: 0.28)], startPoint: .top, endPoint: .bottom))
                }
            }
            .shadow(color: Color(red: 1, green: 0.55, blue: 0.2).opacity(0.45), radius: 14, y: 5)
    }
}

/// A choice on parchment: ink words; chosen, it warms and gets a gold-leaf edge and a little wax seal.
struct ParchmentChoice: View {
    let text: String
    var icon: UIImage? = nil
    let selected: Bool
    var compact = false
    var body: some View {
        HStack(spacing: 10) {
            if let icon { Image(uiImage: icon).resizable().scaledToFit().frame(width: compact ? 26 : 34, height: compact ? 26 : 34) }
            Text(text).font(.story(compact ? 15 : 17, selected ? .semibold : .regular)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            if selected {
                Image(uiImage: UIImage(named: "wax-seal.png") ?? UIImage()).resizable().scaledToFit().frame(width: 22, height: 22)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .padding(.horizontal, compact ? 10 : 14).padding(.vertical, compact ? 9 : 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: selected ? [Color(red: 1, green: 0.9, blue: 0.7), Color(red: 0.97, green: 0.8, blue: 0.55)] : [Theme.paperTop, Theme.paperBottom], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color(red: 0.85, green: 0.6, blue: 0.2) : Theme.paperEdge.opacity(0.55), lineWidth: selected ? 2 : 1))
        .shadow(color: .black.opacity(selected ? 0.3 : 0.18), radius: selected ? 8 : 4, y: 3)
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
    }
}

/// The Spark's words on a parchment scroll, written in ink that warms in from ember-script (as if just spoken).
struct StoryBubble: View {
    let text: String
    @State private var shown = false
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(text).font(.story(19)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                    .opacity(shown ? 1 : 0).blur(radius: shown ? 0 : 5)
            }
            .padding(.horizontal, 22).padding(.vertical, 15)
            .background(SheetPaper(corner: 20))
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
            Triangle().fill(Theme.paperBottom).frame(width: 22, height: 12)
                .overlay(Triangle().stroke(Theme.paperEdge.opacity(0.6), lineWidth: 1))
                .offset(y: -1)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.45).delay(0.12)) { shown = true } }
    }
}

nonisolated struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)); p.closeSubpath(); return p
    }
}

/// While you warm the egg: a ring of light fills around it, embers spiral in, the glow deepens.
struct WarmRing: View {
    let warmth: CGFloat          // 0…1
    let holding: Bool
    let size: CGFloat
    var body: some View {
        TimelineView(.animation(paused: !holding && warmth == 0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().stroke(Theme.gold.opacity(0.18), lineWidth: 3).frame(width: size, height: size)
                Circle().trim(from: 0, to: warmth).stroke(AngularGradient(colors: [Theme.gold, Color(red: 1, green: 0.55, blue: 0.2), Theme.gold], center: .center), style: .init(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: size, height: size)
                    .shadow(color: .orange, radius: 6)
                Canvas { ctx, s in
                    guard holding || warmth > 0.01 else { return }
                    let c = CGPoint(x: s.width / 2, y: s.height / 2)
                    for i in 0..<22 {
                        let seed = Double(i) * 1.7
                        let k = (t * (0.55 + Double(i % 5) * 0.08) + seed).truncatingRemainder(dividingBy: 1)   // 0 → 1 inward
                        let ang = seed * 2.4 + k * 2.6
                        let r = Double(size) * (0.95 - 0.55 * k)
                        let p = CGPoint(x: c.x + cos(ang) * r, y: c.y + sin(ang) * r)
                        let a = sin(k * .pi) * Double(0.4 + warmth * 0.6) * (holding ? 1 : 0.4)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)), with: .color(Color(red: 1, green: 0.78, blue: 0.4).opacity(a)))
                    }
                }
                .frame(width: size * 2, height: size * 2)
            }
        }
        .allowsHitTesting(false)
    }
}

/// The burst: a flash, a shockwave rolling out over the world, glowing shell shards thrown out (spinning, falling),
/// embers. Plays once from `start`.
struct HatchBurst: View {
    let start: Date
    let center: CGPoint
    let color: Color
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard t >= 0, t < 2.6 else { return }
                // Flash.
                let flash = max(0, 1 - t / 0.35)
                if flash > 0 { ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash * 0.85))) }
                // Shockwave ring.
                let k = min(1, t / 1.1), r = 30 + 520 * (1 - pow(1 - k, 3))
                ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.55, width: r * 2, height: r * 1.1)),
                           with: .color(Color(red: 1, green: 0.85, blue: 0.55).opacity((1 - k) * 0.8)), lineWidth: 6 * (1 - k) + 1)
                // Shards: dark shell with a glowing inner edge, thrown out and falling.
                for i in 0..<14 {
                    let s = Double(i) * 2.399
                    let speed = 260 + 160 * (0.5 + 0.5 * sin(s * 3.1))
                    let vx = cos(s) * speed, vy = -abs(sin(s)) * speed * 0.9 - 120
                    let x = center.x + vx * t, y = center.y + vy * t + 520 * t * t
                    let rot = Angle(radians: s + t * (4 + Double(i % 3) * 3))
                    let a = max(0, 1 - t / 1.6)
                    guard a > 0 else { continue }
                    var shard = Path()
                    let w = 10 + Double(i % 4) * 5, h = 7 + Double(i % 3) * 5
                    shard.move(to: CGPoint(x: -w / 2, y: -h / 2)); shard.addLine(to: CGPoint(x: w / 2, y: -h / 3))
                    shard.addLine(to: CGPoint(x: w / 3, y: h / 2)); shard.addLine(to: CGPoint(x: -w / 2.5, y: h / 2.2)); shard.closeSubpath()
                    let tr = CGAffineTransform(translationX: x, y: y).rotated(by: rot.radians)
                    ctx.fill(shard.applying(tr), with: .color(Color(red: 0.2, green: 0.12, blue: 0.1).opacity(a)))
                    ctx.stroke(shard.applying(tr), with: .color(color.opacity(a)), lineWidth: 1.6)
                }
                // Embers rising.
                for i in 0..<40 {
                    let s = Double(i) * 12.9898
                    let life = min(1, max(0, (t - Double(i % 8) * 0.04) / 2.2))
                    guard life > 0, life < 1 else { continue }
                    let ang = (sin(s) * 0.5 + 0.5) * .pi * 2
                    let d = 30 + 240 * life * (0.4 + 0.6 * (0.5 + 0.5 * cos(s * 1.3)))
                    let p = CGPoint(x: center.x + cos(ang) * d, y: center.y + sin(ang) * d * 0.6 - 120 * life)
                    let rr = 1.5 + Double(i % 3)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - rr, y: p.y - rr, width: rr * 2, height: rr * 2)), with: .color(Color(red: 1, green: 0.75, blue: 0.35).opacity((1 - life) * 0.9)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
