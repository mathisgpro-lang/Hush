// Run from prototypes/p2-spikes:
// xcrun swiftc -module-cache-path /tmp/map-journey-swift-cache \
//   SpikeLab/Shell/MapJourneyMotion.swift tools/check_map_journey.swift \
//   -o /tmp/check-map-journey && /tmp/check-map-journey
import Foundation
import CoreGraphics

@main
struct MapJourneyMotionChecks {
    static func main() {
        let checks = Checks()
        checks.run()
    }
}

private final class Checks {
    private var passed = 0
    private var failed = 0

    private func check(_ name: String, _ condition: Bool) {
        if condition { passed += 1 }
        else { failed += 1; print("FAIL: \(name)") }
    }

    private func close(_ a: CGFloat, _ b: CGFloat, tolerance: CGFloat = 0.000_001) -> Bool {
        abs(a - b) <= tolerance
    }

    private func close(_ a: CGPoint, _ b: CGPoint, tolerance: CGFloat = 0.000_001) -> Bool {
        close(a.x, b.x, tolerance: tolerance) && close(a.y, b.y, tolerance: tolerance)
    }

    private func resting(_ pose: MapHopPose, at point: CGPoint) -> Bool {
        close(pose.point, point) && close(pose.elevation, 0)
            && close(pose.scaleX, 1) && close(pose.scaleY, 1) && close(pose.rotation, 0)
    }

    private func continuous(_ before: MapHopPose, _ after: MapHopPose) -> Bool {
        close(before.point, after.point, tolerance: 0.005)
            && close(before.elevation, after.elevation, tolerance: 0.005)
            && close(before.scaleX, after.scaleX, tolerance: 0.005)
            && close(before.scaleY, after.scaleY, tolerance: 0.005)
            && close(before.rotation, after.rotation, tolerance: 0.005)
    }

