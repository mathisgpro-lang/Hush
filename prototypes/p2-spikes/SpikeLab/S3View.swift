// S3 · Restoration, painted route (P2 plan §B.4; Plan 2.0 Part 1 §8; R1, R2).
// The Whispering Grove from Codex's painting, as a depth relief. The Heart pillar's Depth drives restoration:
// level 0 Hushed (grey, mist, every lantern dark) → 5 Radiant. The 474 lights relight in order, outward from the
// stone circle; color, moving water and fireflies return. A real action sends a strand of light from the Flame
// to the next lanterns ("every real thing becomes light; the Flame carries it into the world").
import SwiftUI
import RealityKit
import Metal

enum Restoration {
    static let thresholds: [Float] = [0, 3, 15, 50, 150, 400]
    static let names = ["Hushed", "First light", "Waking", "Alive", "Flourishing", "Radiant"]

    /// Continuous restoration 0…1 from Depth: five equal steps, linear inside each level.
    static func amount(depth: Float) -> Float {
        if depth >= 400 { return 1 }
        for l in 0..<5 where depth < thresholds[l + 1] {
            let frac = (depth - thresholds[l]) / (thresholds[l + 1] - thresholds[l])
            return (Float(l) + frac) / 5
        }
        return 1
    }
    static func depth(amount r: Float) -> Float {
        let x = max(0, min(1, r)) * 5
        let l = min(4, Int(x))
        return thresholds[l] + (x - Float(l)) * (thresholds[l + 1] - thresholds[l])
    }
    static func level(depth: Float) -> Int { thresholds.lastIndex { depth >= $0 } ?? 0 }
}

@MainActor @Observable
final class GroveScene {
    @ObservationIgnored let root = Entity()
    @ObservationIgnored let camera = PerspectiveCamera()
    @ObservationIgnored let hero = LayeredFlame()
    @ObservationIgnored let life = SanctuaryLife()
    @ObservationIgnored private var painting: ModelEntity?
    @ObservationIgnored private var flies: Entity?
    @ObservationIgnored private var strand: ModelEntity?
    @ObservationIgnored private var lanterns: [(pos: SIMD3<Float>, order: Float)] = []
    @ObservationIgnored private var depthMap: (w: Int, h: Int, px: [UInt8])?
    @ObservationIgnored private var time: Float = 0
    @ObservationIgnored private let noise = SmoothNoise(seed: 31)
    @ObservationIgnored private var heroFeet = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var heroScale: Float = 0.42
    @ObservationIgnored private var flareOrder: Float = -1
    @ObservationIgnored private var flareAge: Float = 10
    @ObservationIgnored private var flight: (from: SIMD3<Float>, to: SIMD3<Float>, t: Float, lightTo: Float, flare: Float)?
    @ObservationIgnored var updates: EventSubscription?
    @ObservationIgnored var focus: SIMD3<Float>?
    @ObservationIgnored private var camPos = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var camLook = SIMD3<Float>(0, 0, -1.2)
    @ObservationIgnored private var pw: Float = 1
    @ObservationIgnored private var ph: Float = 1

    var heartDepth: Float = 0
    var vitality: Float = 1
    var lanternTotal = 0
    var litCount: Int { _ = heartDepth; return lanterns.filter { $0.order <= Restoration.amount(depth: heartDepth) }.count }

    static let distance: Float = 1.2, fov: Float = 40

    private func relief(_ g: Float) -> Float { 0.45 * pow(g, 0.6) - 0.15 }
    private func depthAt(_ u: Float, _ v: Float) -> Float {
        guard let d = depthMap else { return 0.3 }
        let cx = Int(u * Float(d.w - 1)), cy = Int((1 - v) * Float(d.h - 1))
        var sum = 0, n = 0
        for dy in -2...2 { for dx in -2...2 {
            let x = max(0, min(d.w - 1, cx + dx)), y = max(0, min(d.h - 1, cy + dy))
            sum += Int(d.px[y * d.w + x]); n += 1
        } }
        return Float(sum) / Float(n * 255)
    }

