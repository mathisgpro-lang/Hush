// Your Spark burns in the color of the ember you chose (Mathis, 2026-10-03): Love pink, Curiosity blue, Strength
// ember-red, Calm moonlit blue, Craft gold, Wonder green. One hue shift per ember, used by the living Spark's shader
// (sparkFire) and by every flat picture of it (map, tour, Your Flame, the glimpse), so it is the same color everywhere.
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

enum SparkTint {
    /// Hue rotation (radians) from the painted orange, and how much of the color to keep (calm is softer).
    static func shift(_ ember: String) -> (angle: Float, saturation: Float, strength: Float) {
        // strength = how much of the color shows (subtle, Mathis). Blues sit opposite the painted orange, so a half
        // mix would cancel to grey: they get a little more color so they still read as a soft blue.
        switch ember {
        case "heart": (-0.62, 0.95, 0.45)       // a warm flame with rose tips
        case "mind": (3.1, 1.2, 0.66)           // soft sky blue
        case "body": (-0.14, 1.3, 0.5)          // deeper, hotter ember red
        case "spirit": (3.45, 0.7, 0.6)         // pale moonlit blue-lavender
        case "craft": (0.12, 1.0, 0.5)          // gold
        case "world": (1.45, 0.95, 0.4)         // golden green
        default: (0, 1, 0)
        }
    }

    private static let context = CIContext()
    private static var cache: [String: UIImage] = [:]
    /// A picture of the Spark (or of its stages) in your ember's color.
    static func image(_ name: String, ember: String) -> UIImage? {
        let key = name + "|" + ember
        if let c = cache[key] { return c }
        guard let src = UIImage(named: name), let ci = CIImage(image: src) else { return nil }
        let s = shift(ember)
        guard s.strength > 0 else { return src }
        let hue = CIFilter.hueAdjust(); hue.inputImage = ci; hue.angle = s.angle
        let sat = CIFilter.colorControls(); sat.inputImage = hue.outputImage; sat.saturation = s.saturation
        let mixF = CIFilter.dissolveTransition(); mixF.inputImage = ci; mixF.targetImage = sat.outputImage; mixF.time = s.strength
        guard let out = mixF.outputImage, let cg = context.createCGImage(out, from: ci.extent) else { return src }
        let img = UIImage(cgImage: cg, scale: src.scale, orientation: src.imageOrientation)
        cache[key] = img
        return img
    }
}
