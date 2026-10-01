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
    private let heroScale: Float = 0.55
    private var mists: [ModelEntity] = []
    let hero = HeroRig()
    private var time: Float = 0
    private let noise = SmoothNoise(seed: 21)
    var tilt = SIMD2<Float>(0, 0)
    var autoDrift = true
    var updates: EventSubscription?

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
        let tex = try await TextureResource(named: "sanctuary-paint.png")
        loadDepth("sanctuary-depth.png")
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
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "sanctuaryLive", in: lib))
            m.custom.value = [1, 0, 0, 0]
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        // Mist cards at three depths, all just behind the Flame (it must stay the warmest, clearest thing on screen),
        // driven by Vitality. The near-water mist lives in the painting's shader.
        if let lib {
            for (k, spec) in [(z: -1.19, y: -0.08, w: 0.9, speed: 0.012), (z: -1.24, y: 0.02, w: 1.1, speed: 0.008), (z: -1.3, y: 0.1, w: 1.3, speed: 0.005)].enumerated() {
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
        flies.components.set(f); flies.position = [0, -0.18, -0.95]
        root.addChild(flies)

        // The Flame on the steps (v ≈ 0.33 in the painting), scaled to the scene.
        try await hero.build()
        // Its feet sit exactly at the depth of the step it stands on (the painting is bent in depth), so the
        // rows above it fall behind it and the rows below it stay below its feet.
        let stepV: Float = 0.285
        let stepDepth = depth == nil ? Self.depthOffset(stepV) : relief(depthAt(0.5, stepV + 0.01))
        let d = Self.distance - stepDepth - 0.01                         // a hair in front of the step
        let k = d / Self.distance                                      // keep its screen position and size
        let scale = heroScale * k
        let stepsY = (stepV - 0.5) * h * k
        hero.leanPivot.scale = .init(repeating: scale)
        hero.leanPivot.position = [0, stepsY + 0.09 * scale, -d]
        root.addChild(hero.leanPivot)

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

    func setVitality(_ v: Float) {
        vitality = v
        for (k, e) in mists.enumerated() {
            guard var comp = e.model, var m = comp.materials.first as? CustomMaterial else { continue }
            m.custom.value.x = (1 - v) * (k == 0 ? 0.55 : 0.75)
            comp.materials = [m]; e.model = comp
        }
    }

    func update(dt: Float) {
        time += dt
        hero.update(dt: dt)
        // The Flame's light on the painting follows it and flickers with the fire (A1); dimmer in the Hush.
        if let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            let u = 0.5 + hero.standingX * heroScale / paintingW
            let flicker = 0.85 + 0.15 * noise.sample(time * 7) + 0.05 * sin(time * 23)
            m.custom.value = [vitality, u, 0.30, 0.9 * flicker * (0.5 + 0.5 * vitality)]
            comp.materials = [m]; painting.model = comp
        }
        // The camera breathes very slowly (an alive world), and follows the phone's tilt for parallax.
        let drift = autoDrift ? SIMD2(noise.sample(time * 0.09), noise.sample(time * 0.07 + 30)) * 0.06 : .zero
        let offset = SIMD3<Float>(tilt.x * 0.06 + drift.x, -tilt.y * 0.04 + drift.y * 0.6, 0)
        camera.look(at: [offset.x * 0.3, offset.y * 0.3, -Self.distance], from: offset, relativeTo: nil)
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
