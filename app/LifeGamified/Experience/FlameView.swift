import SwiftUI
import Observation
import Domain

/// Live animation state around the Flame (sparks in flight, flares). Not truth: truth is the record.
@Observable
final class FlameStage {
    struct Flight: Identifiable {
        let id = UUID()
        let from: CGPoint
        let pillar: Pillar
        let start: Date
        let duration: Double
        let big: Bool
    }
    var flights: [Flight] = []
    var flareUntil = Date.distantPast
    var flareStrength = 0.6

    func launch(from point: CGPoint, pillar: Pillar, big: Bool) {
        flights.append(Flight(from: point, pillar: pillar, start: .now, duration: Theme.flight, big: big))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Theme.flight + 0.1))
            self.flights.removeAll { $0.start.addingTimeInterval($0.duration) < .now }
        }
    }

    func flare(seconds: Double, strength: Double = 0.6) {
        flareUntil = .now.addingTimeInterval(seconds)
        flareStrength = strength
    }
}

/// The Flame (chapter 03): a living fire in a Stone Era vessel. Depth draws the pillar veins,
/// Vitality drives the fire, recent living tints it. Uses Codex's layered art when present, otherwise
/// a procedural vessel (chapter 03 §B.5 will replace this with the full Metal renderer).
struct FlameView: View {
    let vitality: Double
    let depth: [Pillar: Double]
    let recentMix: [Pillar: Double]
    let stage: FlameStage
    var era: Int = 1
    var center: CGFloat = 0.46
    var height: CGFloat = 0.26
    var shake: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                draw(&ctx, size: size, t: timeline.date.timeIntervalSinceReferenceDate, now: timeline.date)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let strongest = depth.sorted { $0.value > $1.value }.prefix(2).map(\.key.name).joined(separator: " and ")
        let fire = vitality > 0.8 ? "burns bright" : vitality > 0.25 ? "burns calmly" : "rests in embers"
        return "Your Flame: a carved stone vessel\(strongest.isEmpty ? "" : ", richest in \(strongest)"). The fire \(fire)."
    }

    // MARK: geometry

    private func vesselRect(_ size: CGSize) -> CGRect {
        let h = size.height * height
        let w = h * 0.56
        return CGRect(x: size.width / 2 - w / 2, y: size.height * center - h / 2, width: w, height: h)
    }

    private func diamond(_ r: CGRect, inset: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY + inset * 1.6))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - inset * 1.6))
        p.addLine(to: CGPoint(x: r.minX + inset, y: r.midY))
        p.closeSubpath()
        return p
    }

    private func vein(_ p: Pillar, in r: CGRect) -> Path {
        let side: CGFloat = p.rawValue % 2 == 0 ? -1 : 1
        let lane = CGFloat(p.rawValue / 2 + 1) / 4.0
        var path = Path()
        path.move(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.04))
        let mid = CGPoint(x: r.midX + side * r.width * 0.45 * lane, y: r.midY + r.height * 0.1)
        let end = CGPoint(x: r.midX + side * r.width * 0.12, y: r.minY + r.height * (0.08 + 0.1 * lane))
        path.addCurve(to: end,
                      control1: CGPoint(x: mid.x + side * r.width * 0.1, y: mid.y + r.height * 0.15),
                      control2: CGPoint(x: mid.x, y: mid.y - r.height * 0.25))
        return path
    }

    /// Permanent growth: a vein's length grows with absolute Depth and never recedes (Codex review B1).
    private func veinLength(_ p: Pillar) -> Double {
        let d = depth[p] ?? 0
        guard d > 0 else { return 0 }
        return min(1, 0.08 + 0.92 * (1 - exp(-d / 40)))
    }

    // MARK: drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double, now: Date) {
        var r = vesselRect(size)
        if shake > 0 { r = r.offsetBy(dx: sin(t * 60) * 4 * shake, dy: cos(t * 47) * 2 * shake) }
        let outer = diamond(r, inset: 0)
        let cavity = diamond(r, inset: r.width * 0.17)
        let flare = max(0, stage.flareUntil.timeIntervalSince(now)) * stage.flareStrength
        let v = min(1.5, vitality + flare * 0.5)

        let glowR = r.width * (1.1 + 0.4 * v)
        ctx.fill(Path(ellipseIn: CGRect(x: r.midX - glowR, y: r.midY - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [fireColor.opacity(0.35 * min(1, v)), .clear]),
                                       center: CGPoint(x: r.midX, y: r.midY), startRadius: 0, endRadius: glowR))

        if let body = UIImage(named: era >= 2 ? "vessel-body-metal" : "vessel-body") {
            // Codex layered art (chapter 03 §B.5); image framing: vessel ≈ 80% of canvas height.
            let scale = r.height / (CGFloat(body.size.height) * 0.8)
            let w = CGFloat(body.size.width) * scale, h = CGFloat(body.size.height) * scale
            let frame = CGRect(x: r.midX - w / 2, y: r.midY - h / 2, width: w, height: h)
            // The live fire burns BEHIND the carved body; the keyed (transparent) cavity lets it shine through.
            var behind = ctx
            behind.clip(to: diamond(r, inset: 0))
            drawFire(&behind, r: r, cavity: cavity, t: t, v: v, clipToCavity: false)
            ctx.draw(Image(uiImage: body), in: frame)
            var veins = ctx
            veins.blendMode = .plusLighter
            for p in Pillar.allCases where veinLength(p) > 0 {
                let path = vein(p, in: r).trimmedPath(from: 0, to: veinLength(p))
                veins.stroke(path, with: .color(p.color.opacity(0.25)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                veins.stroke(path, with: .color(p.color.opacity(0.9)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        } else {
            let material = era >= 2
                ? [Color(red: 0.62, green: 0.48, blue: 0.30), Color(red: 0.22, green: 0.20, blue: 0.22)]   // forged bronze and steel
                : [Color(red: 0.86, green: 0.74, blue: 0.56), Color(red: 0.55, green: 0.43, blue: 0.30)]   // carved sandstone
            ctx.fill(outer, with: .linearGradient(Gradient(colors: material),
                                                  startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
            ctx.stroke(outer, with: .color(era >= 2 ? Color(red: 0.43, green: 0.66, blue: 0.86) : Color(red: 0.35, green: 0.27, blue: 0.18)),
                       lineWidth: era >= 2 ? 2.5 : 2)
            var facets = Path()
            facets.move(to: CGPoint(x: r.minX, y: r.midY)); facets.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            facets.move(to: CGPoint(x: r.midX, y: r.minY)); facets.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            ctx.stroke(facets, with: .color(Color(red: 0.42, green: 0.32, blue: 0.21).opacity(0.6)), lineWidth: 1)
            ctx.fill(cavity, with: .color(Color(red: 0.08, green: 0.05, blue: 0.04)))
            for p in Pillar.allCases where veinLength(p) > 0 {
                let path = vein(p, in: r).trimmedPath(from: 0, to: veinLength(p))
                ctx.stroke(path, with: .color(p.color.opacity(0.35)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                ctx.stroke(path, with: .color(p.color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            drawFire(&ctx, r: r, cavity: cavity, t: t, v: v, clipToCavity: true)
        }

        for f in stage.flights {
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

    private func drawFire(_ ctx: inout GraphicsContext, r: CGRect, cavity: Path, t: Double, v: Double, clipToCavity: Bool) {
        var fire = ctx
        if clipToCavity { fire.clip(to: cavity) }
        fire.blendMode = .plusLighter
        let embers = v < 0.3
        let count = Int(30 + 70 * min(1, v))
        let base = CGPoint(x: r.midX, y: r.maxY - r.height * 0.22)
        let height = r.height * (0.16 + 0.42 * min(1.2, v))
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
    }

    /// The fire's color: gold, tinted by what you've lived lately (chapter 03 §A.2).
    private var fireColor: Color {
        let total = recentMix.values.reduce(0, +)
        guard total > 0 else { return Color(red: 1, green: 0.62, blue: 0.22) }
        var rr = 0.0, gg = 0.0, bb = 0.0
        for (p, w) in recentMix {
            let c = UIColor(p.color).cgColor.components ?? [1, 0.6, 0.2, 1]
            rr += Double(c[0]) * w; gg += Double(c[1]) * w; bb += Double(c[2]) * w
        }
        return Color(red: 0.55 + 0.45 * rr / total * 0.8, green: 0.34 + 0.45 * gg / total * 0.6,
                     blue: 0.12 + 0.45 * bb / total * 0.5)
    }
}

/// The Sanctuary behind the Flame, breathing with Vitality: calm blue dusk when low, never dark.
struct SanctuaryView: View {
    let vitality: Double
    var era: Int = 1
    var body: some View {
        GeometryReader { geo in
            ZStack {
                layer(era >= 2 && UIImage(named: "sanctuary-metal") != nil ? "sanctuary-metal" : "sanctuary-stone", geo)
                layer(era >= 2 && UIImage(named: "sanctuary-metal-embers") != nil ? "sanctuary-metal-embers" : "sanctuary-stone-embers", geo)
                    .opacity(max(0, min(1, (0.9 - vitality) / 0.6)))
                if era >= 2 && UIImage(named: "sanctuary-metal") == nil {
                    Color(red: 0.25, green: 0.45, blue: 0.7).opacity(0.12).blendMode(.overlay)   // placeholder Metal tint
                }
                LinearGradient(colors: [.black.opacity(0.35), .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            }
            .animation(.easeInOut(duration: 1.2), value: vitality)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder private func layer(_ name: String, _ geo: GeometryProxy) -> some View {
        if let img = UIImage(named: name) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(1.3, anchor: .bottom)
                .clipped()
        } else {
            Color(red: 0.23, green: 0.18, blue: 0.29)
        }
    }
}
