// No edge, ever (Mathis, 2026-10-02): how far the camera may slide over a painting bent in depth before any of its
// edges could come into view. Near parts (the water at the bottom) move faster on screen than far ones (parallax),
// so each edge's limit depends on how near that edge sits. Everything the view adds on top (the rubber band past the
// limit, the camera's slow breathing) must fit inside what's left, so callers subtract those margins.
import Foundation

enum EdgeSafety {
    /// The rubber band may pull this far past the limit (meters); the spring never goes further.
    static let rubber: Float = 0.03

    /// Safe sideways and vertical slide (meters) for a camera looking straight at a painting plane.
    /// - planeW/planeH: the painting's size at `restDistance` (its rest plane).
    /// - edges: the distance from the camera's rest position to the nearest point of each edge (left, right,
    ///   bottom, top), from the relief.
    /// - camForward: how far the camera has moved toward the painting (zoom), 0 at rest.
    /// - margin: room kept for the rubber band and the camera's breathing.
    static func limit(planeW: Float, planeH: Float, restDistance: Float, edges: (l: Float, r: Float, b: Float, t: Float),
                      camForward: Float = 0, fov: Float, aspect: Float, margin: Float) -> SIMD2<Float> {
        let tv = tan(fov / 2 * .pi / 180), th = tv * aspect
        // An edge point at distance d sits at (size/2)·d/restDistance from the center; it stays off screen while
        // the camera's offset c keeps |edge − c| ≥ tan(half-angle) · (d − camForward).
        func room(_ half: Float, _ d: Float, _ t: Float) -> Float { half * d / restDistance - t * max(0.01, d - camForward) }
        let x = min(room(planeW / 2, edges.l, th), room(planeW / 2, edges.r, th))
        let y = min(room(planeH / 2, edges.b, tv), room(planeH / 2, edges.t, tv))
        return [max(0, x - margin), max(0, y - margin)]
    }

    /// Past the limit, movement fades out smoothly and never goes beyond `rubber`.
    static func rubberBand(_ x: Float, _ lim: Float) -> Float {
        let over = abs(x) - lim
        guard over > 0 else { return x }
        return (lim + rubber * (1 - exp(-over / rubber))) * (x < 0 ? -1 : 1)
    }
}
