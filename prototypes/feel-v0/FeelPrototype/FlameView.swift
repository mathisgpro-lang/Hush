// THROWAWAY feel prototype (M0). Not the app. A procedural stand-in for the real Metal Flame (chapter 03 §B.2).
import SwiftUI

struct FlameView: View {
    let state: FeelState

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                draw(&ctx, size: size, t: t, now: timeline.date)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: geometry

    private func vessel(in size: CGSize) -> (rect: CGRect, outer: Path, cavity: Path) {
        let h = size.height * 0.26
        let w = h * 0.56
        let c = CGPoint(x: size.width / 2, y: size.height * 0.46)
        let r = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
        func diamond(_ inset: CGFloat) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.midX, y: r.minY + inset * 1.6))
            p.addLine(to: CGPoint(x: r.maxX - inset, y: r.midY))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY - inset * 1.6))
            p.addLine(to: CGPoint(x: r.minX + inset, y: r.midY))
            p.closeSubpath()
            return p
        }
        return (r, diamond(0), diamond(w * 0.17))
    }

    /// One vein per pillar: a path rising over the vessel's surface.
    private func vein(_ p: Pillar, in r: CGRect) -> Path {
        let side: CGFloat = p.rawValue % 2 == 0 ? -1 : 1
        let lane = CGFloat(p.rawValue / 2 + 1) / 4.0
        var path = Path()
        let start = CGPoint(x: r.midX, y: r.maxY - r.height * 0.04)
        path.move(to: start)
        let mid = CGPoint(x: r.midX + side * r.width * 0.45 * lane, y: r.midY + r.height * 0.1)
        let end = CGPoint(x: r.midX + side * r.width * 0.12, y: r.minY + r.height * (0.08 + 0.1 * lane))
        path.addCurve(to: end,
                      control1: CGPoint(x: mid.x + side * r.width * 0.1, y: mid.y + r.height * 0.15),
                      control2: CGPoint(x: mid.x, y: mid.y - r.height * 0.25))
        return path
    }

    // MARK: drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double, now: Date) {
        let (r, outer, cavity) = vessel(in: size)
        let flare = max(0, state.flareUntil.timeIntervalSince(now)) / 1.2
        let v = min(1.4, state.vitality + flare * 0.5)

        // Warm glow around the vessel, breathing with Vitality.
        let glowR = r.width * (1.1 + 0.35 * v)
        ctx.fill(Path(ellipseIn: CGRect(x: r.midX - glowR, y: r.midY - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [fireColor.opacity(0.35 * v), .clear]),
                                       center: CGPoint(x: r.midX, y: r.midY), startRadius: 0, endRadius: glowR))

        // Stone vessel.
        ctx.fill(outer, with: .linearGradient(Gradient(colors: [Color(red: 0.86, green: 0.74, blue: 0.56),
                                                                Color(red: 0.55, green: 0.43, blue: 0.30)]),
                                              startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
        ctx.stroke(outer, with: .color(Color(red: 0.35, green: 0.27, blue: 0.18)), lineWidth: 2)
        var facets = Path()
        facets.move(to: CGPoint(x: r.minX, y: r.midY)); facets.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        facets.move(to: CGPoint(x: r.midX, y: r.minY)); facets.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        ctx.stroke(facets, with: .color(Color(red: 0.42, green: 0.32, blue: 0.21).opacity(0.6)), lineWidth: 1)
        ctx.fill(cavity, with: .color(Color(red: 0.08, green: 0.05, blue: 0.04)))

        // Veins: each pillar's motif grows with its Depth.
        for p in Pillar.allCases {
            let len = state.veins[p] ?? 0
            let path = vein(p, in: r).trimmedPath(from: 0, to: len)
            ctx.stroke(path, with: .color(p.color.opacity(0.35)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            ctx.stroke(path, with: .color(p.color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // The fire, clipped to the cavity.
        var fire = ctx
        fire.clip(to: cavity)
        fire.blendMode = .plusLighter
        let count = Int(30 + 70 * min(1, v))
        let base = CGPoint(x: r.midX, y: r.maxY - r.height * 0.22)
        let height = r.height * (0.16 + 0.42 * v)
        let embers = v < 0.3
        for i in 0..<count {
            let phase = (t * (0.5 + 0.35 * v) + Double(i) * 0.618).truncatingRemainder(dividingBy: 1)
            let sway = sin(t * 2.1 + Double(i) * 1.7) * r.width * 0.06 * phase
            let spread = (Double(i % 9) - 4) / 4 * r.width * 0.15 * (1 - phase * 0.8)
            let x = base.x + sway + spread
            let y = base.y - phase * height * (0.6 + 0.4 * Double((i * 7) % 5) / 4)
            let s = r.width * 0.24 * (1 - phase) * (0.5 + 0.5 * min(1, v))
            let col: Color = embers ? Color(red: 0.9, green: 0.25, blue: 0.08)
                : phase < 0.18 ? Color(red: 1, green: 0.93, blue: 0.7)
                : phase < 0.5 ? fireColor : Color(red: 0.85, green: 0.3, blue: 0.1)
            let a = (embers ? 0.55 : 0.75) * (1 - phase)
            fire.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s * 0.75, width: s, height: s * 1.5)),
                      with: .radialGradient(Gradient(colors: [col.opacity(a), .clear]),
                                            center: CGPoint(x: x, y: y), startRadius: 0, endRadius: s * 0.75))
        }

        // Sparks in flight: card → fire → vessel.
        for f in state.flights {
            let p = min(1, now.timeIntervalSince(f.start) / f.duration)
            let target = CGPoint(x: r.midX, y: r.midY)
            let ctrl = CGPoint(x: (f.from.x + target.x) / 2, y: min(f.from.y, target.y) - size.height * 0.18)
            let q = 1 - p
            let pos = CGPoint(x: q * q * f.from.x + 2 * q * p * ctrl.x + p * p * target.x,
                              y: q * q * f.from.y + 2 * q * p * ctrl.y + p * p * target.y)
            let s: CGFloat = f.big ? 22 : 14
            var spark = ctx
            spark.blendMode = .plusLighter
            spark.fill(Path(ellipseIn: CGRect(x: pos.x - s, y: pos.y - s, width: s * 2, height: s * 2)),
                       with: .radialGradient(Gradient(colors: [.white, f.pillar.color, .clear]),
                                             center: pos, startRadius: 0, endRadius: s))
        }
    }

    private var fireColor: Color {
        let mix = state.recentMix
        let total = max(0.0001, mix.values.reduce(0, +))
        var rr = 0.0, gg = 0.0, bb = 0.0
        for (p, w) in mix {
            let c = UIColor(p.color).cgColor.components ?? [1, 0.6, 0.2, 1]
            rr += Double(c[0]) * w; gg += Double(c[1]) * w; bb += Double(c[2]) * w
        }
        let warm = (r: 1.0, g: 0.62, b: 0.22)   // keep the fire a fire: blend toward gold
        return Color(red: 0.55 * warm.r + 0.45 * rr / total,
                     green: 0.55 * warm.g + 0.45 * gg / total,
                     blue: 0.55 * warm.b + 0.45 * bb / total)
    }
}