    func run() {
        // Catch overshooting easing that sends the camera or character outside its route.
        check("easing clamps below zero", close(MapJourneyMotion.ease(-0.2), 0))
        check("easing clamps above one", close(MapJourneyMotion.ease(1.2), 1))
        check("easing starts at zero", close(MapJourneyMotion.ease(0), 0))
        check("easing ends at one", close(MapJourneyMotion.ease(1), 1))
        check("easing reaches halfway", close(MapJourneyMotion.ease(0.5), 0.5))
        let easing = (0...100).map { MapJourneyMotion.ease(CGFloat($0) / 100) }
        check("easing never reverses", zip(easing, easing.dropFirst()).allSatisfy { $0 <= $1 })

        let from = CGPoint(x: 40, y: 180)
        let to = CGPoint(x: 160, y: 80)
        for progress: CGFloat in [-1, 0] {
            check("hop rests at source at \(progress)", resting(MapJourneyMotion.hop(from: from, to: to, progress: progress), at: from))
        }
        for progress: CGFloat in [1, 2] {
            check("hop rests at destination at \(progress)", resting(MapJourneyMotion.hop(from: from, to: to, progress: progress), at: to))
        }
        for progress: CGFloat in [0.07, 0.13] {
            let pose = MapJourneyMotion.hop(from: from, to: to, progress: progress)
            check("anticipation stays planted at \(progress)", close(pose.point, from) && close(pose.elevation, 0))
            check("anticipation compresses at \(progress)", pose.scaleX > 1 && pose.scaleY < 1)
        }
        let airborne = MapJourneyMotion.hop(from: from, to: to, progress: 0.48)
        check("hop reaches route midpoint", close(airborne.point, CGPoint(x: 100, y: 130)))
        check("hop rises above the path", airborne.elevation >= 26 && airborne.elevation <= 40)
        check("hop stretches in the air", airborne.scaleX < 1 && airborne.scaleY > 1)
        let landing = MapJourneyMotion.hop(from: from, to: to, progress: 0.9)
        check("landing stays on destination", close(landing.point, to) && close(landing.elevation, 0))
        check("landing compresses", landing.scaleX > 1 && landing.scaleY < 1)
        let leftward = MapJourneyMotion.hop(from: to, to: from, progress: 0.48)
        check("hop leans toward travel in both directions", airborne.rotation > 0 && leftward.rotation < 0)
        let inPlace = (0...100).map { MapJourneyMotion.hop(from: from, to: from, progress: CGFloat($0) / 100) }
        check("in-place hop stays over its stone", inPlace.allSatisfy { close($0.point, from) && close($0.rotation, 0) })
        check("in-place hop lifts", inPlace.contains { $0.elevation > 20 })
        for boundary: CGFloat in [0, 0.14, 0.82, 1] {
            check("hop has no jump at phase \(boundary)", continuous(
                MapJourneyMotion.hop(from: from, to: to, progress: boundary - 0.000_001),
                MapJourneyMotion.hop(from: from, to: to, progress: boundary + 0.000_001)))
        }

        // A bent route with unequal legs catches shortcuts and per-segment timing mistakes.
        let path = [CGPoint.zero, CGPoint(x: 90, y: 0), CGPoint(x: 90, y: 30)]
        for progress: CGFloat in [-1, 0] {
            check("dash rests at start at \(progress)", resting(MapJourneyMotion.dash(points: path, progress: progress), at: .zero))
        }
        for progress: CGFloat in [1, 2] {
            check("dash rests at end at \(progress)", resting(MapJourneyMotion.dash(points: path, progress: progress), at: CGPoint(x: 90, y: 30)))
        }
        check("dash travels half the whole path at halfway", close(MapJourneyMotion.dash(points: path, progress: 0.5).point, CGPoint(x: 60, y: 0)))
        let dash = (0...400).map { MapJourneyMotion.dash(points: path, progress: CGFloat($0) / 400) }
        check("dash stays on every path segment", dash.allSatisfy {
            (close($0.point.y, 0) && (0...90).contains($0.point.x))
                || (close($0.point.x, 90) && (0...30).contains($0.point.y))
        })
        let distances = dash.map { $0.point.x + $0.point.y }
        check("dash never reverses or teleports", zip(distances, distances.dropFirst()).allSatisfy { $1 >= $0 && $1 - $0 < 1 })
        check("dash has a low airborne arc", dash.contains { $0.elevation > 5 } && dash.allSatisfy { $0.elevation >= 0 && $0.elevation < 20 })
        check("dash leans into forward travel", MapJourneyMotion.dash(points: path, progress: 0.3).rotation > 0)
        check("dash leans into reverse travel", MapJourneyMotion.dash(points: Array(path.reversed()), progress: 0.7).rotation < 0)
        let corner: CGFloat = 0.673_648_177_666_930_3 // 75% of eased distance: the 90-point first leg.
        check("dash remains continuous around a corner", continuous(
            MapJourneyMotion.dash(points: path, progress: corner - 0.000_001),
            MapJourneyMotion.dash(points: path, progress: corner + 0.000_001)))
        check("empty dash is safe", resting(MapJourneyMotion.dash(points: [], progress: 0.5), at: .zero))
        check("single-point dash stays planted", resting(MapJourneyMotion.dash(points: [from], progress: 0.5), at: from))
        check("zero-length dash stays planted", resting(MapJourneyMotion.dash(points: [from, from, from], progress: 0.5), at: from))
        let duplicates = [CGPoint.zero, CGPoint.zero, CGPoint(x: 90, y: 0), CGPoint(x: 90, y: 0), CGPoint(x: 90, y: 30)]
        check("duplicate route points do not interrupt dash", close(MapJourneyMotion.dash(points: duplicates, progress: 0.5).point, CGPoint(x: 60, y: 0)))

        // Literal positions make overscroll and incorrect follow framing visible.
        check("camera clamps at the top", close(MapJourneyMotion.cameraY(for: CGPoint(x: 10, y: 100), viewportHeight: 600, contentHeight: 2_000), 0))
        check("camera frames the Flame below centre", close(MapJourneyMotion.cameraY(for: CGPoint(x: 10, y: 800), viewportHeight: 600, contentHeight: 2_000), 470))
        check("camera clamps at the bottom", close(MapJourneyMotion.cameraY(for: CGPoint(x: 10, y: 1_900), viewportHeight: 600, contentHeight: 2_000), 1_400))
        check("camera handles content shorter than viewport", close(MapJourneyMotion.cameraY(for: CGPoint(x: 10, y: 800), viewportHeight: 600, contentHeight: 300), 0))
        print("Map journey motion: \(passed) passed, \(failed) failed")
        if failed > 0 { exit(1) }
    }
}
