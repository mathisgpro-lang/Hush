import SwiftUI
import Domain

/// The Flame as live pixel art (decision 77). A classic pixel-fire simulation burns inside a pixel-art stone
/// (or forged metal) vessel. Vitality feeds the fire, Depth colors the vessel's veins pixel by pixel.
final class PixelFire {
    static let w = 40, h = 76
    private(set) var heat = [Int](repeating: 0, count: PixelFire.w * PixelFire.h)
    private var rng = SystemRandomNumberGenerator()
    private var last = Date.distantPast

    /// Advances the simulation at a steady ~20 fps (a deliberate, pixel-art cadence).
    func step(now: Date, intensity: Double, cavity: (Int, Int) -> Bool) {
        guard now.timeIntervalSince(last) > 0.05 else { return }
        last = now
        let w = PixelFire.w, h = PixelFire.h
        let top = PixelFire.palette.count - 1
        let fuelRow = Int(Double(h) * 0.64)            // the base of the fire, low in the cavity
        let mid = Double(w - 1) / 2
        for x in 0..<w where cavity(x, fuelRow) {
            let centerBias = max(0, 1 - abs(Double(x) - mid) / (Double(w) * 0.22))
            heat[fuelRow * w + x] = Int(Double(top) * max(0.15, min(1, intensity)) * (0.55 + 0.45 * centerBias)
                                        * Double.random(in: 0.85...1, using: &rng))
        }
        for y in stride(from: fuelRow, to: 0, by: -1) {
            for x in 0..<w {
                let src = heat[y * w + x]
                let r = Int.random(in: 0...2, using: &rng)
                let dx = max(0, min(w - 1, x - r + 1))
                let cool = (Int.random(in: 0...2, using: &rng) == 0 ? 1 : 0) + (intensity < 0.3 ? 1 : 0)
                heat[(y - 1) * w + dx] = max(0, src - cool)
            }
        }
        // Glowing coals below the flame's base (never a black hole in the heart).
        let coals = Int(Double(top) * (0.25 + 0.3 * max(0, min(1, intensity))))
        for y in (fuelRow + 1)..<h { for x in 0..<w { heat[y * w + x] = coals + Int.random(in: -1...1, using: &rng) } }
    }

    static let palette: [Color] = {
        let stops: [(Double, Double, Double)] = [
            (0.03, 0.02, 0.02), (0.18, 0.04, 0.02), (0.35, 0.06, 0.02), (0.52, 0.10, 0.02), (0.68, 0.18, 0.03),
            (0.80, 0.28, 0.04), (0.88, 0.38, 0.06), (0.94, 0.48, 0.08), (0.97, 0.58, 0.12), (0.99, 0.68, 0.18),
            (1.00, 0.76, 0.26), (1.00, 0.83, 0.38), (1.00, 0.89, 0.52), (1.00, 0.94, 0.70), (1.00, 0.98, 0.88),
        ]
        return stops.map { Color(red: $0.0, green: $0.1, blue: $0.2) }
    }()
}

struct PixelFlameView: View {
    let vitality: Double
    let depth: [Pillar: Double]
    let stage: FlameStage
    var era: Int = 1
    var center: CGFloat = 0.43
    var height: CGFloat = 0.30
    var shake: Double = 0
    @State private var fire = PixelFire()

    private let w = PixelFire.w, h = PixelFire.h

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas(rendersAsynchronously: false) { ctx, size in
                draw(&ctx, size: size, now: tl.date)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(vitality > 0.8 ? "Your Flame burns bright." : vitality > 0.25 ? "Your Flame burns calmly." : "Your Flame rests in embers.")
    }

    // Diamond-shaped vessel in grid space: outer shell and open heart.
    /// A pointed lantern-gem: concave sides make sharp tips (a power < 1 on each axis).
    private func shape(_ x: Int, _ y: Int) -> Double {
        let cx = Double(w - 1) / 2, cy = Double(h - 1) / 2
        let dx = abs(Double(x) - cx) / (Double(w) / 2), dy = abs(Double(y) - cy) / (Double(h) / 2)
        return pow(dx, 0.85) + pow(dy, 1.15)
    }
    private func isShell(_ x: Int, _ y: Int) -> Bool { shape(x, y) <= 1.0 && !isCavity(x, y) }
    private func isCavity(_ x: Int, _ y: Int) -> Bool {
        let cx = Double(w - 1) / 2, cy = Double(h - 1) / 2
        let dx = abs(Double(x) - cx) / (Double(w) / 2), dy = abs(Double(y) - cy) / (Double(h) / 2)
        return pow(dx, 0.85) + pow(dy, 1.15) <= 0.60 && abs(Double(y) - cy) < Double(h) * 0.3
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let flare = max(0, stage.flareUntil.timeIntervalSince(now)) * stage.flareStrength
        let v = min(1.4, vitality + flare * 0.5)
        fire.step(now: now, intensity: v, cavity: { isCavity($0, $1) })

        let cell = floor(size.height * height / CGFloat(h))
        let ox = floor(size.width / 2 - cell * CGFloat(w) / 2) + (shake > 0 ? CGFloat(Int.random(in: -1...1)) * cell * 0.5 : 0)
        let oy = floor(size.height * center - cell * CGFloat(h) / 2)
        func rect(_ x: Int, _ y: Int) -> CGRect { CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell, width: cell, height: cell) }

