// A quick look at Codex's real hero painting, alive (route C preview, before the separate layers exist).
// One deforming layer: no blinking or mouth yet (those need Codex's face parts, queued).
import RealityKit
import UIKit
import Metal

@MainActor
final class HeroRig: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()
    private var hero: ModelEntity?
    private var faces: [String: TextureResource] = [:]
    private var eyesHeldClosed = false
    var log: [String] = []

    private let sortGroup = ModelSortGroup(depthPass: nil)

    init() { leanPivot.addChild(lookPivot) }

    private func setFace(_ key: String) {
        guard let hero, var comp = hero.model, var m = comp.materials.first as? CustomMaterial, let t = faces[key] else { return }
        m.baseColor = .init(tint: m.baseColor.tint, texture: .init(t))   // the shader samples with clamp itself
        comp.materials = [m]; hero.model = comp
    }
    private func closeEyes(for s: Double) {
        eyesHeldClosed = true; setFace("blink")
        after(s) { self.eyesHeldClosed = false; self.setFace("open") }
    }

    func build() async throws {
        let tex = try await TextureResource(named: "hero-keyed.png")
        faces = ["open": tex,
                 "blink": try await TextureResource(named: "hero-blink.png"),
                 "happy": try await TextureResource(named: "hero-happy.png")]
        let aspect = Float(tex.width) / Float(tex.height)
        let h: Float = 0.31, w = h * aspect
        let (nx, ny) = (16, 32)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            pos.append([(u - 0.5) * w, v * h, 0]); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: "hero")
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: PaintedRig.clamped(tex))
        unlit.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        unlit.writesDepth = false
        var material: any Material = unlit
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        if let lib {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "heroFireSurface", in: lib),
                                       geometryModifier: .init(named: "heroLive", in: lib))
            m.custom.value = [0.8, 1, 0, 0]
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            m.writesDepth = false
            material = m
        }
        let e = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        e.position = [0, -0.10, 0]
        e.components.set(ModelSortGroupComponent(group: sortGroup, order: 2))
        lookPivot.addChild(e); hero = e

        // Light from the Flame: a pool on the ground and a halo behind it, both breathing with the core.
        if let lib {
            let glowTex = try await TextureResource(named: "glow.png")
            func glow(_ size: SIMD2<Float>, at p: SIMD3<Float>, strength: Float, order: Int32) throws -> ModelEntity {
                var u = UnlitMaterial()
                u.color = .init(tint: .white, texture: PaintedRig.clamped(glowTex))
                u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false
                var m = try CustomMaterial(from: u, surfaceShader: .init(named: "glowPulse", in: lib))
                m.custom.value = [strength, 0, 0, 0]; m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
                let g = ModelEntity(mesh: .generatePlane(width: size.x, height: size.y), materials: [m])
                g.position = p
                g.components.set(ModelSortGroupComponent(group: sortGroup, order: order))
                return g
            }
            lookPivot.addChild(try glow([0.34, 0.07], at: [0, -0.095, -0.01], strength: 0.85, order: 0))   // ground pool
            lookPivot.addChild(try glow([0.36, 0.36], at: [0, 0.02, -0.02], strength: 0.35, order: 1))    // halo
        }

        let embers = Entity()
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.1, 0.08, 0.02]; p.emissionDirection = [0, 1, 0]; p.speed = 0.035
        p.mainEmitter.birthRate = 10; p.mainEmitter.lifeSpan = 2.4; p.mainEmitter.size = 0.003
        p.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.72, blue: 0.3, alpha: 1))); p.mainEmitter.blendMode = .additive
        embers.components.set(p); embers.position = [0, 0.05, 0.01]
        lookPivot.addChild(embers)
    }

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: tilt(0.06, hold: 1.4)
        case .glanceRight: tilt(-0.06, hold: 1.4)
        case .smallHop, .stretch: hop(0.015)
        case .sway, .hum: tilt(0.05, hold: 0.5); after(0.6) { self.tilt(-0.05, hold: 0.5) }
        case .yawn: closeEyes(for: 1.2)
        case .doze: closeEyes(for: 3.5)
        case .lookAtYou: setFace("happy"); after(0.9) { if !self.eyesHeldClosed { self.setFace("open") } }
        default: break
        }
    }
    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle:
            setFace("happy"); hop(0.012); squash()
            after(0.55) { if !self.eyesHeldClosed { self.setFace("open") } }
        case .leanIn: scale(1.06); after(0.7) { self.scale(1) }
        case .cheer, .pillar:
            setFace("happy"); hop(0.03)
            after(0.7) { if !self.eyesHeldClosed { self.setFace("open") } }
        }
    }
    func blink() {
        guard !eyesHeldClosed else { return }
        setFace("blink")
        after(0.12) { if !self.eyesHeldClosed { self.setFace("open") } }
    }
    func look(at point: SIMD2<Float>?) {
        var t = lookPivot.transform
        let x = point?.x ?? 0
        t.translation.x = x * 0.006
        t.rotation = simd_quatf(angle: -x * 0.05, axis: [0, 0, 1])
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.2, timingFunction: .easeOut)
    }
    func lean(_ tilt: SIMD2<Float>) { leanPivot.orientation = simd_quatf(angle: -max(-0.35, min(0.35, tilt.x * 0.5)), axis: [0, 0, 1]) }
    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        guard let hero, var comp = hero.model, var m = comp.materials.first as? CustomMaterial else { return }
        let bright = (0.6 + mood * 0.4) * (timeOfDay == .night ? 0.75 : 1)
        m.custom.value = [mood, bright, 0, 0]
        if timeOfDay == .night && mood < 0.3 { eyesHeldClosed = true; m.baseColor = .init(tint: m.baseColor.tint, texture: faces["blink"].map { CustomMaterial.Texture($0) } ?? m.baseColor.texture) }
        else if eyesHeldClosed { eyesHeldClosed = false; m.baseColor = .init(tint: m.baseColor.tint, texture: faces["open"].map { CustomMaterial.Texture($0) } ?? m.baseColor.texture) }
        comp.materials = [m]; hero.model = comp
    }
    func mouth(_ open: Float) {}

    private func tilt(_ a: Float, hold: Double) {
        var t = lookPivot.transform; t.rotation = simd_quatf(angle: a, axis: [0, 0, 1])
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.35, timingFunction: .easeInOut)
        after(hold) { var t2 = self.lookPivot.transform; t2.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
            self.lookPivot.move(to: t2, relativeTo: self.leanPivot, duration: 0.5, timingFunction: .easeInOut) }
    }
    private func hop(_ h: Float) {
        var t = lookPivot.transform; t.translation.y = h
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.18, timingFunction: .easeOut)
        after(0.18) { var t2 = self.lookPivot.transform; t2.translation.y = 0
            self.lookPivot.move(to: t2, relativeTo: self.leanPivot, duration: 0.25, timingFunction: .easeIn) }
    }
    private func squash() {
        var t = lookPivot.transform; t.scale = [1.05, 0.95, 1]
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.1)
        after(0.12) { self.scale(1) }
    }
    private func scale(_ s: Float) {
        var t = lookPivot.transform; t.scale = .init(repeating: s)
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.25, timingFunction: .easeInOut)
    }
    private func after(_ s: Double, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in try? await Task.sleep(for: .seconds(s)); work() }
    }
}
