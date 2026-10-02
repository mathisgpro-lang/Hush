// S2 · The Sanctuary, painted route (P2 plan §B.4, fallback step 2 built side by side with full 3D).
// Codex's painting is bent in depth (water near, steps middle, sky far) so moving the phone gives real parallax;
// its water ripples and sparkles, waterfalls flow, mist drifts with Vitality (R1), fireflies float, and the living
// Flame stands on the steps. Today's calls float on top as SwiftUI.
import SwiftUI
import RealityKit
import Metal

@MainActor
final class SanctuaryScene {
    let root = Entity()
    let camera = PerspectiveCamera()
    private var painting: ModelEntity?
    private var vitality: Float = 1
    private var paintingW: Float = 1, paintingH: Float = 1
    private let heroScale: Float = 0.62     // small and cute on the circle, like the First Words frame
    /// The stone circle's center in the painting (uv, v up): the Flame's stage.
    private let circle = SIMD2<Float>(0.540, 0.4648)  // exactly where the Flame sits in the root frame, on its own painted glow
    private var mists: [ModelEntity] = []
    let hero = HeroRig(base: "d", footInset: 22.0 / 426.0, reflection: false, glows: false, wander: 0.004)   // the root frame's own Flame, on its own pixels
    let life = SanctuaryLife()
    private var flies: Entity?
    private var heroFeet = SIMD3<Float>(0, 0, 0)
    private var heroWorldScale: Float = 0.55
    private var time: Float = 0
    private let noise = SmoothNoise(seed: 21)
    var tilt = SIMD2<Float>(0, 0)
    var autoDrift = true
    var updates: EventSubscription?
    var fingerDown = false
    /// The hour shown (0–24). Follows the real clock unless a test overrides it.
    var hourOverride: Float?
    /// The intro hatches the Flame: 0 = not there yet, 1 = present (springs in with an overshoot).
    var flameTarget: Float = 1
    private var appear = Spring(1, stiffness: 90, damping: 9)
    /// Camera focus for exploring spots: nil = the home view.
    var focus: SIMD3<Float>?
    private var camPos = SIMD3<Float>(0, 0, 0), camLook = SIMD3<Float>(0, 0, -1.2)
    private var watching = false

    static let distance: Float = 1.2
    static let fov: Float = 40

    /// Depth from Apple's Depth Anything V2 (tools/depthmap), white = near. Read once into memory.
    private var depth: (w: Int, h: Int, px: [UInt8])?
    private func loadDepth(_ name: String) {
        guard let img = UIImage(named: name)?.cgImage else { return }
        let (w, h) = (img.width, img.height)
        var px = [UInt8](repeating: 0, count: w * h)
        let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        depth = (w, h, px)
    }
    /// Depth 0…1 at painting uv (v = 0 at the bottom), averaged over a small area to keep the relief smooth.
    private func depthAt(_ u: Float, _ v: Float) -> Float {
        guard let d = depth else { return 0.3 }
        let cx = Int(u * Float(d.w - 1)), cy = Int((1 - v) * Float(d.h - 1))
        var sum = 0, n = 0
        for dy in -2...2 { for dx in -2...2 {
            let x = max(0, min(d.w - 1, cx + dx)), y = max(0, min(d.h - 1, cy + dy))
            sum += Int(d.px[y * d.w + x]); n += 1
        } }
        return Float(sum) / Float(n * 255)
    }
    /// How much nearer than the base plane a point sits, from its depth (lifted mid-tones so the arches separate).
    private func relief(_ g: Float) -> Float { 0.45 * pow(g, 0.6) - 0.15 }

    func build() async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let tex = try await TextureResource(named: "home-paint.png")
        let motion = try await TextureResource(named: "home-motion.png", options: .init(semantic: .raw))
        loadDepth("home-depth.png")
        let visibleH = 2 * Self.distance * tan(Self.fov / 2 * .pi / 180)
        let aspect = Float(tex.width) / Float(tex.height)
        let (w, h) = (visibleH * aspect * 1.08, visibleH * 1.08)     // a little overscan so parallax never shows edges
        paintingW = w; paintingH = h

