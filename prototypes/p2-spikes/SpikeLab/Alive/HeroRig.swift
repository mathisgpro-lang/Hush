// A quick look at Codex's real hero painting, alive (route C preview, before the separate layers exist).
// One deforming layer: no blinking or mouth yet (those need Codex's face parts, queued).
import RealityKit
import UIKit
import Metal

@MainActor
final class HeroRig: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()          // kept for FlameRig symmetry; the body moves through walkPivot and bodyPivot
    private let walkPivot = Entity()  // where the Flame stands on the ground (it wanders)
    private let bodyPivot = Entity()  // at the feet: hops, squash and stretch, and tilts happen around here
    private var walkX: Float = 0
    private var stepPhase = false
    private var hero: ModelEntity?
    private var faces: [String: TextureResource] = [:]
    private var eyesHeldClosed = false
    var log: [String] = []

    private let sortGroup = ModelSortGroup(depthPass: nil)

    init() {
        leanPivot.addChild(walkPivot)
        walkPivot.addChild(bodyPivot)
        bodyPivot.position = [0, -0.09, 0]
        bodyPivot.addChild(lookPivot)
    }

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
        let h: Float = 0.27, w = h * aspect
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
        e.position = [0, -0.012, 0]      // the painted feet sit a little above the image bottom
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
            walkPivot.addChild(try glow([0.26, 0.055], at: [0, -0.088, -0.01], strength: 0.85, order: 0))  // ground pool (stays down)
            lookPivot.addChild(try glow([0.32, 0.32], at: [0, 0.12, -0.02], strength: 0.35, order: 1))     // halo (moves with it)
        }

        let embers = Entity()
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.1, 0.08, 0.02]; p.emissionDirection = [0, 1, 0]; p.speed = 0.035
        p.mainEmitter.birthRate = 10; p.mainEmitter.lifeSpan = 2.4; p.mainEmitter.size = 0.003
        p.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.72, blue: 0.3, alpha: 1))); p.mainEmitter.blendMode = .additive
        embers.components.set(p); embers.position = [0, 0.15, 0.01]
        lookPivot.addChild(embers)
    }

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: lookAround(0.09, hold: 1.3)
        case .glanceRight: lookAround(-0.09, hold: 1.3)
        case .glanceUp, .watchEmber:
            pose(y: 0.004, sx: 0.97, sy: 1.05, roll: 0.03, duration: 0.5)
            after(1.2) { self.settle(0.5) }
        case .lookAtYou: smile(0.9); hop(0.012)
        case .smallHop: hop(0.02)
        case .stretch:
            setFaceTemporarily("blink", 1.0)
            pose(y: 0, sx: 0.93, sy: 1.11, roll: 0, duration: 0.55, timing: .easeInOut)
            after(0.95) { self.pose(y: 0, sx: 1.05, sy: 0.95, roll: 0, duration: 0.15); self.after(0.16) { self.settle(0.3) } }
        case .sway, .hum: rock(times: 3, angle: 0.06)
        case .dance:
            smile(2.2)
            for k in 0..<4 { after(Double(k) * 0.5) { self.hop(0.014, roll: k.isMultiple(of: 2) ? 0.09 : -0.09) } }
        case .wander: wander()
        case .yawn: closeEyes(for: 1.2); pose(y: 0, sx: 0.96, sy: 1.06, roll: 0, duration: 0.6); after(1.2) { self.settle(0.4) }
        case .doze: closeEyes(for: 3.5); pose(y: -0.002, sx: 1.03, sy: 0.96, roll: 0.04, duration: 1.0); after(3.5) { self.settle(0.6) }
        }
    }

    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle: smile(0.6); hop(0.014)
        case .leanIn: pose(y: 0, sx: 1.06, sy: 1.06, roll: 0, duration: 0.25); after(0.7) { self.settle(0.35) }
        case .cheer: smile(0.9); hop(0.04)
        case .pillar(let p):
            smile(0.8)
            switch p {
            case .body: hop(0.03)
            case .mind: lookAround(0.1, hold: 0.8)
            case .heart: pose(y: 0, sx: 1.05, sy: 0.97, roll: 0, duration: 0.3); after(0.5) { self.settle(0.4) }
            case .spirit: pose(y: 0.02, sx: 0.98, sy: 1.03, roll: 0, duration: 0.8, timing: .easeInOut); after(1.4) { self.settle(0.8) }
            case .craft: pose(y: -0.003, sx: 1.04, sy: 0.95, roll: 0, duration: 0.12); after(0.15) { self.settle(0.2) }
            case .world: rock(times: 2, angle: 0.08)
            }
        }
    }

    func blink() {
        guard !eyesHeldClosed else { return }
        setFace("blink")
        after(0.12) { if !self.eyesHeldClosed { self.setFace("open") } }
    }
    func look(at point: SIMD2<Float>?) {
        let x = point?.x ?? 0
        var t = lookPivot.transform
        t.translation.x = x * 0.008
        t.rotation = simd_quatf(angle: -x * 0.07, axis: [0, 0, 1])
        lookPivot.move(to: t, relativeTo: bodyPivot, duration: 0.2, timingFunction: .easeOut)
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

    // MARK: Motion toolkit (squash and stretch around the feet)

    private static let neutral = (y: Float(-0.09), sx: Float(1), sy: Float(1))

    private func pose(y: Float, sx: Float, sy: Float, roll: Float, duration: Double, timing: AnimationTimingFunction = .easeOut) {
        var t = bodyPivot.transform
        t.translation = [0, Self.neutral.y + y, 0]
        t.scale = [sx, sy, 1]
        t.rotation = simd_quatf(angle: roll, axis: [0, 0, 1])
        bodyPivot.move(to: t, relativeTo: walkPivot, duration: duration, timingFunction: timing)
    }

    private func settle(_ d: Double) { pose(y: 0, sx: 1, sy: 1, roll: 0, duration: d, timing: .easeOut) }

    /// A hop with anticipation, stretch, squash on landing and a settle: the classic bounce that reads as alive.
    private func hop(_ height: Float, roll: Float = 0) {
        pose(y: 0, sx: 1.07, sy: 0.92, roll: roll * 0.5, duration: 0.08)                       // crouch
        after(0.08) { self.pose(y: height, sx: 0.95, sy: 1.08, roll: roll, duration: 0.16) }      // launch, stretched
        after(0.24) { self.pose(y: 0, sx: 0.97, sy: 1.04, roll: roll * 0.5, duration: 0.16, timing: .easeIn) } // fall
        after(0.40) { self.pose(y: 0, sx: 1.09, sy: 0.90, roll: 0, duration: 0.06) }              // land, squashed
        after(0.46) { self.settle(0.2) }
    }

    private func lookAround(_ roll: Float, hold: Double) {
        pose(y: 0.002, sx: 1, sy: 1.02, roll: roll, duration: 0.35, timing: .easeInOut)
        var t = lookPivot.transform; t.translation.x = -roll * 0.08
        lookPivot.move(to: t, relativeTo: bodyPivot, duration: 0.35, timingFunction: .easeInOut)
        after(hold) {
            self.settle(0.45)
            var t2 = self.lookPivot.transform; t2.translation.x = 0
            self.lookPivot.move(to: t2, relativeTo: self.bodyPivot, duration: 0.45, timingFunction: .easeInOut)
        }
    }

    private func rock(times: Int, angle: Float) {
        for k in 0..<(times * 2) {
            after(Double(k) * 0.4) { self.pose(y: 0.002, sx: 1, sy: 1, roll: k.isMultiple(of: 2) ? angle : -angle, duration: 0.38, timing: .easeInOut) }
        }
        after(Double(times * 2) * 0.4) { self.settle(0.3) }
    }

    /// Walk to a new spot with a waddle: each step tilts side to side and bounces a little; the light pool follows.
    private func wander() {
        var target = Float.random(in: -0.06...0.06)
        if abs(target - walkX) < 0.03 { target = walkX > 0 ? walkX - 0.05 : walkX + 0.05 }
        let distance = target - walkX
        let steps = max(3, Int(abs(distance) / 0.012))
        let stepTime = 0.2
        let lean: Float = distance > 0 ? -0.04 : 0.04
        for k in 0..<steps {
            after(Double(k) * stepTime) {
                self.walkX += distance / Float(steps)
                var t = self.walkPivot.transform; t.translation.x = self.walkX
                self.walkPivot.move(to: t, relativeTo: self.leanPivot, duration: stepTime, timingFunction: .linear)
                self.stepPhase.toggle()
                self.pose(y: 0.006, sx: 0.98, sy: 1.03, roll: lean + (self.stepPhase ? 0.07 : -0.07), duration: stepTime * 0.5)
                self.after(stepTime * 0.5) { self.pose(y: 0, sx: 1.03, sy: 0.97, roll: lean, duration: stepTime * 0.5, timing: .easeIn) }
            }
        }
        after(Double(steps) * stepTime) { self.settle(0.25); self.smile(0.6) }
    }

    private func smile(_ seconds: Double) { setFaceTemporarily("happy", seconds) }

    private func setFaceTemporarily(_ key: String, _ seconds: Double) {
        guard !eyesHeldClosed else { return }
        setFace(key)
        after(seconds) { if !self.eyesHeldClosed { self.setFace("open") } }
    }

    private func after(_ s: Double, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in try? await Task.sleep(for: .seconds(s)); work() }
    }
}