    func build() async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let tex = try await TextureResource(named: "grove-paint.png")
        let lanternTex = try await TextureResource(named: "grove-lanterns.png", options: .init(semantic: .raw))
        if let img = UIImage(named: "grove-depth.png")?.cgImage {
            var px = [UInt8](repeating: 0, count: img.width * img.height)
            let ctx = CGContext(data: &px, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width,
                                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
            depthMap = (img.width, img.height, px)
        }
        let visibleH = 2 * Self.distance * tan(Self.fov / 2 * .pi / 180)
        let aspect = Float(tex.width) / Float(tex.height)
        let (w, h) = (visibleH * aspect * 1.08, visibleH * 1.08)
        pw = w; ph = h
        func point(_ u: Float, _ v: Float, nearer extra: Float = 0) -> SIMD3<Float> {
            let rest = SIMD3<Float>((u - 0.5) * w, (v - 0.5) * h, -Self.distance)
            let d = Self.distance - relief(depthAt(u, v)) - extra
            return rest * (d / Self.distance)
        }

        let (nx, ny) = (72, 162)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            pos.append(point(u, v)); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: "grove")
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: .init(tex))
        var material: any RealityKit.Material = unlit
        if let lib {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "groveRestore", in: lib))
            m.custom.texture = .init(lanternTex)
            m.custom.value = [0, 1, -1, 10]
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        // Lantern positions (in front of the relief by a hair) and their relight order, from tools' detection.
        if let url = Bundle.main.url(forResource: "grove-lanterns", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]] {
            let n = list.count
            lanterns = list.enumerated().map { k, l in
                let order = Float(1 + Int(254 * Double(k) / Double(max(1, n - 1)))) / 255
                return (point(Float(l["u"]!), Float(l["v"]!), nearer: 0.01), order)
            }
            lanternTotal = lanterns.count
        }

        // Fireflies: they come back as the Grove restores.
        let flies = Entity()
        var f = ParticleEmitterComponent()
        f.emitterShape = .box; f.emitterShapeSize = [0.45, 0.3, 0.25]
        f.emissionDirection = [0, 1, 0]; f.speed = 0.008; f.speedVariation = 0.006
        f.mainEmitter.birthRate = 0; f.mainEmitter.lifeSpan = 5; f.mainEmitter.lifeSpanVariation = 2
        f.mainEmitter.size = 0.0035; f.mainEmitter.blendMode = .additive
        f.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 1)))
        flies.components.set(f); flies.position = [0, -0.12, -0.95]
        root.addChild(flies); self.flies = flies

        // The light strand: a glowing orb with a trail of sparks.
        if let lib {
            var u = UnlitMaterial(); u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false
            var m = try CustomMaterial(from: u, surfaceShader: .init(named: "strandGlow", in: lib))
            m.custom.value = [0, 0, 0, 0]; m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = false
            let orb = ModelEntity(mesh: .generatePlane(width: 0.035, height: 0.035), materials: [m])
            var trail = ParticleEmitterComponent()
            trail.emitterShape = .point; trail.speed = 0.005
            trail.mainEmitter.birthRate = 0; trail.mainEmitter.lifeSpan = 0.6; trail.mainEmitter.size = 0.004
            trail.mainEmitter.blendMode = .additive
            trail.mainEmitter.color = .constant(.single(UIColor(red: 1, green: 0.85, blue: 0.5, alpha: 1)))
            orb.components.set(trail)
            root.addChild(orb); strand = orb
        }

        // The Flame on the stone circle.
        let circle = point(0.5, 0.335, nearer: 0.012)
        try await hero.build()
        let k = -circle.z / Self.distance
        heroScale = 0.55 * k
        hero.leanPivot.scale = .init(repeating: heroScale)
        hero.leanPivot.position = circle + SIMD3(0, 0.09 * heroScale, 0)
        root.addChild(hero.leanPivot)
        heroFeet = circle

        try await life.build()
        root.addChild(life.root)
        camera.camera.fieldOfViewInDegrees = Self.fov
        root.addChild(camera)
    }

    func spot(_ u: Float, _ v: Float) -> SIMD3<Float> {
        let rest = SIMD3<Float>((u - 0.5) * pw, (v - 0.5) * ph, -Self.distance)
        let d = Self.distance - relief(depthAt(u, v))
        return rest * (d / Self.distance)
    }

    /// A real Heart action: the Flame cheers and sends a strand of light to the next unlit lanterns.
    func act() {
        guard flight == nil else { return }
        let r = Restoration.amount(depth: heartDepth)
        let next = lanterns.filter { $0.order > r }.sorted { $0.order < $1.order }
        guard let first = next.first else { return }
        let last = next[min(next.count - 1, 5)]                     // a small cluster per action
        hero.react(.cheer)
        let from = heroFeet + SIMD3(hero.standingX * heroScale, 0.14 * heroScale, 0.01)
        flight = (from, first.pos, 0, last.order + 0.0005, first.order)
    }

    func update(dt: Float) {
        time += dt
        let chest = heroFeet + SIMD3(hero.standingX * heroScale, 0.13 * heroScale, 0.005)
        if let watch = life.update(dt: dt, flameAt: chest) { hero.look(at: watch) }
        hero.wind = life.wind
        hero.update(dt: dt)
        flareAge += dt

        // The strand's flight: a gentle arc from the Flame to the lantern, then the relight.
        if var f = flight, let strand {
            f.t += dt / 1.1
            let t = min(1, f.t)
            let e = t * t * (3 - 2 * t)
            let arc = SIMD3<Float>(0, sin(t * .pi) * 0.12, 0)
            strand.position = f.from + (f.to - f.from) * e + arc
            setStrand(opacity: t < 0.95 ? 1 : (1 - t) * 20, emitting: t < 0.95)
            if t >= 1 {
                heartDepth = max(heartDepth, Restoration.depth(amount: f.lightTo))
                flareOrder = f.flare; flareAge = 0
                flight = nil
            } else { flight = f }
        }

        let r = Restoration.amount(depth: heartDepth)
        if let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            m.custom.value = [r, vitality, flareOrder, flareAge]
            m.roughness = .init(floatLiteral: abs(life.wind))
            comp.materials = [m]; painting.model = comp
        }
        if let flies, var f = flies.components[ParticleEmitterComponent.self] {
            f.mainEmitter.birthRate = r < 0.25 ? 0 : (r - 0.25) * 18
            f.mainEmitter.acceleration = [life.wind * 0.02, 0, 0]
            flies.components.set(f)
        }
        let drift = SIMD2(noise.sample(time * 0.09), noise.sample(time * 0.07 + 30)) * 0.05
        let offset = SIMD3<Float>(drift.x, drift.y * 0.6, 0)
        let (wantPos, wantLook): (SIMD3<Float>, SIMD3<Float>) = focus.map { f0 in
            // Glide toward the spot but keep the view inside the painting (side spots would show its edge).
            let f = SIMD3<Float>(max(-0.09, min(0.09, f0.x)), f0.y, f0.z)
            return (f * 0.42 + offset * 0.3, f) }
            ?? (offset, [offset.x * 0.3, offset.y * 0.3, -Self.distance])
        let k = 1 - exp(-dt * 3.2)
        camPos += (wantPos - camPos) * k; camLook += (wantLook - camLook) * k
        camera.look(at: camLook, from: camPos, relativeTo: nil)
    }

    private func setStrand(opacity: Float, emitting: Bool) {
        guard let strand, var comp = strand.model, var m = comp.materials.first as? CustomMaterial else { return }
        m.custom.value = [max(0, opacity), 0, 0, 0]
        comp.materials = [m]; strand.model = comp
        if var trail = strand.components[ParticleEmitterComponent.self] {
            trail.mainEmitter.birthRate = emitting ? 120 : 0
            strand.components.set(trail)
        }
    }
}

