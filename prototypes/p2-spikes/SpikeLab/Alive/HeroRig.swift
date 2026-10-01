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
    var log: [String] = []

    init() { leanPivot.addChild(lookPivot) }

    func build() async throws {
        let tex = try await TextureResource(named: "hero-keyed.png")
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
        if let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() {
            var m = try CustomMaterial(from: unlit, geometryModifier: .init(named: "heroLive", in: lib))
            m.custom.value = [0.8, 0, 0, 0]
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            m.writesDepth = false
            material = m
        }
        let e = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        e.position = [0, -0.10, 0]
        lookPivot.addChild(e); hero = e

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
        default: break
        }
    }
    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle: hop(0.012); squash()
        case .leanIn: scale(1.06); after(0.7) { self.scale(1) }
        case .cheer, .pillar: hop(0.03)
        }
    }
    func blink() {}
    func look(at point: SIMD2<Float>?) {
        var t = lookPivot.transform
        t.rotation = simd_quatf(angle: (point?.x ?? 0) * 0.25, axis: [0, 1, 0])
        lookPivot.move(to: t, relativeTo: leanPivot, duration: 0.15)
    }
    func lean(_ tilt: SIMD2<Float>) { leanPivot.orientation = simd_quatf(angle: -max(-0.35, min(0.35, tilt.x * 0.5)), axis: [0, 0, 1]) }
    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        guard let hero, var comp = hero.model, var m = comp.materials.first as? CustomMaterial else { return }
        m.custom.value = [mood, 0, 0, 0]
        let b = CGFloat((0.55 + mood * 0.45) * (timeOfDay == .night ? 0.75 : 1))
        m.baseColor = .init(tint: UIColor(white: b, alpha: 1), texture: m.baseColor.texture)
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
