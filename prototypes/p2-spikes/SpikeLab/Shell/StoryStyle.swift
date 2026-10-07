// The storybook look of the introduction and every dialogue (Mathis, 2026-10-06: "high end… it should match the
// style of the game now"): painted gold buttons, parchment choices and cards, the Spark's words on a parchment
// scroll in ink, your name written on a plaque, and the hatching as a real moment (a ring of light filling as you
// warm the egg, embers spiralling in, then the burst: flash, shockwave, glowing shards, rays).
import SwiftUI

/// The primary action: a slim champagne pill sized to its words, a hairline edge, a soft warm shadow (decision 146:
/// quiet and precise, never a loud full-width slab).
struct GoldButtonLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.story(18, .medium)).foregroundStyle(Color(red: 0.27, green: 0.15, blue: 0.06))
            .padding(.horizontal, 34).frame(minWidth: 200).frame(height: 52)
            .background(Capsule(style: .continuous).fill(LinearGradient(colors: [Color(red: 1, green: 0.93, blue: 0.78), Theme.champagne], startPoint: .top, endPoint: .bottom)))
            .overlay(Capsule(style: .continuous).stroke(Theme.champagneDeep.opacity(0.9), lineWidth: 0.75))
            .overlay(Capsule(style: .continuous).stroke(.white.opacity(0.7), lineWidth: 0.75).padding(1.5).mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)))
            .shadow(color: Theme.warmShadow.opacity(0.35), radius: 14, y: 6)
            .shadow(color: Theme.champagne.opacity(0.25), radius: 20)
    }
}

/// The quiet second action: words only, a hairline under them.
struct QuietLink: View {
    let text: String
    var body: some View {
        Text(text).font(.ui(15, .medium)).foregroundStyle(Theme.cream.opacity(0.72))
            .padding(.vertical, 10).padding(.horizontal, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.cream.opacity(0.25)).frame(height: 0.5).padding(.horizontal, 12).offset(y: -6) }
    }
}

/// A choice on parchment: ink words; chosen, it warms and gets a gold-leaf edge and a little wax seal.
struct ParchmentChoice: View {
    let text: String
    var icon: UIImage? = nil
    let selected: Bool
    var compact = false
    var body: some View {
        HStack(spacing: 9) {
            if let icon { Image(uiImage: icon).resizable().scaledToFit().frame(width: compact ? 22 : 26, height: compact ? 22 : 26).opacity(selected ? 1 : 0.85) }
            if compact {                                         // a short word: centred on one line
                Text(text).font(.story(15, selected ? .medium : .regular)).foregroundStyle(Theme.ink.opacity(selected ? 1 : 0.82))
                    .lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth: .infinity)
            } else {
                Text(text).font(.story(16)).fontWeight(selected ? .medium : .regular).foregroundStyle(Theme.ink.opacity(selected ? 1 : 0.82))
                    .lineLimit(1).fixedSize().layoutPriority(1)   // one line, one size, never cut, in every card
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, compact ? 12 : 14)
        .frame(height: compact ? 42 : 52)                     // every card the same height
        .overlay(alignment: .topTrailing) {                   // chosen: a small gold mark in the corner
            if !compact { Circle().fill(Theme.champagneDeep).frame(width: 6, height: 6).padding(8).opacity(selected ? 1 : 0) }
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(selected ? Color(red: 1, green: 0.92, blue: 0.76) : Color.white.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Theme.champagneDeep : Theme.paperEdge.opacity(0.28), lineWidth: selected ? 1 : 0.6))
        .animation(Motion.tap, value: selected)
    }
}

/// The Spark's words on a parchment scroll, written in ink that warms in from ember-script (as if just spoken).
struct StoryBubble: View {
    let text: String
    @State private var shown = false
    var body: some View {
        Text(text).font(.story(20).italic()).foregroundStyle(Theme.cream).multilineTextAlignment(.center).lineSpacing(3)
            .shadow(color: Theme.warmShadow.opacity(0.9), radius: 6)
            .padding(.horizontal, 26).padding(.vertical, 18)
            .background(Ellipse().fill(Color.black.opacity(0.32)).padding(.horizontal, -10).blur(radius: 26))   // a soft shade, no edge
            .opacity(shown ? 1 : 0).blur(radius: shown ? 0 : 6).offset(y: shown ? 0 : 6)
            .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.1)) { shown = true } }
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
    static let shards: [UIImage] = (0..<8).compactMap { UIImage(named: "shard-\($0).png") }
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
                if flash > 0 { ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 1, green: 0.95, blue: 0.85).opacity(flash * 0.5))) }
                // Shockwave ring.
                let k = min(1, t / 1.1), r = 30 + 520 * (1 - pow(1 - k, 3))
                ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.55, width: r * 2, height: r * 1.1)),
                           with: .color(Color(red: 1, green: 0.88, blue: 0.62).opacity((1 - k) * 0.4)), lineWidth: 2.5 * (1 - k) + 0.5)
                // Shards: dark shell with a glowing inner edge, thrown out and falling.
                for i in 0..<8 {
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
                    if !Self.shards.isEmpty {                           // Codex's painted shell shards
                        let img = ctx.resolve(Image(uiImage: Self.shards[i % Self.shards.count]))
                        ctx.drawLayer { l in
                            l.opacity = a
                            l.translateBy(x: x, y: y); l.rotate(by: rot)
                            let k = 0.55 + Double(i % 3) * 0.15
                            l.draw(img, in: CGRect(x: -22 * k, y: -22 * k, width: 44 * k, height: 44 * k))
                        }
                    } else {
                        let tr = CGAffineTransform(translationX: x, y: y).rotated(by: rot.radians)
                        ctx.fill(shard.applying(tr), with: .color(Color(red: 0.2, green: 0.12, blue: 0.1).opacity(a)))
                        ctx.stroke(shard.applying(tr), with: .color(color.opacity(a)), lineWidth: 1.6)
                    }
                }
                // Embers rising.
                for i in 0..<24 {
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