struct S3View: View {
    @State private var meter = FrameMeter()
    @State private var scene = GroveScene()
    @State private var director: AliveDirector?
    @State private var depthSlider: Double = 0     // sqrt scale, 0…20 → Depth 0…400

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RealityView { content in
                content.camera = .virtual
                do { try await scene.build() } catch { return }
                content.add(scene.root)
                let d = AliveDirector(seed: 13, meter: meter)
                d.attach(scene.hero, tempo: 0.55)
                director = d
                if let i = CommandLine.arguments.firstIndex(of: "-depth"), i + 1 < CommandLine.arguments.count,
                   let v = Float(CommandLine.arguments[i + 1]) { scene.heartDepth = v; depthSlider = Double(sqrt(v)) }
                scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
                if CommandLine.arguments.contains("-autoact") {
                    Task { @MainActor in
                        for _ in 0..<14 { try? await Task.sleep(for: .seconds(1.6)); scene.act() }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture { director?.tapped() }

            VStack(spacing: 8) {
                HUDView(meter: meter)
                let level = Restoration.level(depth: scene.heartDepth)
                Text(String(format: "Heart Depth %.1f · %d · %@ · %d/%d lights", scene.heartDepth, level,
                            Restoration.names[level], scene.litCount, scene.lanternTotal))
                    .font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5).background(.black.opacity(0.5), in: Capsule())
                Spacer()
                Button {
                    scene.act()
                } label: {
                    Label("A real Heart action", systemImage: "heart.fill")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.black.opacity(0.45), in: Capsule())
                        .overlay(Capsule().stroke(Color(red: 0.95, green: 0.55, blue: 0.6).opacity(0.8), lineWidth: 1))
                        .foregroundStyle(.white)
                }
                if !CommandLine.arguments.contains("-nocontrols") {
                    VStack(spacing: 4) {
                        HStack { Text("Depth").font(.caption)
                            Slider(value: $depthSlider, in: 0...20).onChange(of: depthSlider) { _, v in scene.heartDepth = Float(v * v) } }
                        HStack { Text("Vitality").font(.caption)
                            Slider(value: Binding(get: { Double(scene.vitality) }, set: { scene.vitality = Float($0) }), in: 0...1) }
                    }
                    .padding(10).background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("S3 · Restoration (the Grove)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { meter.start() }
        .onDisappear { meter.stop(); director?.stop() }
    }
}
