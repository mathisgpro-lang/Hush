// Living elements on top of the painted Sanctuary (decision 118): each one is its own thing, not warped paint.
// Real flames burning in the braziers, spray and mist where the waterfalls land, clouds drifting behind the ruins
// (the relief's depth hides them behind nearer stone), fish glints on the sea, fireflies that come out at night.
import RealityKit
import UIKit

@MainActor
final class WorldElements {
    let root = Entity()
    private var clouds: [(e: ModelEntity, speed: Float, baseX: Float)] = []
    private var fireflies: Entity?
    private var flames: [Entity] = []
    private var time: Float = 0
    private var cloudBounds: Float = 0.5

    /// Painting uv → a point on the relief (from the scene).
    func build(spot: (Float, Float) -> SIMD3<Float>, paintingW: Float) async throws {
        // Brazier flames (uv of each flame's base, and its size).
        for (u, v, s) in [(0.139, 0.573, 1.0), (0.397, 0.579, 0.8), (0.737, 0.575, 1.0), (0.816, 0.548, 1.1), (0.308, 0.431, 1.1), (0.109, 0.378, 1.6)] as [(Float, Float, Float)] {
            let e = Entity()
            e.components.set(flame(size: s))
            e.position = spot(u, v) + SIMD3(0, 0, 0.004)
            root.addChild(e); flames.append(e)
        }
        // Waterfall feet: spray and rolling mist.
        for (u, v, s) in [(0.587, 0.155, 1.6), (0.865, 0.28, 1.4), (0.962, 0.427, 1.0), (0.03, 0.38, 0.8)] as [(Float, Float, Float)] {
            let spray = Entity(); spray.components.set(sprayEmitter(size: s))
            spray.position = spot(u, v) + SIMD3(0, 0.004, 0.004)
            let mist = Entity(); mist.components.set(mistEmitter(size: s))
            mist.position = spray.position
            root.addChild(spray); root.addChild(mist)
        }
        // Fish glints on the open sea (lower right).
        let glints = Entity()
        var g = ParticleEmitterComponent()
        g.emitterShape = .box; g.emitterShapeSize = [0.14, 0.001, 0.06]
        g.mainEmitter.birthRate = 3; g.mainEmitter.lifeSpan = 0.5; g.speed = 0.004
        g.mainEmitter.size = 0.004; g.mainEmitter.sizeMultiplierAtEndOfLifespan = 0.1; g.mainEmitter.blendMode = .additive
        g.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.95, blue: 0.85, alpha: 1)))
        glints.components.set(g); glints.position = spot(0.86, 0.14) + SIMD3(0, 0, 0.01)
        root.addChild(glints)
        // Fireflies over the circle and the gardens (only at night; rate set each frame).
        let ff = Entity()
        var f = ParticleEmitterComponent()
        f.emitterShape = .box; f.emitterShapeSize = [0.35, 0.18, 0.12]
        f.emissionDirection = [0, 1, 0]; f.speed = 0.006; f.speedVariation = 0.006
        f.mainEmitter.birthRate = 0; f.mainEmitter.lifeSpan = 4; f.mainEmitter.lifeSpanVariation = 1.5
        f.mainEmitter.size = 0.0045; f.mainEmitter.blendMode = .additive
        f.mainEmitter.color = .constant(.single(UIColor(red: 0.85, green: 1, blue: 0.45, alpha: 1)))
        f.mainEmitter.opacityCurve = .gradualFadeInOut
        ff.components.set(f); ff.position = spot(0.5, 0.42) + SIMD3(0, 0.05, 0.08)
        root.addChild(ff); fireflies = ff
        // Clouds drifting across the sky, just in front of it and behind everything nearer.
        let tex = try await TextureResource(named: "cloud.png")
        let sky = spot(0.75, 0.78)
        cloudBounds = paintingW * 0.7
        for k in 0..<7 {
            var m = UnlitMaterial()
            m.color = .init(tint: UIColor(red: 1, green: 0.82, blue: 0.78, alpha: 0.55), texture: .init(tex))
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
            let w = Float.random(in: 0.18...0.34)
            let e = ModelEntity(mesh: .generatePlane(width: w, height: w * 0.45), materials: [m])
            let x = Float.random(in: -cloudBounds...cloudBounds)
            e.position = [x, sky.y + Float.random(in: -0.06...0.1), sky.z + 0.02 + Float(k) * 0.002]
            root.addChild(e); clouds.append((e, Float.random(in: 0.004...0.01), x))
        }
    }

    private func flame(size s: Float) -> ParticleEmitterComponent {
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.004 * s, 0.002 * s, 0.004 * s]
        p.emissionDirection = [0, 1, 0]; p.speed = 0.022 * s; p.speedVariation = 0.008 * s
        p.mainEmitter.birthRate = 70; p.mainEmitter.lifeSpan = 0.45; p.mainEmitter.lifeSpanVariation = 0.15
        p.mainEmitter.size = 0.0075 * s; p.mainEmitter.sizeMultiplierAtEndOfLifespan = 0.15
        p.mainEmitter.blendMode = .additive
        p.mainEmitter.color = .evolving(start: .single(UIColor(red: 1, green: 0.92, blue: 0.6, alpha: 1)),
                                        end: .single(UIColor(red: 1, green: 0.35, blue: 0.08, alpha: 0.6)))
        p.mainEmitter.noiseStrength = 0.004; p.mainEmitter.noiseScale = 2; p.mainEmitter.noiseAnimationSpeed = 2
        return p
    }

    private func sprayEmitter(size s: Float) -> ParticleEmitterComponent {
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.02 * s, 0.003, 0.01 * s]
        p.emissionDirection = [0, 1, 0]; p.speed = 0.02; p.speedVariation = 0.015
        p.mainEmitter.birthRate = 40 * s; p.mainEmitter.lifeSpan = 0.9; p.mainEmitter.lifeSpanVariation = 0.3
        p.mainEmitter.size = 0.004; p.mainEmitter.sizeMultiplierAtEndOfLifespan = 2.2
        p.mainEmitter.acceleration = [0, -0.04, 0]
        p.mainEmitter.color = .evolving(start: .single(UIColor(white: 1, alpha: 0.8)), end: .single(UIColor(white: 1, alpha: 0)))
        p.mainEmitter.blendMode = .alpha
        return p
    }

    private func mistEmitter(size s: Float) -> ParticleEmitterComponent {
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.03 * s, 0.004, 0.015 * s]
        p.emissionDirection = [0.3, 1, 0]; p.speed = 0.006; p.speedVariation = 0.004
        p.mainEmitter.birthRate = 6 * s; p.mainEmitter.lifeSpan = 3; p.mainEmitter.lifeSpanVariation = 1
        p.mainEmitter.size = 0.02 * s; p.mainEmitter.sizeMultiplierAtEndOfLifespan = 2.5
        p.mainEmitter.color = .evolving(start: .single(UIColor(white: 1, alpha: 0.28)), end: .single(UIColor(white: 1, alpha: 0)))
        p.mainEmitter.blendMode = .alpha
        return p
    }

    /// Each frame: clouds drift (and take the color of the hour), fireflies come out at night, flames dance in the wind.
    func update(dt: Float, hour: Float, wind: Float) {
        time += dt
        let night = max(0, min(1, (hour - 20.5) / 2)) + max(0, min(1, (6.5 - hour) / 1.5))
        let n = min(1, night)
        let tint: UIColor = n > 0.5 ? UIColor(red: 0.45, green: 0.5, blue: 0.7, alpha: 0.35)
            : (hour > 9.5 && hour < 17) ? UIColor(white: 1, alpha: 0.6) : UIColor(red: 1, green: 0.82, blue: 0.78, alpha: 0.55)
        for i in clouds.indices {
            var c = clouds[i]
            var p = c.e.position
            p.x += (c.speed + wind * 0.004) * dt
            if p.x > cloudBounds { p.x = -cloudBounds }
            c.e.position = p
            if var comp = c.e.model, var m = comp.materials.first as? UnlitMaterial {
                m.color = .init(tint: tint, texture: m.color.texture); comp.materials = [m]; c.e.model = comp
            }
            clouds[i] = c
        }
        if let ff = fireflies, var f = ff.components[ParticleEmitterComponent.self] {
            f.mainEmitter.birthRate = 9 * n; ff.components.set(f)
        }
        for e in flames {
            guard var f = e.components[ParticleEmitterComponent.self] else { continue }
            f.mainEmitter.acceleration = [wind * 0.03, 0, 0]
            e.components.set(f)
        }
    }
}