        // The painting, bent in depth. Each vertex keeps its rest screen position (scaled along the camera ray),
        // so from the rest camera the painting looks untouched; moving the camera reveals the depth.
        let (nx, ny) = (72, 156)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            let rest = SIMD3<Float>((u - 0.5) * w, (v - 0.5) * h, -Self.distance)
            let d = Self.distance - (depth == nil ? Self.depthOffset(v) : relief(depthAt(u, v)))
            pos.append(rest * (d / Self.distance)); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: "sanctuary")
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: .init(tex))
        var material: any RealityKit.Material = unlit
        if let lib {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "stoneLive", in: lib))
            m.custom.texture = .init(motion)
            m.custom.value = [1, 0.5, 0.5, 0]
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        // Mist cards at three depths, all just behind the Flame (it must stay the warmest, clearest thing on screen),
        // driven by Vitality. The near-water mist lives in the painting's shader.
        if let lib {
            for (k, spec) in [(z: -1.32, y: -0.02, w: 1.0, speed: 0.012), (z: -1.36, y: 0.1, w: 1.2, speed: 0.008), (z: -1.42, y: 0.2, w: 1.4, speed: 0.005)].enumerated() {
                var u = UnlitMaterial(); u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false
                var m = try CustomMaterial(from: u, surfaceShader: .init(named: "mistDrift", in: lib))
                m.custom.value = [0, Float(spec.speed), Float(k) * 13.7, 0]
                m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
                let e = ModelEntity(mesh: .generatePlane(width: Float(spec.w), height: Float(spec.w) * 0.45), materials: [m])
                e.position = [0, Float(spec.y), Float(spec.z)]
                root.addChild(e); mists.append(e)
            }
        }

        // Fireflies drifting over the water and the steps.
        let flies = Entity()
        var f = ParticleEmitterComponent()
        f.emitterShape = .box; f.emitterShapeSize = [0.5, 0.25, 0.3]
        f.emissionDirection = [0, 1, 0]; f.speed = 0.01; f.speedVariation = 0.008
        f.mainEmitter.birthRate = 6; f.mainEmitter.lifeSpan = 5; f.mainEmitter.lifeSpanVariation = 2
        f.mainEmitter.size = 0.004; f.mainEmitter.blendMode = .additive
        f.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 1)))
        flies.components.set(f); flies.position = [0, 0.0, -0.95]
        root.addChild(flies); self.flies = flies

        // The Flame on the steps (v ≈ 0.33 in the painting), scaled to the scene.
        try await hero.build()
        // Center stage: its feet on the middle of the stone circle, at the circle's own depth.
        let d = Self.distance - relief(depthAt(circle.x, circle.y)) - 0.01
        let k = d / Self.distance
        // Exactly as in the root frame: the cutout is 426 of the painting's 1846 px tall (its mesh is 0.27 tall).
        let scale = 0.92 * (426.0 / 1846.0) * h * k / 0.27      // its painted size, a touch smaller (Mathis); the painted glow stays
        let feet = SIMD3<Float>((circle.x - 0.5) * w * k, (circle.y - 0.5) * h * k, -d)
        hero.leanPivot.scale = .init(repeating: scale)
        hero.leanPivot.position = feet + SIMD3(0, 0.09 * scale, 0)
        hero.stationary = true
        root.addChild(hero.leanPivot)
        heroFeet = feet; heroWorldScale = scale

        try await life.build()
        root.addChild(life.root)

        // Soft glowing motes drifting close to the camera, in front of the whole world (depth and air).
        let motes = Entity()
        var mp = ParticleEmitterComponent()
        mp.emitterShape = .box; mp.emitterShapeSize = [0.5, 0.9, 0.25]
        mp.emissionDirection = [0.3, 1, 0]; mp.speed = 0.012; mp.speedVariation = 0.008
        mp.mainEmitter.birthRate = 5; mp.mainEmitter.lifeSpan = 7; mp.mainEmitter.lifeSpanVariation = 2
        mp.mainEmitter.size = 0.012; mp.mainEmitter.sizeVariation = 0.008; mp.mainEmitter.blendMode = .additive
        mp.mainEmitter.color = .evolving(start: .single(UIColor(red: 1, green: 0.85, blue: 0.6, alpha: 0.9)), end: .single(UIColor(red: 1, green: 0.7, blue: 0.4, alpha: 0.6)))
        mp.mainEmitter.opacityCurve = .gradualFadeInOut
        motes.components.set(mp); motes.position = [0, -0.05, -0.55]
        root.addChild(motes)

        camera.camera.fieldOfViewInDegrees = Self.fov
        root.addChild(camera)
    }

    /// How much nearer than the base plane each row of the painting sits: the water is near, the steps a bit
    /// nearer than the arches, the waterfalls and cliffs behind, and the sky far away.
    static func depthOffset(_ v: Float) -> Float {
        if v < 0.32 { return 0.38 * (0.32 - v) / 0.32 + 0.02 }       // water, nearest at the bottom
        if v < 0.40 { return 0.02 - (v - 0.32) * 0.5 }               // the steps
        if v < 0.62 { return -0.02 - (v - 0.40) * 0.6 }              // arches and waterfalls
        return -0.15 - (v - 0.62) * 0.8                              // sky
    }

    /// A point on the painting's relief, from its uv (v up): used to focus the camera on a spot.
    func spot(_ u: Float, _ v: Float) -> SIMD3<Float> {
        let rest = SIMD3<Float>((u - 0.5) * paintingW, (v - 0.5) * paintingH, -Self.distance)
        let d = Self.distance - relief(depthAt(u, v))
        return rest * (d / Self.distance)
    }

    /// For the intro: the Flame isn't born yet.
    func hideFlameInstantly() { appear = Spring(0, stiffness: 90, damping: 9); flameTarget = 0 }
    /// Where the Flame's chest is, to focus the camera on it.
    var flameFocus: SIMD3<Float> { heroFeet + SIMD3(0, 0.12 * heroWorldScale, 0) }

    func setVitality(_ v: Float) {
        vitality = v
        for (k, e) in mists.enumerated() {
            guard var comp = e.model, var m = comp.materials.first as? CustomMaterial else { continue }
            m.custom.value.x = 0.14 + (1 - v) * (k == 0 ? 0.45 : 0.6)   // mist always drifts far behind; never in front of the Flame
            comp.materials = [m]; e.model = comp
        }

    }

    func update(dt: Float) {
        time += dt
        // The Flame's birth: it springs into being (with a little overshoot) when flameTarget becomes 1.
        appear.step(toward: flameTarget, dt: dt)
        hero.leanPivot.scale = .init(repeating: heroWorldScale * max(0, appear.value))
        hero.leanPivot.isEnabled = appear.value > 0.01 || flameTarget > 0
        // Life and wind first, so the Flame can react to them this frame.
        let chest = heroFeet + SIMD3(hero.standingX * heroWorldScale, 0.10 * heroWorldScale, 0.005)
        let watch = life.update(dt: dt, flameAt: chest)
        hero.wind = life.wind
        if !fingerDown {
            if let watch { hero.look(at: watch); watching = true }
            else if watching { hero.look(at: nil); watching = false }   // reset once when the moth leaves
        }
        hero.update(dt: dt)
        if let flies, var f = flies.components[ParticleEmitterComponent.self] {
            f.mainEmitter.acceleration = [life.wind * 0.02, 0, 0]
            flies.components.set(f)
        }
        // The Flame's light on the painting follows it and flickers with the fire (A1); dimmer in the Hush.
        if let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            let u = circle.x + hero.standingX * heroWorldScale / paintingW
            let flicker = 0.85 + 0.15 * noise.sample(time * 7) + 0.05 * sin(time * 23)
            m.custom.value = [vitality, u - 0.03, circle.y + 0.01, (flicker - 0.9) * 1.4 * max(0, min(1, appear.value))]   // the painted glow breathes with the Flame's fire (±)
            m.roughness = .init(floatLiteral: abs(life.wind))       // the shader reads wind from roughness_scale
            let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let args = CommandLine.arguments
            if args.contains("-hourcycle") { hourOverride = (6 + time * 0.8).truncatingRemainder(dividingBy: 24) }
            else if let i = args.firstIndex(of: "-hour"), i + 1 < args.count, let h = Float(args[i + 1]) { hourOverride = h }
            let hour = hourOverride ?? (Float(comps.hour ?? 18) + Float(comps.minute ?? 0) / 60)
            m.metallic = .init(floatLiteral: hour / 24)              // and the time of day from metallic_scale
            comp.materials = [m]; painting.model = comp
        }
        // The camera breathes very slowly (an alive world), and follows the phone's tilt for parallax.
        let drift = autoDrift ? SIMD2(noise.sample(time * 0.08), noise.sample(time * 0.06 + 30)) * 0.12 : SIMD2(noise.sample(time * 0.08), noise.sample(time * 0.06 + 30)) * 0.04
        let offset = SIMD3<Float>(tilt.x * 0.11 + drift.x, -tilt.y * 0.07 + drift.y * 0.6, sin(time * 0.11) * 0.05)
        let (wantPos, wantLook): (SIMD3<Float>, SIMD3<Float>) = focus.map { f0 in
            // Glide toward the spot but keep the view inside the painting (side spots would show its edge).
            let f = SIMD3<Float>(max(-0.09, min(0.09, f0.x)), f0.y, f0.z)
            return (f * 0.42 + offset * 0.3, f) }
            ?? (offset, [offset.x * 0.3, offset.y * 0.3, -Self.distance])
        let k = 1 - exp(-dt * 3.2)
        camPos += (wantPos - camPos) * k; camLook += (wantLook - camLook) * k
        camera.look(at: camLook, from: camPos, relativeTo: nil)
    }
}

