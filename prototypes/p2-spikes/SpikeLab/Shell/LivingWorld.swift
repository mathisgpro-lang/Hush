// What every world offers the one home interface (Mathis, 2026-10-03: "the same interface in every world"): your
// Spark, looking around, where its quests wait, where the light flies to. The Sanctuary and every realm conform, so
// HomeView runs identically in all of them; only the world underneath changes.
import SwiftUI
import simd

@MainActor
protocol LivingWorld: AnyObject {
    var hero: HeroRig { get }
    func fitFlame(heightFraction: Float, growth: Float)
    var pan: SIMD2<Float> { get }
    var panTarget: SIMD2<Float> { get set }
    var panLimit: SIMD2<Float> { get }
    var fingerDown: Bool { get set }
    var focus: SIMD3<Float>? { get set }
    /// Screen points per meter at the painting (to turn finger movement into looking around).
    var pointsPerMeterScale: Float { get }
    /// A spot of the world's home painting (uv, v up) on screen, following the camera.
    func screenPoint(world uv: SIMD2<Float>, in size: CGSize) -> CGPoint
    /// Where the light from a finished quest flies to (your Spark), in home-painting uv.
    var flameUV: SIMD2<Float> { get }
    /// Where the quests you take wait in this world (on the ground around the circle), in home-painting uv.
    var questSpots: [SIMD2<Float>] { get }
}

extension SanctuaryScene: LivingWorld {
    var pointsPerMeterScale: Float { 1 / SanctuaryScene.visibleHeight * 0.98 }
    func screenPoint(world uv: SIMD2<Float>, in size: CGSize) -> CGPoint { screenPoint(homeUV: uv, in: size) }
    var flameUV: SIMD2<Float> { stageCircle + SIMD2(0, 0.07) }
    var questSpots: [SIMD2<Float>] { [[0.30, 0.425], [0.775, 0.44], [0.42, 0.33]] }
}

extension RealmScene: LivingWorld {
    var pointsPerMeterScale: Float { 1 / (2 * RealmScene.distance * tan(RealmScene.fov / 2 * .pi / 180)) }
    func screenPoint(world uv: SIMD2<Float>, in size: CGSize) -> CGPoint { screenPoint(uv.x, uv.y, in: size) }
    var flameUV: SIMD2<Float> { circle + SIMD2(0, 0.05) }
    /// Around the realm's stone circle: left, right, and a little in front.
    var questSpots: [SIMD2<Float>] {
        if let set = RealmContent.questSpots(realm) { return set }
        let offsets: [SIMD2<Float>] = [[-0.24, 0.035], [0.25, 0.04], [-0.1, -0.075]]
        let lo = SIMD2<Float>(0.08, 0.06), hi = SIMD2<Float>(0.92, 0.9)
        return offsets.map { o in simd_clamp(circle + o, lo, hi) }
    }
}
