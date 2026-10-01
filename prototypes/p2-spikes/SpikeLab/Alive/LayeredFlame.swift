// The living layered Flame (route C, final form for P2): Codex's separate painted parts (docs/design/rig/),
// assembled live and driven by the same fluid physics as the hero preview (FluidBody). The body breathes with fire
// flowing through it; five flame tongues sway, stretch and trail behind on their own; the eyes blink, look around
// and squint; the brows react; the mouth smiles, opens with joy and talks in Emberspeak.
import RealityKit
import UIKit
import Metal

@MainActor
final class LayeredFlame: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()
    private let walkPivot = Entity()
    private let bodyPivot = Entity()
    private let facePivot = Entity()          // face parts shift more than the body when looking (parallax)
    private let hairPivot = Entity()
    private var bodyLayer: ModelEntity?
    private var tongues: [ModelEntity] = []
    private var tongueRest: [Float] = []
    private var eyes: [ModelEntity] = []      // left, right
    private var brows: [ModelEntity] = []
    private var mouthLayer: ModelEntity?
    private var textures: [String: TextureResource] = [:]
    private var body = FluidBody(seed: 17)
    private var behaviorRoll: Float = 0, fingerRoll: Float = 0
    private var look = SIMD2<Float>(0, 0), lookTarget = SIMD2<Float>(0, 0)
    private var browLift: Float = 0, browTarget: Float = 0
    private var eyesHeldClosed = false, eyeMode = "open"
    private var talkUntil: Float = 0, clock: Float = 0
    private var mood: Float = 0.8, brightness: Float = 1
    private let sortGroup = ModelSortGroup(depthPass: nil)
    private var order: Int32 = 0
    var updates: EventSubscription?
    var standingX: Float { body.x }
    var wind: Float = 0

    // Layout, measured on Codex's body painting (729 × 1105 px): the face and hair positions in those pixels.
    private static let feetY: Float = -0.09
    private static let bodyHeight: Float = 0.17
    private static let px: Float = bodyHeight / 1105
    private static func at(_ x: Float, _ y: Float) -> SIMD2<Float> { [(x - 364.5) * px, (1105 - y) * px] }

    init() {
        leanPivot.addChild(walkPivot)
        walkPivot.addChild(bodyPivot)
        bodyPivot.position = [0, Self.feetY, 0]
        bodyPivot.addChild(lookPivot)
        lookPivot.addChild(hairPivot)
        lookPivot.addChild(facePivot)
    }

    func build() async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let names = ["body", "tongue-0", "tongue-1", "tongue-2", "tongue-3", "tongue-4",
                     "eye-open-L", "eye-open-R", "eye-closed-L", "eye-closed-R", "eye-up", "eye-down",
                     "brow-L", "brow-R", "mouth-smile", "mouth-joy", "mouth-o", "mouth-flat", "mouth-talk"]
        for n in names { textures[n] = try await TextureResource(named: "lf-\(n).png") }
        func size(_ n: String, width: Float) -> SIMD2<Float> {
            let t = textures[n]!; return [width, width * Float(t.height) / Float(t.width)]
        }

        // Hair first (behind the head). Each tongue's base hides behind the round head; outer ones tilt outward.
        let hairScale: Float = 0.5 * Self.px                     // hair painting px → meters
        let headCenter = SIMD2<Float>(365, 290), headR: Float = 300
        for (i, dx) in [Float(-240), -130, 0, 130, 240].enumerated() {
            let n = "tongue-\(i)", t = textures[n]!
            let s = SIMD2<Float>(Float(t.width), Float(t.height)) * hairScale
            let surfaceY = headCenter.y - (headR * headR - dx * dx).squareRoot()
            let base = Self.at(365 + dx, surfaceY)
            let e = try plane(n, size: s, bottom: [base.x, base.y - s.y * 0.38, -0.004], lib: lib,
                              surface: "tongueFire", geometry: "tongueSway", custom: [Float(i) * 1.37, i == 2 ? 0.006 : 0.004, 1, 0])
            let tilt = -dx / 240 * 0.28
            e.orientation = simd_quatf(angle: tilt, axis: [0, 0, 1])
            hairPivot.addChild(e); tongues.append(e); tongueRest.append(tilt)
        }
        // The body (with the painted cheeks).
        let b = try plane("body", size: [729 * Self.px, Self.bodyHeight], bottom: [0, 0, 0], lib: lib,
                          surface: "layerBodyFire", custom: [0.8, 1, 0, 0])   // breathing comes from FluidBody
        lookPivot.addChild(b); bodyLayer = b
        // Eyes, brows, mouth.
        for (n, x) in [("eye-open-L", Float(228)), ("eye-open-R", 502)] {
            let s = size(n, width: 165 * Self.px), c = Self.at(x, 352)
            let e = try plane(n, size: s, bottom: [c.x, c.y - s.y / 2, 0.003], lib: nil)
            facePivot.addChild(e); eyes.append(e)
        }
        for (n, x) in [("brow-L", Float(222)), ("brow-R", 508)] {
            let s = size(n, width: 84 * Self.px), c = Self.at(x, 255)
            let e = try plane(n, size: s, bottom: [c.x, c.y - s.y / 2, 0.004], lib: nil)
            facePivot.addChild(e); brows.append(e)
        }
        let ms = size("mouth-smile", width: 120 * Self.px), mc = Self.at(365, 432)
        let m = try plane("mouth-smile", size: ms, bottom: [mc.x, mc.y - ms.y / 2, 0.003], lib: nil)
        facePivot.addChild(m); mouthLayer = m

        // Its light on the ground, and embers.
        if let lib {
            let glowTex = try await TextureResource(named: "glow.png")
            var u = UnlitMaterial()
            u.color = .init(tint: .white, texture: PaintedRig.clamped(glowTex))
            u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false
            var gm = try CustomMaterial(from: u, surfaceShader: .init(named: "glowPulse", in: lib))
            gm.custom.value = [0.85, 0, 0, 0]; gm.blending = .transparent(opacity: .init(floatLiteral: 1.0)); gm.writesDepth = false
            let pool = ModelEntity(mesh: .generatePlane(width: 0.24, height: 0.05), materials: [gm])
            pool.position = [0, Self.feetY + 0.002, -0.01]
            pool.components.set(ModelSortGroupComponent(group: sortGroup, order: -1))
            walkPivot.addChild(pool)
        }
        let embers = Entity()
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere; p.emitterShapeSize = [0.08, 0.06, 0.02]; p.emissionDirection = [0, 1, 0]; p.speed = 0.035
        p.mainEmitter.birthRate = 10; p.mainEmitter.lifeSpan = 2.2; p.mainEmitter.size = 0.003
        p.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.72, blue: 0.3, alpha: 1))); p.mainEmitter.blendMode = .additive
        embers.components.set(p); embers.position = [0, 0.16, 0.01]
        lookPivot.addChild(embers)
    }

    private func plane(_ tex: String, size: SIMD2<Float>, bottom: SIMD3<Float>, lib: MTLLibrary?,
                       surface: String? = nil, geometry: String? = nil, custom: SIMD4<Float> = .zero) throws -> ModelEntity {
        let (nx, ny) = geometry == nil ? (1, 1) : (6, 16)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            pos.append([(u - 0.5) * size.x, v * size.y, 0]); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: tex)
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: PaintedRig.clamped(textures[tex]!))
        unlit.blending = .transparent(opacity: .init(floatLiteral: 1.0)); unlit.writesDepth = false; unlit.faceCulling = .none
        var material: any RealityKit.Material = unlit
        if let lib, let surface {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: surface, in: lib),
                                       geometryModifier: geometry.map { .init(named: $0, in: lib) })
            m.custom.value = custom
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false; m.faceCulling = .none
            material = m
        }
        let e = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        e.position = bottom
        e.components.set(ModelSortGroupComponent(group: sortGroup, order: order)); order += 1
        return e
    }

    // MARK: Every frame

    func update(dt: Float) {
        clock += dt
        body.extraRoll = behaviorRoll + fingerRoll - wind * 0.03
        body.step(dt: dt)
        walkPivot.transform.translation = [body.x, 0, 0]
        bodyPivot.transform = Transform(scale: [body.scaleX, body.scaleY, 1],
                                        rotation: simd_quatf(angle: body.roll, axis: [0, 0, 1]),
                                        translation: [0, Self.feetY + body.y, 0])
        // Eyes and face ease toward where it's looking (the face shifts more than the body: a small turn).
        let k = 1 - exp(-dt * 10)
        look += (lookTarget - look) * k
        facePivot.position = [look.x * 0.008, look.y * 0.005, 0]
        hairPivot.position = [-look.x * 0.003, 0, 0]
        let wantUp = look.y > 0.45, wantDown = look.y < -0.45
        if !eyesHeldClosed {
            let mode = wantUp ? "up" : wantDown ? "down" : "open"
            if mode != eyeMode { setEyes(mode) }
        }
        browLift += (browTarget - browLift) * k
        for (i, br) in brows.enumerated() {
            br.position.y = Self.at(0, 255).y - br.model!.mesh.bounds.extents.y / 2 + browLift * 0.004
            br.orientation = simd_quatf(angle: (i == 0 ? 1 : -1) * browLift * 0.08, axis: [0, 0, 1])
        }
        // Hair follow-through and wind: each tongue bends from its base, outer ones a little more.
        let drag = body.hairDrag.x + wind * 0.012
        for (i, t) in tongues.enumerated() {
            let outer: Float = i == 2 ? 1 : 1.3
            t.orientation = simd_quatf(angle: tongueRest[i] - drag * 9 * outer, axis: [0, 0, 1])
        }
        // Talking: Emberspeak babble while talkUntil.
        if clock < talkUntil {
            let open = 0.5 + 0.5 * sin(clock * 17) * sin(clock * 6.3)
            mouth(open)
        }
        setBodyCustom()
    }

    private func setBodyCustom() {
        if let bodyLayer, var comp = bodyLayer.model, var m = comp.materials.first as? CustomMaterial {
            m.custom.value = [mood, brightness, 0, 0]; comp.materials = [m]; bodyLayer.model = comp
        }
    }

    // MARK: FlameRig

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: glance([-0.8, 0.1], roll: 0.07, hold: 1.4)
        case .glanceRight: glance([0.8, 0.1], roll: -0.07, hold: 1.4)
        case .glanceUp, .watchEmber: glance([0.25, 0.85], roll: 0.03, hold: 1.4); brow(1, for: 1.4)
        case .lookAtYou: glance([0, 0], roll: 0, hold: 1.2); smile(1.2); body.hop(height: 0.008)
        case .smallHop: body.hop(height: 0.022)
        case .stretch: closeEyes(for: 0.9); body.stretchTarget = 1.12; setMouth("o"); after(0.9) { self.body.stretchTarget = 1; self.setMouth("smile") }
        case .hum: talk(for: 1.6)
        case .sway: for k in 0..<4 { after(Double(k) * 0.45) { self.behaviorRoll = k.isMultiple(of: 2) ? 0.06 : -0.06 } }; after(1.8) { self.behaviorRoll = 0 }
        case .dance:
            smile(2.4); setMouth("joy")
            for k in 0..<4 { after(Double(k) * 0.55) { self.body.hop(height: 0.016); self.behaviorRoll = k.isMultiple(of: 2) ? 0.08 : -0.08 } }
            after(2.3) { self.behaviorRoll = 0; self.setMouth("smile") }
        case .wander:
            body.bias = Float.random(in: 0.03...0.06) * (Bool.random() ? 1 : -1)
            lookTarget = [body.bias > 0 ? 0.6 : -0.6, 0]
            after(3.0) { self.body.bias = 0; self.lookTarget = .zero; self.smile(0.6) }
        case .yawn: closeEyes(for: 1.2); setMouth("o"); body.stretchTarget = 1.07; after(1.2) { self.body.stretchTarget = 1; self.setMouth("smile") }
        case .doze:
            closeEyes(for: 3.5); setMouth("flat"); body.resting = true; body.stretchTarget = 0.96; behaviorRoll = 0.04
            after(3.5) { self.body.resting = false; self.body.stretchTarget = 1; self.behaviorRoll = 0; self.setMouth("smile") }
        }
    }

    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle: smile(0.7); setMouth("joy"); body.hop(height: 0.016); after(0.6) { self.setMouth("smile") }
        case .leanIn: body.stretchTarget = 1.07; brow(0.6, for: 0.7); after(0.7) { self.body.stretchTarget = 1 }
        case .cheer: smile(1.0); setMouth("joy"); brow(1, for: 0.8); body.hop(height: 0.045); after(0.9) { self.setMouth("smile") }
        case .pillar(let p):
            switch p {
            case .body: setMouth("joy"); body.hop(height: 0.03); after(0.6) { self.setMouth("smile") }
            case .mind: glance([0.3, 0.6], roll: 0.1, hold: 0.9); brow(1, for: 0.9); setMouth("o"); after(0.9) { self.setMouth("smile") }
            case .heart: smile(1.0); body.stretchTarget = 0.95; after(0.4) { self.body.stretchTarget = 1 }
            case .spirit: closeEyes(for: 1.2); body.hop(height: 0.012); body.stretchTarget = 1.04; after(1.2) { self.body.stretchTarget = 1 }
            case .craft: brow(-0.8, for: 0.8); setMouth("flat"); body.stretchTarget = 0.93; after(0.15) { self.body.stretchTarget = 1 }; after(0.8) { self.setMouth("smile") }
            case .world: talk(for: 1.0); for k in 0..<3 { after(Double(k) * 0.4) { self.behaviorRoll = k.isMultiple(of: 2) ? 0.08 : -0.08 } }; after(1.2) { self.behaviorRoll = 0 }
            }
        }
    }

    func blink() {
        guard !eyesHeldClosed else { return }
        setEyes("closed")
        after(0.12) { if !self.eyesHeldClosed { self.setEyes("open") } }
    }

    func look(at point: SIMD2<Float>?) {
        lookTarget = point ?? .zero
        body.bias = (point?.x ?? 0) * 0.03
        fingerRoll = -(point?.x ?? 0) * 0.06
    }

    func lean(_ tilt: SIMD2<Float>) { leanPivot.orientation = simd_quatf(angle: -max(-0.35, min(0.35, tilt.x * 0.5)), axis: [0, 0, 1]) }

    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        self.mood = mood
        body.energy = mood
        brightness = (0.6 + mood * 0.4) * (timeOfDay == .night ? 0.75 : 1)
        for t in tongues {
            guard var comp = t.model, var m = comp.materials.first as? CustomMaterial else { continue }
            m.custom.value.z = brightness; comp.materials = [m]; t.model = comp
        }
        if timeOfDay == .night && mood < 0.3 { eyesHeldClosed = true; body.resting = true; setEyes("closed"); setMouth("flat") }
        else if eyesHeldClosed && body.resting { eyesHeldClosed = false; body.resting = false; setEyes("open"); setMouth("smile") }
    }

    func mouth(_ open: Float) { setMouth(open > 0.7 ? "joy" : open > 0.4 ? "talk" : open > 0.15 ? "o" : "smile") }

    // MARK: Helpers

    private func setEyes(_ mode: String) {
        eyeMode = mode
        let names: [String] = switch mode {
        case "closed": ["eye-closed-L", "eye-closed-R"]
        case "up": ["eye-up", "eye-up"]
        case "down": ["eye-down", "eye-down"]
        default: ["eye-open-L", "eye-open-R"]
        }
        for (e, n) in zip(eyes, names) { setTexture(e, n) }
    }

    private func setMouth(_ shape: String) { if let mouthLayer { setTexture(mouthLayer, "mouth-\(shape)") } }

    private func setTexture(_ e: ModelEntity, _ name: String) {
        guard let t = textures[name], var comp = e.model, var m = comp.materials.first as? UnlitMaterial else { return }
        m.color = .init(tint: .white, texture: PaintedRig.clamped(t))
        comp.materials = [m]; e.model = comp
    }

    private func glance(_ to: SIMD2<Float>, roll: Float, hold: Double) {
        lookTarget = to; behaviorRoll = roll
        after(hold) { self.lookTarget = .zero; self.behaviorRoll = 0 }
    }

    private func brow(_ lift: Float, for s: Double) { browTarget = lift; after(s) { self.browTarget = 0 } }

    private func smile(_ s: Double) {
        guard !eyesHeldClosed else { return }
        setEyes("closed")       // the closed-eye arcs read as a happy squint together with the smile
        after(s) { if !self.eyesHeldClosed { self.setEyes("open") } }
    }

    private func closeEyes(for s: Double) {
        eyesHeldClosed = true; setEyes("closed")
        after(s) { self.eyesHeldClosed = false; self.setEyes("open") }
    }

    private func talk(for s: Float) { talkUntil = clock + s; after(Double(s) + 0.05) { self.setMouth("smile") } }

    private func after(_ s: Double, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in try? await Task.sleep(for: .seconds(s)); work() }
    }
}