        // Pixel glow behind the vessel (stepped rings, no smooth gradient).
        let rings = 5
        for i in (0..<rings).reversed() {
            let rr = cell * CGFloat(w) * (0.55 + 0.18 * CGFloat(i)) * CGFloat(0.8 + 0.3 * min(1, v))
            let c = CGPoint(x: ox + cell * CGFloat(w) / 2, y: oy + cell * CGFloat(h) * 0.55)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                     with: .color(Color(red: 1, green: 0.55, blue: 0.2).opacity(0.05 * min(1, v))))
        }

        // Vessel: stone (or forged metal) with pixel shading and a dithered texture.
        let stone: [Color] = era >= 2
            ? [Color(red: 0.72, green: 0.56, blue: 0.34), Color(red: 0.52, green: 0.40, blue: 0.26), Color(red: 0.30, green: 0.26, blue: 0.26), Color(red: 0.16, green: 0.15, blue: 0.18)]
            : [Color(red: 0.93, green: 0.82, blue: 0.62), Color(red: 0.82, green: 0.68, blue: 0.48), Color(red: 0.64, green: 0.50, blue: 0.34), Color(red: 0.42, green: 0.31, blue: 0.21)]
        let cx = Double(w - 1) / 2
        for y in 0..<h {
            for x in 0..<w where isShell(x, y) {
                let edge = shape(x, y) > 0.9 || !isShell(x, y - 1) || !isShell(x, y + 1) && !isCavity(x, y + 1)
                let light = (Double(x) < cx ? 0 : 1) + (y > h / 2 ? 1 : 0)
                let dither = (x + y) % 3 == 0 ? 1 : 0
                let ridge = abs(Double(x) - cx) < 0.6 && !edge
                let tone = edge ? 3 : ridge ? 0 : min(2, Int(light) + (light == 1 ? dither : 0))
                ctx.fill(Path(rect(x, y)), with: .color(stone[tone]))
            }
        }
        if era >= 2 {   // forged era: thin blue inlay pixels
            for y in stride(from: 4, to: h - 4, by: 6) {
                for x in 0..<w where isShell(x, y) && (x + y) % 2 == 0 {
                    ctx.fill(Path(rect(x, y)), with: .color(Color(red: 0.43, green: 0.68, blue: 0.95)))
                }
            }
        }

        // Pillar veins: pixels of each pillar's color grow through the shell as its Depth deepens.
        for p in Pillar.allCases {
            let d = depth[p] ?? 0
            guard d > 0 else { continue }
            let n = Int(min(40, 3 + 37 * (1 - exp(-d / 40))))
            var placed = 0, k = p.rawValue * 97 + 13
            while placed < n && k < 4000 {
                k += 31
                let x = (k * 7) % w, y = (k * 13) % h
                if isShell(x, y), shape(x, y) < 0.88 { ctx.fill(Path(rect(x, y)), with: .color(p.color)); placed += 1 }
            }
        }

        // Fire: the simulation, drawn only inside the open heart.
        let pal = PixelFire.palette
        for y in 0..<h {
            for x in 0..<w where isCavity(x, y) {
                let heat = fire.heat[y * w + x]
                let color = heat <= 1 ? Color(red: 0.12, green: 0.04, blue: 0.03) : pal[min(pal.count - 1, heat)]
                ctx.fill(Path(rect(x, y)), with: .color(color))
            }
        }

        // Sparks in flight: square pixels, stepping along their arc.
        for f in stage.flights {
            let prog = min(1, now.timeIntervalSince(f.start) / f.duration)
            let steps = (prog * 16).rounded(.down) / 16
            let target = CGPoint(x: ox + cell * CGFloat(w) / 2, y: oy + cell * CGFloat(h) / 2)
            let ctrl = CGPoint(x: (f.from.x + target.x) / 2, y: min(f.from.y, target.y) - size.height * 0.18)
            let q = 1 - steps
            let pos = CGPoint(x: q * q * f.from.x + 2 * q * steps * ctrl.x + steps * steps * target.x,
                              y: q * q * f.from.y + 2 * q * steps * ctrl.y + steps * steps * target.y)
            let s = cell * (f.big ? 3 : 2)
            let snapped = CGPoint(x: (pos.x / cell).rounded() * cell, y: (pos.y / cell).rounded() * cell)
            ctx.fill(Path(CGRect(x: snapped.x - s / 2, y: snapped.y - s / 2, width: s, height: s)), with: .color(f.pillar.color))
            ctx.fill(Path(CGRect(x: snapped.x - s / 4, y: snapped.y - s / 4, width: s / 2, height: s / 2)), with: .color(.white))
        }
    }
}
