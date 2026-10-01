// Route C, the painted rig (P2 plan §B.6b): the Flame is Codex's painting cut into layers, animated live.
// Layers are textured planes: body (breathing), five flame tongues (swaying), eyes and mouth (texture swaps),
// a soft glow behind the core, and embers. Looking around shifts layers by depth for a small 3D-like turn.
import RealityKit
import UIKit
import Metal

/// Where each layer sits, in meters (the whole Flame is about 0.30 m tall). One layout per art set.
struct PaintedLayout {
    struct Plane { var file: String; var size: SIMD2<Float>; var bottomCenter: SIMD3<Float> }
    var body: Plane
    var tongues: [Plane]
    var eyeLeft: Plane, eyeRight: Plane
    var eyeOpen: String, eyeClosed: String
    var mouth: Plane
    var mouths: [String: String]       // smile, joy, o, flat, talk → file
    var glow: Plane?

    static let placeholder = PaintedLayout(
        body: .init(file: "body.png", size: [0.28, 0.28], bottomCenter: [0, -0.14, 0]),
        tongues: [(-0.07, 0.025, 0.55), (-0.036, 0.04, 0.75), (0, 0.045, 1.0), (0.036, 0.04, 0.75), (0.07, 0.025, 0.55)]
            .enumerated().map { i, t in .init(file: "tongue-\(i).png", size: [0.07, 0.14], bottomCenter: [Float(t.0), Float(t.1), -0.004]) },
        eyeLeft: .init(file: "eye-open.png", size: [0.042, 0.049], bottomCenter: [-0.04, -0.03, 0.004]),
        eyeRight: .init(file: "eye-open.png", size: [0.042, 0.049], bottomCenter: [0.04, -0.03, 0.004]),
        eyeOpen: "eye-open.png", eyeClosed: "eye-closed.png",
        mouth: .init(file: "mouth-smile.png", size: [0.05, 0.0375], bottomCenter: [0, -0.075, 0.004]),
        mouths: ["smile": "mouth-smile.png", "joy": "mouth-joy.png", "o": "mouth-o.png", "flat": "mouth-flat.png", "talk": "mouth-talk.png"],
        glow: nil)
}

