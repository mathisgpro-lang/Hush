// Pixel mode (Mathis, 2026-10-07: "pixelize the whole game… efficiency and the mechanics first"): a live switch that
// turns every world, the map and your Spark into pixel art (the shaders snap to an art-pixel grid and a small
// palette, see s2pixelUV / s2pixelColor). On by default in this trial; Your Flame has the switch.
import RealityKit
import UIKit

enum PixelMode {
    nonisolated static let key = "look.pixel"
    nonisolated static var on: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? !CommandLine.arguments.contains("-painted") }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    /// The native pixel art is in the app (decision 149): the Sanctuary and the Spark are drawn as pixel art, not
    /// filtered paintings (the other worlds still use the filter until Codex repaints them).
    nonisolated static let world: Bool = on && Bundle.main.url(forResource: "px-home-paint", withExtension: "png") != nil
    nonisolated static let sparkBase = world ? "px-spark" : "spark"
    nonisolated static let sparkImage = sparkBase + "-keyed.png"
    /// The pixel world's native grid (art pixels), from tools/build_pixel_world.py.
    static let worldGrid: SIMD2<Float>? = {
        guard world, let u = Bundle.main.url(forResource: "px-home-features", withExtension: "json"), let d = try? Data(contentsOf: u),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Double], let w = j["gridW"], let h = j["gridH"] else { return nil }
        return [Float(w), Float(h)]
    }()
    /// Art pixels down the height of the screen: chunky enough to read as pixel art, fine enough for the details.
    static let rowsPerScreen: Float = 640

    /// Marks every custom material under `root` for (or out of) pixel mode. `screens` = how many screen heights the
    /// textures span (so an art pixel is the same size everywhere); `sprite` = a small character (its own scale).
    @MainActor static func apply(to root: Entity, on: Bool) {
        visit(root) { e in
            guard var comp = e.model else { return }
            var changed = false
            comp.materials = comp.materials.map { mat in
                guard var m = mat as? CustomMaterial else { return mat }
                let texH = Float(m.baseColor.texture?.resource.height ?? 1024)
                let texW = Float(m.baseColor.texture?.resource.width ?? 1024)
                let isSpark = texW < 1200                         // your Spark (the worlds' paintings are all wider)
                var k = isSpark ? (world ? 12 : max(2, texH / 80)) : max(1.5, texH / rowsPerScreen)   // (the pixel Spark is drawn 12 texels per pixel)   // texels per art pixel
                if let g = worldGrid, abs(texH - g.y * 4) < 2 { k = 4 }              // the native pixel world: its own grid
                // The grid travels in the emissive tint, which the renderer linearises: pre-encode it (sRGB).
                func enc(_ v: Float) -> CGFloat {
                    let l = min(1, max(0, v)); return CGFloat(l <= 0.0031308 ? l * 12.92 : 1.055 * pow(l, 1 / 2.4) - 0.055)
                }
                let tint = on ? UIColor(red: enc(texW / k / 4096), green: enc(texH / k / 4096), blue: 0.5, alpha: 1) : .white
                m.emissiveColor = .init(color: tint, texture: m.emissiveColor.texture)
                changed = true
                return m
            }
            if changed { e.model = comp }
        }
    }
    @MainActor private static func visit(_ e: Entity, _ f: (ModelEntity) -> Void) {
        if let m = e as? ModelEntity { f(m) }
        for c in e.children { visit(c, f) }
    }
}
