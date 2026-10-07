// Your Spark burns in the color of the ember you chose (Mathis, 2026-10-03): Love pink, Curiosity blue, Strength
// ember-red, Calm moonlit blue, Craft gold, Wonder green. One hue shift per ember, used by the living Spark's shader
// (sparkFire) and by every flat picture of it (map, tour, Your Flame, the glimpse), so it is the same color everywhere.
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

enum SparkTint {
    /// Hue rotation (radians) from the painted orange, and how much of the color to keep (calm is softer).
    nonisolated static func shift(_ ember: String) -> (angle: Float, saturation: Float, strength: Float) {
        // strength = how much of the color shows (subtle, Mathis). Blues sit opposite the painted orange, so a half
        // mix would cancel to grey: they get a little more color so they still read as a soft blue.
        switch ember {
        case "heart": (-0.62, 0.95, 0.4)       // a warm flame with rose tips
        case "mind": (3.1, 1.25, 0.8)           // soft sky blue
        case "body": (-0.14, 1.25, 0.4)          // deeper, hotter ember red
        case "spirit": (3.45, 0.8, 0.72)         // pale moonlit blue-lavender
        case "craft": (0.12, 1.0, 0.4)          // gold
        case "world": (1.45, 0.95, 0.36)         // golden green
        default: (0, 1, 0)
        }
    }

    nonisolated(unsafe) private static let context = CIContext()
    nonisolated(unsafe) private static var cache: [String: UIImage] = [:]
    nonisolated private static let lock = NSLock()
    /// A picture of the Spark (or of its stages) in your ember's color.
    static func image(_ name: String, ember: String) -> UIImage? {
        let key = name + "|" + ember
        lock.lock(); let c = cache[key]; lock.unlock()
        if let c { return c }
        return PerfProbe.measure("tint \(name)") { tinted(name, ember: ember, key: key) }
    }
    /// Prepares every picture of your Spark in your ember's color in the background, at launch, so no screen ever
    /// waits for it (the first tint took ~45 ms on the main thread).
    nonisolated static func warmUp(ember: String) {
        let names = [PixelMode.sparkImage, "spark-keyed.png", "stage-spark.png", "stage-flame.png", "stage-blaze.png", "stage-kindled.png", "stage-beyond.png"]
        DispatchQueue.global(qos: .utility).async {
            for n in names { _ = tinted(n, ember: ember, key: n + "|" + ember) }
        }
    }
    nonisolated private static func tinted(_ name: String, ember: String, key: String) -> UIImage? {
        lock.lock(); let c = cache[key]; lock.unlock()
        if let c { return c }
        guard let src = UIImage(named: name), let ci = CIImage(image: src) else { return nil }
        let s = shift(ember)
        guard s.strength > 0 else { return src }
        let hue = CIFilter.hueAdjust(); hue.inputImage = ci; hue.angle = s.angle
        let sat = CIFilter.colorControls(); sat.inputImage = hue.outputImage; sat.saturation = s.saturation
        let mixF = CIFilter.dissolveTransition(); mixF.inputImage = ci; mixF.targetImage = sat.outputImage; mixF.time = s.strength * 0.75
        // Only hints at the edges: the heart of the fire keeps its painted color (as in the live Spark's shader).
        let e = ci.extent, r = Float(min(e.width, e.height))
        let grad = CIFilter.radialGradient()
        grad.center = CGPoint(x: e.midX, y: e.minY + e.height * 0.42)
        grad.radius0 = r * 0.24; grad.radius1 = r * 0.58
        grad.color0 = CIColor(red: 0, green: 0, blue: 0); grad.color1 = CIColor(red: 1, green: 1, blue: 1)
        let blend = CIFilter.blendWithMask(); blend.inputImage = mixF.outputImage; blend.backgroundImage = ci
        blend.maskImage = grad.outputImage?.cropped(to: e)
        guard let out = blend.outputImage, let cg = context.createCGImage(out, from: ci.extent) else { return src }
        let img = UIImage(cgImage: cg, scale: src.scale, orientation: src.imageOrientation)
        lock.lock(); cache[key] = img; lock.unlock()
        return img
    }
}
