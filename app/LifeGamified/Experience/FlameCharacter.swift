import SwiftUI
import Domain

/// Your Flame, personified (decisions 79–80): an original cartoon flame character that represents you.
/// Drawn live so it can breathe, blink and react. Mood follows Vitality; it cheers when you complete
/// something (FlameStage flare), sleeps in embers, and grows more flame tips as your Depth grows.
struct FlameCharacter: View {
    let vitality: Double
    let totalDepth: Double
    let stage: FlameStage
    var era: Int = 1
    var center: CGFloat = 0.45
    var height: CGFloat = 0.22

    enum Mood { case joyful, happy, calm, sleepy }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in draw(&ctx, size: size, now: tl.date) }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        switch mood(now: .now) {
        case .joyful: "Your Flame is cheering."
        case .happy: "Your Flame is bright and happy."
        case .calm: "Your Flame is calm."
        case .sleepy: "Your Flame is resting in embers, waiting for you."
        }
    }

    private func mood(now: Date) -> Mood {
        if stage.flareUntil > now { return .joyful }
        if vitality > 0.7 { return .happy }
        if vitality > 0.3 { return .calm }
        return .sleepy
    }

    /// Evolution: more flame tips as Depth grows (3 → 5), the first visible form of growth.
    private var tips: Int { totalDepth < 20 ? 3 : totalDepth < 80 ? 4 : 5 }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let t = now.timeIntervalSinceReferenceDate
        let m = mood(now: now)
        let cheer = max(0, stage.flareUntil.timeIntervalSince(now))
        let sleepy = m == .sleepy
        let scale: CGFloat = sleepy ? 0.8 : 1
        let h = size.height * height * scale
        let w = h * 0.86
        // Idle breathing (squash and stretch) and a hop when cheering.
        let breath = sin(t * (sleepy ? 1.2 : 2.4)) * (sleepy ? 0.015 : 0.03)
        let hop = m == .joyful ? abs(sin(cheer * 6)) * h * 0.18 : 0
        let footY = size.height * center + h * 0.5
        let bodyH = h * (1 + breath), bodyW = w * (1 - breath * 0.8)
        let origin = CGPoint(x: size.width / 2 - bodyW / 2, y: footY - bodyH - hop)
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: origin.x + bodyW * x, y: origin.y + bodyH * y) }

        // Colors: warmer and deeper when sleepy; a forged-era sheen after the Forge.
        let deep = sleepy ? Color(red: 0.75, green: 0.22, blue: 0.10) : Color(red: 0.98, green: 0.36, blue: 0.08)
        let bright = sleepy ? Color(red: 0.95, green: 0.50, blue: 0.20) : Color(red: 1.0, green: 0.72, blue: 0.18)
        let core = Color(red: 1.0, green: 0.88, blue: 0.45)

        // Soft ground shadow and glow.
        let shadowW = bodyW * (0.9 - hop / h * 0.6)
        ctx.fill(Path(ellipseIn: CGRect(x: size.width / 2 - shadowW / 2, y: footY - h * 0.03, width: shadowW, height: h * 0.07)),
                 with: .color(Color(red: 0.25, green: 0.12, blue: 0.35).opacity(0.55)))
        let glowR = bodyW * (1.1 + 0.3 * min(1, vitality))
        let gc = CGPoint(x: size.width / 2, y: origin.y + bodyH * 0.55)
        ctx.fill(Path(ellipseIn: CGRect(x: gc.x - glowR, y: gc.y - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [Color.orange.opacity(0.35 * (sleepy ? 0.4 : 1)), .clear]),
                                       center: gc, startRadius: 0, endRadius: glowR))

        // Feet and arms (little rounded nubs).
        let limb = deep
        for side in [-1.0, 1.0] {
            ctx.fill(Path(roundedRect: CGRect(x: size.width / 2 + side * bodyW * 0.16 - bodyW * 0.07, y: footY - hop - h * 0.06,
                                              width: bodyW * 0.14, height: h * 0.10), cornerRadius: bodyW * 0.05), with: .color(limb))
            let armUp = m == .joyful ? -0.9 : m == .happy ? -0.2 + sin(t * 2) * 0.1 : 0.35
            var arm = Path()
            let shoulder = P(0.5 + side * 0.42, 0.62)
            arm.move(to: shoulder)
            arm.addLine(to: CGPoint(x: shoulder.x + side * bodyW * 0.18, y: shoulder.y + bodyH * 0.18 * armUp))
            ctx.stroke(arm, with: .color(limb), style: StrokeStyle(lineWidth: bodyW * 0.1, lineCap: .round))
        }

        // The body: a rounded flame with flickering tips.
        var body = Path()
        body.move(to: P(0.5, 1.0))
        body.addCurve(to: P(0.02, 0.62), control1: P(0.18, 1.0), control2: P(0.0, 0.85))
        let n = tips
        var prev = P(0.02, 0.62)
        for i in 0..<n {
            let f = (Double(i) + 0.5) / Double(n)
            let isCenter = abs(f - 0.5) < 0.15
            let tipH = isCenter ? 0.0 : 0.18 + 0.08 * abs(f - 0.5) * 2
            let wob = sin(t * 5 + Double(i) * 1.7) * 0.03
            let tip = P(0.1 + 0.8 * f + wob, tipH + sin(t * 4 + Double(i)) * 0.02)
            let dipX = 0.1 + 0.8 * (Double(i) + 1) / Double(n)
            body.addQuadCurve(to: tip, control: CGPoint(x: (prev.x + tip.x) / 2 - bodyW * 0.04, y: tip.y + bodyH * 0.18))
            let dip = i < n - 1 ? P(dipX, 0.34) : P(0.98, 0.62)
            body.addQuadCurve(to: dip, control: CGPoint(x: (tip.x + dip.x) / 2 + bodyW * 0.03, y: tip.y + bodyH * 0.12))
            prev = dip
        }
        body.addCurve(to: P(0.5, 1.0), control1: P(1.0, 0.85), control2: P(0.82, 1.0))
        body.closeSubpath()
        ctx.fill(body, with: .linearGradient(Gradient(colors: [bright, deep]),
                                             startPoint: P(0.5, 0.1), endPoint: P(0.5, 1.0)))
        // Inner core highlight.
        ctx.fill(Path(ellipseIn: CGRect(x: origin.x + bodyW * 0.28, y: origin.y + bodyH * 0.5, width: bodyW * 0.44, height: bodyH * 0.42)),
                 with: .radialGradient(Gradient(colors: [core.opacity(sleepy ? 0.3 : 0.7), .clear]),
                                       center: P(0.5, 0.72), startRadius: 0, endRadius: bodyW * 0.3))
        if era >= 2 {   // after the Forge: a small forged ember-gem on the brow
            var gem = Path()
            gem.move(to: P(0.5, 0.36)); gem.addLine(to: P(0.54, 0.41)); gem.addLine(to: P(0.5, 0.46)); gem.addLine(to: P(0.46, 0.41))
            gem.closeSubpath()
            ctx.fill(gem, with: .color(Color(red: 0.43, green: 0.68, blue: 0.95)))
        }

        // Face.
        let eyeY = 0.58, eyeDX = 0.15
        let blink = sleepy || (t.truncatingRemainder(dividingBy: 4.2) < 0.12)
        let eyeColor = Color(red: 0.25, green: 0.1, blue: 0.08)
        for side in [-1.0, 1.0] {
            let c = P(0.5 + side * eyeDX, eyeY)
            if blink || m == .joyful {
                var lid = Path()   // closed or ^ ^ happy eyes
                lid.move(to: CGPoint(x: c.x - bodyW * 0.05, y: c.y))
                lid.addQuadCurve(to: CGPoint(x: c.x + bodyW * 0.05, y: c.y),
                                 control: CGPoint(x: c.x, y: c.y + (m == .joyful ? -1 : 1) * bodyH * 0.05))
                ctx.stroke(lid, with: .color(eyeColor), style: StrokeStyle(lineWidth: bodyW * 0.022, lineCap: .round))
            } else {
                let ew = bodyW * 0.075, eh = bodyH * 0.09
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - ew / 2, y: c.y - eh / 2, width: ew, height: eh)), with: .color(eyeColor))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - ew * 0.1, y: c.y - eh * 0.35, width: ew * 0.35, height: ew * 0.35)), with: .color(.white))
            }
            // blush
            ctx.fill(Path(ellipseIn: CGRect(x: c.x + side * bodyW * 0.03 - bodyW * 0.045, y: c.y + bodyH * 0.06, width: bodyW * 0.09, height: bodyH * 0.035)),
                     with: .color(Color(red: 1, green: 0.45, blue: 0.4).opacity(0.5)))
        }
        let mc = P(0.5, 0.71)
        var mouth = Path()
        switch m {
        case .joyful:
            mouth.addEllipse(in: CGRect(x: mc.x - bodyW * 0.07, y: mc.y - bodyH * 0.02, width: bodyW * 0.14, height: bodyH * 0.09))
            ctx.fill(mouth, with: .color(Color(red: 0.4, green: 0.08, blue: 0.06)))
        case .happy:
            mouth.move(to: CGPoint(x: mc.x - bodyW * 0.06, y: mc.y))
            mouth.addQuadCurve(to: CGPoint(x: mc.x + bodyW * 0.06, y: mc.y), control: CGPoint(x: mc.x, y: mc.y + bodyH * 0.06))
            ctx.stroke(mouth, with: .color(eyeColor), style: StrokeStyle(lineWidth: bodyW * 0.022, lineCap: .round))
        case .calm:
            mouth.move(to: CGPoint(x: mc.x - bodyW * 0.035, y: mc.y))
            mouth.addQuadCurve(to: CGPoint(x: mc.x + bodyW * 0.035, y: mc.y), control: CGPoint(x: mc.x, y: mc.y + bodyH * 0.025))
            ctx.stroke(mouth, with: .color(eyeColor), style: StrokeStyle(lineWidth: bodyW * 0.02, lineCap: .round))
        case .sleepy:
            mouth.addEllipse(in: CGRect(x: mc.x - bodyW * 0.02, y: mc.y, width: bodyW * 0.04, height: bodyH * 0.03))
            ctx.fill(mouth, with: .color(eyeColor))
            // floating z's
            for i in 0..<3 {
                let ph = (t * 0.4 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let zp = CGPoint(x: origin.x + bodyW * (0.85 + ph * 0.3), y: origin.y + bodyH * (0.3 - ph * 0.5))
                ctx.draw(Text("z").font(.system(size: 10 + ph * 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7 * (1 - ph))), at: zp)
            }
        }

        // Little embers floating up.
        var sparks = ctx
        sparks.blendMode = .plusLighter
        for i in 0..<(sleepy ? 3 : 8) {
            let ph = (t * 0.5 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let sx = origin.x + bodyW * (0.2 + 0.6 * Double((i * 7) % 10) / 10) + sin(t * 2 + Double(i)) * 6
            let sy = origin.y + bodyH * (0.2 - ph * 0.6)
            let s = 3.5 * (1 - ph)
            sparks.fill(Path(ellipseIn: CGRect(x: sx, y: sy, width: s, height: s)), with: .color(bright.opacity(1 - ph)))
        }

        // Sparks in flight toward your Flame.
        for f in stage.flights {
            let p = min(1, now.timeIntervalSince(f.start) / f.duration)
            let target = P(0.5, 0.6)
            let ctrl = CGPoint(x: (f.from.x + target.x) / 2, y: min(f.from.y, target.y) - size.height * 0.18)
            let q = 1 - p
            let pos = CGPoint(x: q * q * f.from.x + 2 * q * p * ctrl.x + p * p * target.x,
                              y: q * q * f.from.y + 2 * q * p * ctrl.y + p * p * target.y)
            let s: CGFloat = f.big ? 20 : 13
            sparks.fill(Path(ellipseIn: CGRect(x: pos.x - s, y: pos.y - s, width: s * 2, height: s * 2)),
                        with: .radialGradient(Gradient(colors: [.white, f.pillar.color, .clear]), center: pos, startRadius: 0, endRadius: s))
        }
    }
}
