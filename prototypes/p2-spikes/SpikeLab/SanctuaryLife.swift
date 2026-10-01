// Life in the painted Sanctuary (Part 4 §10): wind gusts that move everything together (B3), birds crossing the
// sky behind the arches (B4, with real occlusion from the relief), and a little moth that visits the Flame (A7),
// which watches it and drifts after it.
import RealityKit
import UIKit

@MainActor
final class SanctuaryLife {
    let root = Entity()
    private(set) var wind: Float = 0            // signed strength, about −1…1
    private var time: Float = 0
    private var rng = SeededRandom(seed: 99)
    private let noise = SmoothNoise(seed: 5)

    private var gustStart: Float = 6, gustLength: Float = 3.5, gustDir: Float = 1

    private struct Bird { let e: ModelEntity; var x: Float; let y: Float; let z: Float; let speed: Float; let phase: Float }
    private var birds: [Bird] = []
    private var nextFlock: Float = 3
    private var birdTexture: TextureResource?

    private var moth: ModelEntity?
    private var mothStart: Float = 8
    private let mothLength: Float = 11

    func build() async throws {
        birdTexture = try await TextureResource(named: "bird.png")
        let mothTex = try await TextureResource(named: "moth.png")
        var m = UnlitMaterial()
        m.color = .init(tint: .white, texture: PaintedRig.clamped(mothTex))
        m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
        let e = ModelEntity(mesh: .generatePlane(width: 0.026, height: 0.0195), materials: [m])
        e.scale = .zero
        root.addChild(e); moth = e
    }

    /// Steps the world's life. `flameAt` is where the Flame's chest is (world space); returns where the Flame
    /// should look (normalized −1…1 around itself), or nil when there's nothing to watch.
    func update(dt: Float, flameAt: SIMD3<Float>) -> SIMD2<Float>? {
        time += dt
        stepWind()
        stepBirds(dt)
        return stepMoth(flameAt: flameAt)
    }

    // MARK: Wind: a light breeze, and every 9–20 s a gust that rises and falls over 3–4 s.
    private func stepWind() {
        if time > gustStart + gustLength {
            gustStart = time + Float.random(in: 9...20, using: &rng)
            gustLength = Float.random(in: 3...4.5, using: &rng)
            gustDir = Bool.random(using: &rng) ? 1 : -1
        }
        let k = (time - gustStart) / gustLength
        let gust: Float = (k > 0 && k < 1) ? sin(k * .pi) * (0.8 + 0.2 * noise.sample(time * 3)) : 0
        let breeze = 0.15 + 0.08 * noise.sample(time * 0.4)
        wind = gustDir * (breeze + gust)
    }

    // MARK: Birds: a small flock now and then, flapping, crossing behind the arches.
    private func stepBirds(_ dt: Float) {
        if time > nextFlock, let tex = birdTexture {
            nextFlock = time + Float.random(in: 14...26, using: &rng)
            let dir: Float = Bool.random(using: &rng) ? 1 : -1
            let baseY = Float.random(in: 0.12...0.26, using: &rng)
            for k in 0..<Int.random(in: 2...4, using: &rng) {
                var m = UnlitMaterial()
                m.color = .init(tint: .white, texture: PaintedRig.clamped(tex))
                m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
                let size = Float.random(in: 0.012...0.018, using: &rng)
                let e = ModelEntity(mesh: .generatePlane(width: size, height: size * 0.5), materials: [m])
                root.addChild(e)
                birds.append(Bird(e: e, x: -0.55 * dir - Float(k) * 0.04 * dir, y: baseY + Float(k) * 0.012,
                                  z: -1.3, speed: 0.07 * dir * Float.random(in: 0.85...1.15, using: &rng),
                                  phase: Float.random(in: 0...6, using: &rng)))
            }
        }
        for i in birds.indices {
            birds[i].x += birds[i].speed * dt
            let b = birds[i]
            b.e.position = [b.x, b.y + sin(time * 1.3 + b.phase) * 0.006, b.z]
            b.e.scale = [b.speed > 0 ? 1 : -1, 0.35 + 0.65 * abs(sin(time * 9 + b.phase)), 1]
        }
        birds.removeAll { b in
            if abs(b.x) > 0.7 { b.e.removeFromParent(); return true }
            return false
        }
    }

    // MARK: The moth: it visits for ~11 s every 25–35 s, fluttering around the Flame's head.
    private func stepMoth(flameAt: SIMD3<Float>) -> SIMD2<Float>? {
        guard let moth else { return nil }
        let k = (time - mothStart) / mothLength
        if k > 1 { mothStart = time + Float.random(in: 25...35, using: &rng) }
        guard k > 0, k < 1 else { moth.scale = .zero; return nil }
        let appear = min(1, min(k, 1 - k) * 8)                       // flutters in and out
        let t = time - mothStart
        let offset = SIMD3<Float>(sin(t * 0.9) * 0.07 + noise.sample(t * 2.3) * 0.015,
                                  0.075 + sin(t * 1.7) * 0.03 + noise.sample(t * 2.9 + 9) * 0.01,
                                  0.02 + cos(t * 0.7) * 0.015)
        moth.position = flameAt + offset
        moth.scale = [appear * (0.25 + 0.75 * abs(sin(t * 15))), appear, 1]
        return SIMD2(max(-1, min(1, offset.x / 0.07)), max(-1, min(1, (offset.y - 0.04) / 0.06)))
    }
}
