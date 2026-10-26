import Foundation
import CoreGraphics

/// Presentation only: `point` is the ground/contact position; render the body
/// at `point.y - elevation` and leave its shadow on the ground. Rotation is radians.
struct MapHopPose {
    var point: CGPoint
    var elevation: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat
    var rotation: CGFloat
}

enum MapJourneyMotion {
    /// Clamped smoothstep, shared by the route and camera animations.
    static func ease(_ t: CGFloat) -> CGFloat {
        let t = min(1, max(0, t))
        return t * t * (3 - 2 * t)
    }

    /// A complete hop fits in the caller's duration (normally 0.56 seconds).
    static func hop(from: CGPoint, to: CGPoint, progress: CGFloat) -> MapHopPose {
        let t = min(1, max(0, progress))
        if t == 0 { return rest(at: from) }
        if t == 1 { return rest(at: to) }
        let dx = to.x - from.x
        let dy = to.y - from.y
        let direction = dx / max(40, abs(dx))

        if t < 0.14 {
            let compression = ease(t / 0.14)
            return MapHopPose(point: from, elevation: 0,
                              scaleX: 1 + 0.11 * compression,
                              scaleY: 1 - 0.12 * compression,
                              rotation: -direction * 0.035 * compression)
        }
        if t < 0.82 {
            let flight = (t - 0.14) / 0.68
            let travel = ease(flight)
            let arc = 4 * flight * (1 - flight)
            let stretch = sin(.pi * flight)
            let compression = 1 - ease(flight / 0.18)
            let height = min(40, 26 + hypot(dx, dy) * 0.07)
            return MapHopPose(point: CGPoint(x: from.x + dx * travel, y: from.y + dy * travel),
                              elevation: height * arc,
                              scaleX: 1 + 0.11 * compression - 0.035 * stretch,
                              scaleY: 1 - 0.12 * compression + 0.055 * stretch,
                              rotation: direction * (-0.035 * compression + 0.07 * stretch))
        }
        let landing = (t - 0.82) / 0.18
        let compression = sin(.pi * landing)
        return MapHopPose(point: to, elevation: 0,
                          scaleX: 1 + 0.10 * compression,
                          scaleY: 1 - 0.13 * compression,
                          rotation: direction * 0.02 * compression)
    }

    /// Follows the full polyline at eased distance; repeated points are harmless.
    static func dash(points: [CGPoint], progress: CGFloat) -> MapHopPose {
        guard let first = points.first, let last = points.last else { return rest(at: .zero) }
        let t = min(1, max(0, progress))
        if t == 0 { return rest(at: first) }
        if t == 1 { return rest(at: last) }
        var length: CGFloat = 0
        for index in 1..<points.count {
            length += distance(points[index - 1], points[index])
        }
        guard length > 0 else { return rest(at: first) }
        let travelled = length * ease(t)
        let point = point(on: points, distance: travelled)
        // Read a short span of the route for the lean, so turns never snap the body.
        let span = min(30, length * 0.08)
        let behind = self.point(on: points, distance: max(0, travelled - span))
        let ahead = self.point(on: points, distance: min(length, travelled + span))
        let direction = (ahead.x - behind.x) / max(1, distance(behind, ahead))
        let lift = sin(.pi * t)
        return MapHopPose(point: point, elevation: 12 * lift,
                          scaleX: 1 - 0.025 * lift, scaleY: 1 + 0.04 * lift,
                          rotation: direction * 0.09 * lift)
    }

    static func cameraY(for point: CGPoint, viewportHeight: CGFloat, contentHeight: CGFloat) -> CGFloat {
        min(max(0, contentHeight - viewportHeight), max(0, point.y - viewportHeight * 0.55))
    }

    private static func rest(at point: CGPoint) -> MapHopPose {
        MapHopPose(point: point, elevation: 0, scaleX: 1, scaleY: 1, rotation: 0)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    private static func point(on points: [CGPoint], distance: CGFloat) -> CGPoint {
        var remaining = max(0, distance)
        for index in 1..<points.count {
            let from = points[index - 1]
            let to = points[index]
            let segment = self.distance(from, to)
            guard segment > 0 else { continue }
            if remaining <= segment {
                let t = remaining / segment
                return CGPoint(x: from.x + (to.x - from.x) * t,
                               y: from.y + (to.y - from.y) * t)
            }
            remaining -= segment
        }
        return points.last ?? .zero
    }
}