struct S2View: View {
    @State private var meter = FrameMeter()
    @State private var scene = SanctuaryScene()
    @State private var director: AliveDirector?
    @State private var tilt = TiltSource()
    @State private var vitality: Double = CommandLine.arguments.contains("-hushed") ? 0.15 : 1
    @State private var done: Set<String> = []
    @State private var showPanel = !CommandLine.arguments.contains("-nocontrols")

    private let calls: [(id: String, text: String, pillar: Pillar, color: Color)] = [
        ("walk", "Walk 20 minutes", .body, Color(red: 1.0, green: 0.55, blue: 0.2)),
        ("call", "Call someone you love", .heart, Color(red: 0.95, green: 0.55, blue: 0.6)),
        ("read", "Read 10 pages", .mind, Color(red: 0.5, green: 0.7, blue: 1.0)),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RealityView { content in
                content.camera = .virtual
                do { try await scene.build() } catch { return }
                content.add(scene.root)
                scene.setVitality(Float(vitality))
                let d = AliveDirector(seed: 7, meter: meter)
                d.attach(scene.hero, tempo: 0.55)
                director = d
                scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
            }
            .ignoresSafeArea()
            .onTapGesture { director?.tapped() }

            VStack(spacing: 10) {
                HUDView(meter: meter)
                Spacer()
                // Today's calls, floating near the hearth.
                VStack(spacing: 8) {
                    ForEach(calls, id: \.id) { call in
                        if !done.contains(call.id) {
                            Button {
                                withAnimation(.spring(duration: 0.5)) { _ = done.insert(call.id) }
                                director?.actionCompleted(call.pillar)
                            } label: {
                                HStack(spacing: 8) {
                                    Circle().fill(call.color).frame(width: 8, height: 8).shadow(color: call.color, radius: 6)
                                    Text(call.text).font(.system(size: 15, weight: .medium, design: .serif))
                                }
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(.black.opacity(0.45), in: Capsule())
                                .overlay(Capsule().stroke(call.color.opacity(0.7), lineWidth: 1))
                                .foregroundStyle(.white)
                            }
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                }
                if showPanel {
                    HStack {
                        Text("Vitality").font(.caption)
                        Slider(value: $vitality, in: 0...1).onChange(of: vitality) { _, v in scene.setVitality(Float(v)) }
                    }
                    .padding(10).background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("S2 · The Sanctuary (painted)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            meter.start()
            tilt.start { t in scene.tilt = t; scene.autoDrift = false }
        }
        .onDisappear { meter.stop(); tilt.stop(); director?.stop() }
    }
}