@MainActor
final class PaintedRig: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()
    private let layout: PaintedLayout
    private var textures: [String: TextureResource] = [:]
    private var body: ModelEntity?
    private var tongues: [ModelEntity] = []
    private var eyes: [ModelEntity] = []
    private var mouth: ModelEntity?
    private var eyesHeldClosed = false
    private var lookYaw: Float = 0, lookPitch: Float = 0
    private var idleYaw: Float = 0, idlePitch: Float = 0
    var log: [String] = []

    init(layout: PaintedLayout) {
        self.layout = layout
        leanPivot.addChild(lookPivot)
    }

    func build() async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        func tex(_ f: String) async throws -> TextureResource {
            if let t = textures[f] { return t }
            let t = try await TextureResource(named: f)
            textures[f] = t
            return t
        }
        for f in [layout.eyeOpen, layout.eyeClosed] + layout.mouths.values { _ = try await tex(f) }

        // Tongues, each with its own phase so they never move in unison.
        for (i, t) in layout.tongues.enumerated() {
            let amp: Float = i == 2 ? 0.012 : 0.008
            let e = try await plane(t, texture: tex(t.file), modifier: lib.map { .init(named: "tongueSway", in: $0) },
                                    custom: [Float(i) * 1.37, amp, 0, 0], subdivisions: [4, 12])
            lookPivot.addChild(e); tongues.append(e)
        }
        // Body, breathing (in front of the tongues, so their bases hide behind the head).
        let b = try await plane(layout.body, texture: tex(layout.body.file), modifier: lib.map { .init(named: "breathe", in: $0) },
                                custom: [1, 0.018, 0, 0], subdivisions: [6, 6])
        lookPivot.addChild(b); body = b
        // Eyes and mouth: plain unlit layers whose textures swap.
        for p in [layout.eyeLeft, layout.eyeRight] {
            let e = try await plane(p, texture: tex(layout.eyeOpen), modifier: nil, custom: .zero, subdivisions: [1, 1])
            lookPivot.addChild(e); eyes.append(e)
        }
        let m = try await plane(layout.mouth, texture: tex(layout.mouths["smile"]!), modifier: nil, custom: .zero, subdivisions: [1, 1])
        lookPivot.addChild(m); mouth = m

        // Embers rising from the Flame.
        let embers = Entity()
        var p = ParticleEmitterComponent()
        p.emitterShape = .sphere
        p.emitterShapeSize = [0.09, 0.06, 0.02]
        p.emissionDirection = [0, 1, 0]
        p.speed = 0.035
        p.mainEmitter.birthRate = 9
        p.mainEmitter.lifeSpan = 2.2
        p.mainEmitter.size = 0.0035
        p.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.7, blue: 0.3, alpha: 1)))
        p.mainEmitter.blendMode = .additive
        embers.components.set(p)
        embers.position = [0, 0.02, 0.01]
        lookPivot.addChild(embers)
        log.append("painted rig: \(tongues.count) tongues, shaders \(lib == nil ? "missing" : "on")")
    }

    /// A subdivided plane with its pivot at the bottom center (uv.y = 0 at the bottom).
    /// Painted layers are drawn strictly in this order (back to front), never by depth, so overlaps can't fight.
    private let sortGroup = ModelSortGroup(depthPass: nil)
    private var nextOrder: Int32 = 0

    private func plane(_ spec: PaintedLayout.Plane, texture: TextureResource, modifier: CustomMaterial.GeometryModifier?,
                       custom: SIMD4<Float>, subdivisions: SIMD2<Int>) async throws -> ModelEntity {
        let (w, h) = (spec.size.x, spec.size.y)
        let (nx, ny) = (subdivisions.x, subdivisions.y)
        var positions: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], indices: [UInt32] = []
        for j in 0...ny {
            for i in 0...nx {
                let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
                positions.append([(u - 0.5) * w, v * h, 0])
                uvs.append([u, v])
            }
        }
        for j in 0..<ny {
            for i in 0..<nx {
                let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
                indices += [a, b, d, a, d, c]
            }
        }
        var desc = MeshDescriptor(name: spec.file)
        desc.positions = MeshBuffers.Positions(positions)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)
        let mesh = try MeshResource.generate(from: [desc])

        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: Self.clamped(texture))
        unlit.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        unlit.faceCulling = .none
        unlit.writesDepth = false
        let material: any Material
        if let modifier {
            var custom2 = try CustomMaterial(from: unlit, geometryModifier: modifier)
            custom2.custom.value = custom
            custom2.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            custom2.faceCulling = .none
            custom2.writesDepth = false
            material = custom2
        } else {
            material = unlit
        }
        let e = ModelEntity(mesh: mesh, materials: [material])
        e.position = spec.bottomCenter
        e.components.set(ModelSortGroupComponent(group: sortGroup, order: nextOrder))
        nextOrder += 1
        return e
    }

    // MARK: FlameRig

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: glance(yaw: 0.5, pitch: 0, hold: 1.4)
        case .glanceRight: glance(yaw: -0.5, pitch: 0, hold: 1.4)
        case .glanceUp: glance(yaw: 0, pitch: 0.4, hold: 1.2)
        case .lookAtYou: glance(yaw: 0, pitch: -0.05, hold: 1.8); setMouth("smile")
        case .watchEmber:
            glance(yaw: 0.2, pitch: 0.4, hold: 0.8)
            after(0.9) { self.glance(yaw: -0.15, pitch: 0.6, hold: 1.0) }
        case .stretch: hop(height: 0.012, up: 0.5, down: 0.6); setMouth("o"); after(1.1) { self.setMouth("smile") }
        case .smallHop: hop(height: 0.018, up: 0.18, down: 0.25)
        case .yawn: closeEyes(for: 1.3); setMouth("o"); after(1.3) { self.setMouth("smile") }
        case .doze: closeEyes(for: 3.5); setMouth("flat"); after(3.5) { self.setMouth("smile") }
        case .hum:
            for k in 0..<6 { after(Double(k) * 0.18) { self.setMouth(k.isMultiple(of: 2) ? "o" : "smile") } }
        case .sway, .dance: rock(angle: 0.07)
        case .wander: hop(height: 0.012, up: 0.2, down: 0.25)
        }
    }

    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle:
            setEyesTexture(layout.eyeClosed); setMouth("joy")        // visible on the very next frame
            hop(height: 0.012, up: 0.12, down: 0.2)
            after(0.5) { self.openEyesIfAwake(); self.setMouth("smile") }
        case .leanIn:
            scale(lookPivot, 1.06, duration: 0.25)
            after(0.7) { self.scale(self.lookPivot, 1, duration: 0.35) }
        case .cheer:
            setMouth("joy"); hop(height: 0.03, up: 0.2, down: 0.3)
            after(0.6) { self.setMouth("smile") }
        case .pillar(let p):
            switch p {
            case .body: hop(height: 0.02, up: 0.15, down: 0.2)
            case .mind: glance(yaw: 0, pitch: 0, roll: 0.2, hold: 1.0)
            case .heart: closeEyes(for: 0.9); scale(lookPivot, 1.04, duration: 0.3); after(0.4) { self.scale(self.lookPivot, 1, duration: 0.4) }
            case .spirit: hop(height: 0.02, up: 0.8, down: 0.8)
            case .craft: glance(yaw: 0, pitch: -0.3, hold: 0.3)
            case .world: rock(angle: 0.12)
            }
        }
    }

    func blink() {
        guard !eyesHeldClosed else { return }
        setEyesTexture(layout.eyeClosed)
        after(0.13) { self.openEyesIfAwake() }
    }

    func look(at point: SIMD2<Float>?) {
        lookYaw = (point?.x ?? 0) * 0.5
        lookPitch = (point?.y ?? 0) * 0.4
        applyParallax(duration: 0.12)
    }

    func lean(_ tilt: SIMD2<Float>) {
        let roll = max(-0.35, min(0.35, tilt.x * 0.5))
        leanPivot.orientation = simd_quatf(angle: -roll, axis: [0, 0, 1])
    }

    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        let night: Float = timeOfDay == .night ? 0.75 : 1
        let brightness = CGFloat((0.55 + mood * 0.45) * night)
        let tint: UIColor = switch season {
        case .thaw: UIColor(red: brightness, green: brightness * 0.97, blue: brightness * 0.95, alpha: 1)
        case .longLight: UIColor(white: brightness, alpha: 1)
        case .harvest: UIColor(red: brightness, green: brightness * 0.9, blue: brightness * 0.8, alpha: 1)
        case .embernight: UIColor(red: brightness, green: brightness * 0.85, blue: brightness * 0.85, alpha: 1)
        }
        for e in [body].compactMap({ $0 }) + tongues { retint(e, tint) }
        if timeOfDay == .night && mood < 0.3 { eyesHeldClosed = true; setEyesTexture(layout.eyeClosed); setMouth("flat") }
        else if eyesHeldClosed { eyesHeldClosed = false; setEyesTexture(layout.eyeOpen); setMouth("smile") }
    }

    func mouth(_ open: Float) {
        setMouth(open > 0.6 ? "joy" : open > 0.25 ? "talk" : open > 0.08 ? "o" : "smile")
    }

    // MARK: Helpers

    /// Depth parallax: the face moves most, the tongues a little, the body barely, so a glance reads as a small turn.
    private func applyParallax(duration: Double, roll: Float = 0) {
        let yaw = lookYaw + idleYaw, pitch = lookPitch + idlePitch
        func shift(_ e: Entity, base: SIMD3<Float>, depth: Float) {
            var t = e.transform
            t.translation = base + SIMD3(yaw * 0.03 * depth, pitch * 0.02 * depth, 0)
            e.move(to: t, relativeTo: lookPivot, duration: duration, timingFunction: .easeInOut)
        }
        if let body { shift(body, base: layout.body.bottomCenter, depth: 0.15) }
        for (i, e) in tongues.enumerated() { shift(e, base: layout.tongues[i].bottomCenter, depth: 0.45) }
        for (i, e) in eyes.enumerated() { shift(e, base: i == 0 ? layout.eyeLeft.bottomCenter : layout.eyeRight.bottomCenter, depth: 1) }
        if let mouth { shift(mouth, base: layout.mouth.bottomCenter, depth: 0.9) }
        var t = lookPivot.transform
        t.rotation = simd_quatf(angle: roll, axis: [0, 0, 1])
        lookPivot.move(to: t, relativeTo: leanPivot, duration: duration, timingFunction: .easeInOut)
    }

    private func glance(yaw: Float, pitch: Float, roll: Float = 0, hold: Double) {
        idleYaw = yaw; idlePitch = pitch
        applyParallax(duration: 0.35, roll: roll)
        after(hold) { self.idleYaw = 0; self.idlePitch = 0; self.applyParallax(duration: 0.5) }
    }

    private func hop(height: Float, up: Double, down: Double) {
        var t = lookPivot.transform
        t.translation.y = height
        lookPivot.move(to: t, relativeTo: leanPivot, duration: up, timingFunction: .easeOut)
        after(up) {
            var t2 = self.lookPivot.transform
            t2.translation.y = 0
            self.lookPivot.move(to: t2, relativeTo: self.leanPivot, duration: down, timingFunction: .easeIn)
        }
    }

    private func rock(angle: Float) {
        for i in 0..<4 { after(Double(i) * 0.45) { self.glance(yaw: 0, pitch: 0, roll: i.isMultiple(of: 2) ? angle : -angle, hold: 0.4) } }
    }

    private func scale(_ e: Entity, _ s: Float, duration: Double) {
        var t = e.transform
        t.scale = .init(repeating: s)
        e.move(to: t, relativeTo: e.parent, duration: duration, timingFunction: .easeInOut)
    }

    private func closeEyes(for seconds: Double) {
        eyesHeldClosed = true
        setEyesTexture(layout.eyeClosed)
        after(seconds) { self.eyesHeldClosed = false; self.openEyesIfAwake() }
    }

    private func openEyesIfAwake() { if !eyesHeldClosed { setEyesTexture(layout.eyeOpen) } }

    private func setEyesTexture(_ file: String) {
        guard let t = textures[file] else { return }
        for e in eyes { setTexture(e, t) }
    }

    private func setMouth(_ shape: String) {
        guard let mouth, let f = layout.mouths[shape], let t = textures[f] else { return }
        setTexture(mouth, t)
    }

    /// Clamp at the edges: with the default repeat, a layer's bottom row bleeds into its top edge as a thin line.
    static func clamped(_ t: TextureResource) -> MaterialParameters.Texture {
        let d = MTLSamplerDescriptor()
        d.sAddressMode = .clampToEdge
        d.tAddressMode = .clampToEdge
        d.minFilter = .linear; d.magFilter = .linear; d.mipFilter = .linear
        return MaterialParameters.Texture(t, sampler: .init(d))
    }

    private func setTexture(_ e: ModelEntity, _ t: TextureResource) {
        guard var comp = e.model, var m = comp.materials.first as? UnlitMaterial else { return }
        m.color = .init(tint: m.color.tint, texture: Self.clamped(t))
        comp.materials = [m]
        e.model = comp
    }

    private func retint(_ e: ModelEntity, _ tint: UIColor) {
        guard var comp = e.model else { return }
        if var m = comp.materials.first as? CustomMaterial {
            m.baseColor = .init(tint: tint, texture: m.baseColor.texture)
            comp.materials = [m]
        } else if var m = comp.materials.first as? UnlitMaterial {
            m.color = .init(tint: tint, texture: m.color.texture)
            comp.materials = [m]
        }
        e.model = comp
    }

    private func after(_ seconds: Double, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            work()
        }
    }
}
