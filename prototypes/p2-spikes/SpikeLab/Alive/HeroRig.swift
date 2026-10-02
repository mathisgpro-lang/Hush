// Codex's real hero painting, alive (route C preview, before the separate layers exist).
// Motion is fluid and continuous: a FluidBody (springs, gravity, organic drift) is stepped every frame and drives
// where the Flame stands, its hops, squash and stretch, its lean, and the follow-through of its flame hair.
import RealityKit
import UIKit
import Metal

@MainActor
final class HeroRig: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()          // kept for FlameRig symmetry
    private let walkPivot = Entity()  // where it stands on the ground
    private let bodyPivot = Entity()  // at the feet: squash, stretch and lean happen around here
    private var hero: ModelEntity?
    private var reflection: ModelEntity?
    private let reflectPivot = Entity()
    private var landingPuff: Entity?
    /// Where it stands along the ground (meters, before any scene scale): scenes use it to place its light.
    var standingX: Float { body.x }
    private var faces: [String: TextureResource] = [:]
    private var eyesHeldClosed = false
    private var body = FluidBody(seed: 11)
    private var behaviorRoll: Float = 0, fingerRoll: Float = 0
    private var mood: Float = 0.8, brightness: Float = 1
    var updates: EventSubscription?
    /// In a scene, the world lights the Flame (A2: rim and haze); outside one (S1), it doesn't.
    var inScene = false
    /// Wind from the scene (B3): bends the hair and leans the body a little.
    var wind: Float = 0
    var log: [String] = []

    private let sortGroup = ModelSortGroup(depthPass: nil)
    private static let feetY: Float = -0.09

    /// Which painted Flame to use (e.g. "hero" or "d", the root frame's own Flame), how far its feet sit above the
    /// image's bottom (fraction of its height), whether to add a reflection and extra glows (the root frame already
    /// paints its own glow), and how much it drifts (a sitting Flame barely moves).
    private let base: String, footInset: Float, withReflection: Bool, withGlows: Bool
    /// A stationary Flame stays exactly where it sits (no drifting, no leaning toward fingers or moths): only in-place life.
    var stationary = false
    init(base: String = "hero", footInset: Float = 0.044, reflection: Bool = true, glows: Bool = true, wander: Float = 0.06) {
        self.base = base; self.footInset = footInset; self.withReflection = reflection; self.withGlows = glows
        body.wanderRange = wander
        leanPivot.addChild(walkPivot)
        walkPivot.addChild(bodyPivot)
        bodyPivot.position = [0, Self.feetY, 0]
        bodyPivot.addChild(lookPivot)
        walkPivot.addChild(reflectPivot)
    }

    func build() async throws {
        let tex = try await TextureResource(named: "\(base)-keyed.png")
        faces = ["open": tex,
                 "blink": try await TextureResource(named: "\(base)-blink.png"),
                 "happy": try await TextureResource(named: "\(base)-happy.png")]
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
            m.custom.value = [0.8, 1, 0, 0]       // x mood, y brightness, zw hair follow-through
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            m.writesDepth = false
            material = m
        }
        let e = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        e.position = [0, -footInset * h, 0]
        e.components.set(ModelSortGroupComponent(group: sortGroup, order: 2))
        lookPivot.addChild(e); hero = e

        // Its reflection (A4): the same painting mirrored under its feet; the pivot mirrors the body every frame.
        if withReflection, let lib {
            var u = unlit; u.faceCulling = .none
            var m = try CustomMaterial(from: u, surfaceShader: .init(named: "heroReflection", in: lib),
                                       geometryModifier: .init(named: "heroLive", in: lib))
            m.custom.value = [0.8, 1, 0, 0]; m.faceCulling = .none
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
            let r = ModelEntity(mesh: e.model!.mesh, materials: [m])
            r.position = [0, -0.012, 0]
            r.components.set(ModelSortGroupComponent(group: sortGroup, order: 1))
            reflectPivot.addChild(r); reflection = r
        }
        // A puff of embers when it lands (A3).
        let puff = Entity()
        var pe = ParticleEmitterComponent()
        pe.emitterShape = .sphere; pe.emitterShapeSize = [0.05, 0.005, 0.02]
        pe.emissionDirection = [0, 1, 0]; pe.speed = 0.06; pe.speedVariation = 0.03
        pe.mainEmitter.birthRate = 0; pe.burstCount = 24; pe.burstCountVariation = 6
        pe.mainEmitter.lifeSpan = 0.7; pe.mainEmitter.size = 0.003; pe.mainEmitter.blendMode = .additive
        pe.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.7, blue: 0.3, alpha: 1)))
        pe.isEmitting = false
        puff.components.set(pe); puff.position = [0, Self.feetY + 0.005, 0.01]
        walkPivot.addChild(puff); landingPuff = puff

        if withGlows, let lib {
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
            lookPivot.addChild(try glow([0.32, 0.32], at: [0, 0.12, -0.02], strength: 0.35, order: 1))     // halo
        }

        let embers = Entity()
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.1, 0.08, 0.02]; p.emissionDirection = [0, 1, 0]; p.speed = 0.035
        p.mainEmitter.birthRate = 10; p.mainEmitter.lifeSpan = 2.4; p.mainEmitter.size = 0.003
        p.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.72, blue: 0.3, alpha: 1))); p.mainEmitter.blendMode = .additive
        embers.components.set(p); embers.position = [0, 0.15, 0.01]
        lookPivot.addChild(embers)
    }

    // MARK: Every frame

    func update(dt: Float) {
        if stationary { body.bias = 0 }
        body.extraRoll = behaviorRoll + fingerRoll - wind * 0.03
        body.step(dt: dt)
        walkPivot.transform.translation = [stationary ? 0 : body.x, 0, 0]
        bodyPivot.transform = Transform(scale: [body.scaleX, body.scaleY, 1],
                                        rotation: simd_quatf(angle: body.roll, axis: [0, 0, 1]),
                                        translation: [0, Self.feetY + body.y, 0])
        reflectPivot.transform = Transform(scale: [body.scaleX, -body.scaleY, 1],
                                           rotation: simd_quatf(angle: -body.roll, axis: [0, 0, 1]),
                                           translation: [0, Self.feetY - body.y, 0])
        let drag = body.hairDrag + SIMD2(wind * 0.012, 0)
        for e in [hero, reflection].compactMap({ $0 }) {
            guard var comp = e.model, var m = comp.materials.first as? CustomMaterial else { continue }
            let b = (inScene && e === hero) ? brightness + 10 : brightness
            m.custom.value = [mood, b, drag.x, drag.y]
            comp.materials = [m]; e.model = comp
        }
        if body.landed > 0.2, let puff = landingPuff, var pe = puff.components[ParticleEmitterComponent.self] {
            pe.burst()
            puff.components.set(pe)
        }
    }

    // MARK: Behaviors set targets; the physics makes them fluid

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: hold(roll: 0.08, for: 1.4)
        case .glanceRight: hold(roll: -0.08, for: 1.4)
        case .glanceUp, .watchEmber: body.stretchTarget = 1.05; hold(roll: 0.03, for: 1.2); after(1.2) { self.body.stretchTarget = 1 }
        case .lookAtYou: smile(1.0); body.hop(height: 0.01)
        case .smallHop: body.hop(height: 0.022)
        case .stretch:
            setFaceTemporarily("blink", 1.0)
            body.stretchTarget = 1.12
            after(0.9) { self.body.stretchTarget = 1 }
        case .sway, .hum:
            for k in 0..<4 { after(Double(k) * 0.45) { self.behaviorRoll = k.isMultiple(of: 2) ? 0.06 : -0.06 } }
            after(1.8) { self.behaviorRoll = 0 }
        case .dance:
            smile(2.4)
            for k in 0..<4 { after(Double(k) * 0.55) { self.body.hop(height: 0.016); self.behaviorRoll = k.isMultiple(of: 2) ? 0.08 : -0.08 } }
            after(2.3) { self.behaviorRoll = 0 }
        case .wander:
            body.bias = Float.random(in: 0.03...0.06) * (Bool.random() ? 1 : -1)
            after(3.0) { self.body.bias = 0; self.smile(0.6) }
        case .yawn: closeEyes(for: 1.2); body.stretchTarget = 1.07; after(1.2) { self.body.stretchTarget = 1 }
        case .doze:
            closeEyes(for: 3.5); body.resting = true; body.stretchTarget = 0.96; behaviorRoll = 0.04
            after(3.5) { self.body.resting = false; self.body.stretchTarget = 1; self.behaviorRoll = 0 }
        }
    }

    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle: smile(0.6); body.hop(height: 0.016)
        case .leanIn: body.stretchTarget = 1.07; after(0.7) { self.body.stretchTarget = 1 }
        case .cheer: smile(0.9); body.hop(height: 0.045)
        case .pillar(let p):
            smile(0.8)
            switch p {
            case .body: body.hop(height: 0.03)
            case .mind: hold(roll: 0.1, for: 0.9)
            case .heart: body.stretchTarget = 0.95; after(0.4) { self.body.stretchTarget = 1 }
            case .spirit: body.hop(height: 0.012); body.stretchTarget = 1.04; after(1.2) { self.body.stretchTarget = 1 }
            case .craft: body.stretchTarget = 0.93; after(0.15) { self.body.stretchTarget = 1 }
            case .world:
                for k in 0..<3 { after(Double(k) * 0.4) { self.behaviorRoll = k.isMultiple(of: 2) ? 0.08 : -0.08 } }
                after(1.2) { self.behaviorRoll = 0 }
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
        body.bias = x * 0.03           // it drifts toward your finger…
        fingerRoll = -x * 0.08         // …and leans to look at it
    }

    func lean(_ tilt: SIMD2<Float>) { leanPivot.orientation = simd_quatf(angle: -max(-0.35, min(0.35, tilt.x * 0.5)), axis: [0, 0, 1]) }

    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        self.mood = mood
        body.energy = mood
        brightness = min(1, 0.76 + mood * 0.3) * (timeOfDay == .night ? 0.75 : 1)   // at a normal mood: the painting's exact colors
        if timeOfDay == .night && mood < 0.3 { eyesHeldClosed = true; body.resting = true; setFace("blink") }
        else if eyesHeldClosed && body.resting { eyesHeldClosed = false; body.resting = false; setFace("open") }
    }

    func mouth(_ open: Float) {}

    // MARK: Helpers

    private func hold(roll: Float, for seconds: Double) {
        behaviorRoll = roll
        after(seconds) { self.behaviorRoll = 0 }
    }

    private func setFace(_ key: String) {
        guard let t = faces[key] else { return }
        for e in [hero, reflection].compactMap({ $0 }) {
            guard var comp = e.model, var m = comp.materials.first as? CustomMaterial else { continue }
            m.baseColor = .init(tint: m.baseColor.tint, texture: .init(t))
            comp.materials = [m]; e.model = comp
        }
    }

    private func closeEyes(for s: Double) {
        eyesHeldClosed = true; setFace("blink")
        after(s) { self.eyesHeldClosed = false; self.setFace("open") }
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
