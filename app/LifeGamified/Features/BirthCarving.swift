import SwiftUI

/// The carving, animated live (decision 75: no still photos). Shards of stone fly in from the dark and
/// assemble around a growing fire; the vessel's outline is carved, dust drifts, then it settles.
struct BirthCarving: View {
    let duration: Double
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let p = min(1, tl.date.timeIntervalSince(start) / duration)
                draw(&ctx, size: size, p: p, t: tl.date.timeIntervalSinceReferenceDate)
            }
        }
        .ignoresSafeArea()
        .onAppear { start = .now }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, p: Double, t: Double) {
        let h = size.height * 0.34, w = h * 0.56
        let r = CGRect(x: size.width / 2 - w / 2, y: size.height * 0.44 - h / 2, width: w, height: h)
        let top = CGPoint(x: r.midX, y: r.minY), right = CGPoint(x: r.maxX, y: r.midY)
        let bottom = CGPoint(x: r.midX, y: r.maxY), left = CGPoint(x: r.minX, y: r.midY)
        let corners = [top, right, bottom, left]
        func onOutline(_ u: Double) -> CGPoint {
            let seg = Int(u * 4) % 4, f = u * 4 - Double(Int(u * 4))
            let a = corners[seg], b = corners[(seg + 1) % 4]
            return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
        }

        // Warm glow and the fire growing at the heart.
        let glowR = w * (0.4 + 1.4 * p)
        ctx.fill(Path(ellipseIn: CGRect(x: r.midX - glowR, y: r.midY - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [Color.orange.opacity(0.45 * p), .clear]),
                                       center: CGPoint(x: r.midX, y: r.midY), startRadius: 0, endRadius: glowR))
        var fire = ctx
        fire.blendMode = .plusLighter
        for i in 0..<Int(20 + 60 * p) {
            let ph = (t * 0.7 + Double(i) * 0.618).truncatingRemainder(dividingBy: 1)
            let x = r.midX + sin(t * 2 + Double(i)) * w * 0.05 * ph + (Double(i % 7) - 3) / 3 * w * 0.1 * (1 - ph)
            let y = r.midY + h * 0.15 - ph * h * (0.1 + 0.35 * p)
            let s = w * 0.22 * (1 - ph) * (0.4 + 0.6 * p)
            let col = ph < 0.2 ? Color(red: 1, green: 0.93, blue: 0.7) : Color(red: 1, green: 0.55, blue: 0.18)
            fire.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s * 0.75, width: s, height: s * 1.5)),
                      with: .radialGradient(Gradient(colors: [col.opacity(0.8 * (1 - ph)), .clear]),
                                            center: CGPoint(x: x, y: y), startRadius: 0, endRadius: s * 0.75))
        }

        // Shards fly in from the dark and land on the vessel's outline, staggered.
        let stone = Color(red: 0.84, green: 0.70, blue: 0.50)
        for i in 0..<56 {
            let u = Double(i) / 56
            let target = onOutline(u)
            let angle = Double((i * 97) % 360) * .pi / 180
            let from = CGPoint(x: size.width / 2 + cos(angle) * size.height * 0.7, y: size.height / 2 + sin(angle) * size.height * 0.7)
            let delay = Double((i * 37) % 56) / 56 * 0.55
            let q = max(0, min(1, (p - delay) / 0.4))
            let e = 1 - pow(1 - q, 3)
            let pos = CGPoint(x: from.x + (target.x - from.x) * e, y: from.y + (target.y - from.y) * e)
            let s = 7.0 * (1.4 - 0.4 * e)
            var shard = Path()
            let rot = angle + t * (1 - e) * 3
            for k in 0..<3 {
                let a = rot + Double(k) * 2.1
                let pt = CGPoint(x: pos.x + cos(a) * s, y: pos.y + sin(a) * s)
                k == 0 ? shard.move(to: pt) : shard.addLine(to: pt)
            }
            shard.closeSubpath()
            ctx.fill(shard, with: .color(stone.opacity(0.35 + 0.65 * q)))
        }

        // The outline is carved as the shards settle.
        var outline = Path()
        outline.move(to: top); outline.addLine(to: right); outline.addLine(to: bottom); outline.addLine(to: left); outline.closeSubpath()
        let carve = max(0, min(1, (p - 0.35) / 0.6))
        ctx.stroke(outline.trimmedPath(from: 0, to: carve), with: .color(stone), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        ctx.stroke(outline.trimmedPath(from: 0, to: carve), with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2))

        // Drifting stone dust.
        for i in 0..<40 {
            let ph = (t * 0.15 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let x = r.midX + (Double((i * 53) % 100) - 50) / 50 * w * 1.6
            let y = r.maxY - ph * h * 1.6
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(stone.opacity(0.5 * (1 - ph) * p)))
        }
    }
}

/// Dawn, animated: the Sanctuary rises out of the dark around your newborn Flame.
struct BirthDawn: View {
    let model: AppModel
    @State private var light = 0.0
    @State private var stage = FlameStage()
    var body: some View {
        ZStack {
            SanctuaryView(vitality: 1).opacity(light)
            Color.black.opacity(0.9 * (1 - light)).ignoresSafeArea()
            PixelFlameView(vitality: 0.4 + 0.6 * light, depth: [:], stage: stage)
            VStack {
                Spacer()
                Text("It will never be finished. It will never go out.")
                    .font(Theme.ceremonial(20)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                    .padding(32).padding(.bottom, 40).opacity(light)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 3.0)) { light = 1 }; stage.flare(seconds: 2.0, strength: 0.8) }
    }
}
