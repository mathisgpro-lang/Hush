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
    private var backdrop: ModelEntity?
    private var vitality: Float = 1
    private var paintingW: Float = 1, paintingH: Float = 1
    /// The swipeable world (decision 120): when the stitched world exists, the home image is a window in its middle.
    private struct WorldLayout: Decodable { let total: Float; let height: Float; let homeX0: Float; let homeW: Float; let backdropW: Float; let backdropH: Float }
    private lazy var layout: WorldLayout? = {
        guard let url = Bundle.main.url(forResource: "world-layout", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WorldLayout.self, from: data)
    }()
    /// The living layers (decision 121): when present, the land is cut out and a real sky and sea live behind it.
    private struct Layers: Decodable { let horizonV: Float; let seaDepth: [Float] }
    private lazy var layers: Layers? = {
        guard layout != nil, let url = Bundle.main.url(forResource: "world-layers", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Layers.self, from: data)
    }()
    private var sky: ModelEntity?
    private var sea: ModelEntity?
    /// The sea's depth (0…1, white = near) at world v, from its curve.
    private func seaDepth(_ v: Float) -> Float {
        guard let c = layers?.seaDepth, c.count > 1 else { return 0 }
        let x = max(0, min(1, v)) * Float(c.count - 1), i = min(c.count - 2, Int(x)), f = x - Float(i)
        return c[i] * (1 - f) + c[i + 1] * f
    }
    /// Home-image u → world u.
    func hx(_ u: Float) -> Float { layout.map { ($0.homeX0 + u * $0.homeW) / $0.total } ?? u }
    /// Home width as a fraction of the world (1 without the wider world).
    var homeRatio: Float { layout.map { $0.homeW / $0.total } ?? 1 }
    private let heroScale: Float = 0.62     // small and cute on the circle, like the First Words frame
    /// The stone circle's center in the painting (uv, v up): the Flame's stage.
    private let circle = SIMD2<Float>(0.540, 0.4648)  // exactly where the Flame sits in the root frame, on its own painted glow
    private var mists: [ModelEntity] = []
    /// The Spark (decision 125): the first Flame, a pure spirit hovering over the stone circle.
    let hero = HeroRig(base: "spark", footInset: 0.045, reflection: false, glows: true, wander: 0.004, spirit: true)
    let life = SanctuaryLife()
    let elements = WorldElements()
    private var currentHour: Float = 18
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
    private var camVel = SIMD3<Float>(0, 0, 0), lookVel = SIMD3<Float>(0, 0, 0)
    /// Looking around (Clash of Clans–style): the camera slides a little in any direction (meters), but the
    /// Sanctuary always stays in view. The view sets the target; the camera follows on a smooth spring.
    /// `panLimit` is how far you may peek from the home view (x sideways, y up and down).
    var panTarget = SIMD2<Float>(0, 0)
    private(set) var pan = SIMD2<Float>(0, 0)
    private var panVel = SIMD2<Float>(0, 0)
    var panLimit = SIMD2<Float>(0, 0)
    /// Points per meter at the painting's depth (for the view to convert finger movement and to move its overlays).
    static let visibleHeight: Float = 2 * distance * tan(fov / 2 * .pi / 180)
    private var watching = false

    static let distance: Float = 1.2
    /// The painting is sized for a 40° view; the camera looks a little closer (35°), which leaves room to peek
    /// up and down as well as sideways.
    static let paintFov: Float = 40
    static let fov: Float = 35

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
    /// Gentler with the living layers: strong relief opened gaps behind near things (the arches) that filled with
    /// stretched, blurry waterfall pixels when the camera moved. The sky and sea layers now give most of the depth.
    private func relief(_ g: Float) -> Float { layers == nil ? 0.45 * pow(g, 0.6) - 0.15 : 0.2 * pow(g, 0.6) - 0.065 }

    func build() async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let prefix = layout == nil ? "home" : "world"
        let tex = try await TextureResource(named: layers == nil ? "\(prefix)-paint.png" : "world-land.png")
        let motion = try await TextureResource(named: "\(prefix)-motion.png", options: .init(semantic: .raw))
        loadDepth("\(prefix)-depth.png")
        let visibleH = 2 * Self.distance * tan(Self.paintFov / 2 * .pi / 180)
        let aspect = Float(tex.width) / Float(tex.height)
        let (w, h) = (visibleH * aspect * 1.08, visibleH * 1.08)     // a little overscan so parallax never shows edges
        paintingW = w; paintingH = h
        let screen = UIScreen.main.bounds.size
        let camH = Self.visibleHeight, camW = camH * Float(screen.width / screen.height)
        // Sideways: up to ~28% of a screen, so the stone circle never leaves the view (and never past the world).
        // Up and down: whatever the painting holds beyond the screen, minus a margin for the camera's breathing.
        panLimit = [min(camW * 0.28, max(0, (w - camW * 1.04) / 2)), max(0, (h - camH) / 2 - 0.03)]

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
            if layers != nil {        // the land is cut out where the sky and the sea live (soft edges, still writes depth)
                m.blending = .transparent(opacity: .init(floatLiteral: 1.0)); m.writesDepth = true
            }
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        if let lib, layers != nil {
            // The sky, far away (so it drifts behind the land when you look around), its clouds alive.
            let skyTex = try await TextureResource(named: "world-sky.png")
            let skyBase = try await TextureResource(named: "world-sky-base.png")
            var su = UnlitMaterial(); su.color = .init(tint: .white, texture: .init(skyTex))
            var sm = try CustomMaterial(from: su, surfaceShader: .init(named: "skyLive", in: lib))
            sm.custom.texture = .init(skyBase); sm.custom.value = [1, 0, 0, 0]
            let skyD: Float = 3.5, ks = skyD / Self.distance
            let sk = ModelEntity(mesh: .generatePlane(width: w * ks * 1.06, height: h * ks * 1.06), materials: [sm])
            sk.position = [0, 0, -skyD]
            root.addChild(sk); sky = sk

            // The open sea: its own surface, lying at the sea's depth (a little behind the land, so rocks and
            // shores always sit on top of it), its waves rolling in.
            let seaTex = try await TextureResource(named: "world-sea.png")
            var qu = UnlitMaterial(); qu.color = .init(tint: .white, texture: .init(seaTex))
            var qm = try CustomMaterial(from: qu, surfaceShader: .init(named: "seaLive", in: lib))
            qm.custom.value = [1, 0, 0, 0]; qm.blending = .transparent(opacity: .init(floatLiteral: 1.0)); qm.writesDepth = true
            let (sx, sy) = (40, 120)
            var spos: [SIMD3<Float>] = [], suv: [SIMD2<Float>] = [], sidx: [UInt32] = []
            for j in 0...sy { for i in 0...sx {
                let u = Float(i) / Float(sx), v = Float(j) / Float(sy)
                let rest = SIMD3<Float>((u - 0.5) * w, (v - 0.5) * h, -Self.distance)
                let d = Self.distance - (relief(seaDepth(v)) - 0.05)
                spos.append(rest * (d / Self.distance)); suv.append([u, v])
            } }
            for j in 0..<sy { for i in 0..<sx {
                let a = UInt32(j * (sx + 1) + i), b = a + 1, c = a + UInt32(sx + 1), d = c + 1
                sidx += [a, b, d, a, d, c]
            } }
            var sdesc = MeshDescriptor(name: "sea")
            sdesc.positions = .init(spos); sdesc.textureCoordinates = .init(suv); sdesc.primitives = .triangles(sidx)
            let se = ModelEntity(mesh: try MeshResource.generate(from: [sdesc]), materials: [qm])
            root.addChild(se); sea = se
        }

        // The world doesn't end at the painting's edge: a softly continued backdrop behind it, much larger,
        // graded by the same light (time of day, the Hush), so no edge or black can ever show.
        // (Not needed with the living layers: the sky covers everything behind the land.)
        if let lib, layers == nil, let bTex = try? await TextureResource(named: "\(prefix)-backdrop.png") {
            let blank = try await TextureResource(named: "blank-mask.png", options: .init(semantic: .raw))
            var u = UnlitMaterial(); u.color = .init(tint: .white, texture: .init(bTex))
            var m = try CustomMaterial(from: u, surfaceShader: .init(named: "stoneLive", in: lib))
            m.custom.texture = .init(blank); m.custom.value = [1, 0.5, 0.5, 0]
            let back: Float = layers == nil ? 0.5 : 3.0, k = (Self.distance + back) / Self.distance   // behind the sky when it exists
            let bw = layout.map { w * $0.backdropW / $0.total * k } ?? w * (1618.0 / 852.0) * k
            let bh = layout.map { h * $0.backdropH / $0.height * k } ?? h * (2768.0 / 1846.0) * k
            let b = ModelEntity(mesh: .generatePlane(width: bw, height: bh), materials: [m])
            b.position = [0, 0, -(Self.distance + back)]
            root.addChild(b); backdrop = b
        }

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
        let d = Self.distance - relief(depthAt(hx(circle.x), circle.y)) - 0.01
        let k = d / Self.distance
        // Exactly as in the root frame: the cutout is 426 of the painting's 1846 px tall (its mesh is 0.27 tall).
        let scale = 0.126 * h * k / 0.27      // the Spark: about a ninth of the painting's height (small, a newborn spirit)
        let feet = SIMD3<Float>((hx(circle.x) - 0.5) * w * k, (circle.y - 0.5) * h * k, -d)
        hero.leanPivot.scale = .init(repeating: scale)
        hero.leanPivot.position = feet + SIMD3(0, 0.09 * scale, 0)
        hero.stationary = true
        root.addChild(hero.leanPivot)
        heroFeet = feet; heroWorldScale = scale

        try await life.build()
        root.addChild(life.root)
        if !CommandLine.arguments.contains("-noelements") {      // (test flag: the world without particles)
            try await elements.build(spot: { [unowned self] u, v in self.spot(self.hx(u), v) }, paintingW: w, withClouds: layers == nil)
            root.addChild(elements.root)
        }

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
        if CommandLine.arguments.contains("-onlyland") {        // (test flag: only the land painting)
            for e in root.children where e !== painting && e !== camera { e.isEnabled = false }
        }
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
            m.custom.value.x = 0.03 + (1 - v) * (k == 0 ? 0.55 : 0.7)   // a faint veil when you're living fully; the Hush thickens it (never in front of the Flame)
            comp.materials = [m]; e.model = comp
            e.isEnabled = v < 0.95          // at full vitality the veil is invisible anyway: don't draw three full-screen sheets
        }

    }

    /// -perf: frame timing as RealityKit renders it (frames per second, hitches over 20 ms, the worst frame).
    private var perf = (frames: 0, hitches: 0, worst: Float(0), elapsed: Float(0))
    private let perfOn = CommandLine.arguments.contains("-perf")
    private var layersAt: Float = 0, clockReadAt: Float = 0, clockHour: Float = 18
    private static let hourCycle = CommandLine.arguments.contains("-hourcycle")
    private static let hourArg: Float? = {
        let a = CommandLine.arguments
        guard let i = a.firstIndex(of: "-hour"), i + 1 < a.count else { return nil }
        return Float(a[i + 1])
    }()

    func update(dt: Float) {
        time += dt
        if perfOn {
            perf.frames += 1; perf.elapsed += dt; perf.worst = max(perf.worst, dt)
            if dt > 0.020 { perf.hitches += 1 }
            if perf.elapsed >= 2 {
                print(String(format: "PERF fps %.1f  hitches %d  worst %.1f ms", Float(perf.frames) / perf.elapsed, perf.hitches, perf.worst * 1000) + "  | \(life.debugState) finger \(fingerDown ? 1 : 0) pan \(String(format: "%.2f", pan.x))")
                perf = (0, 0, 0, 0)
            }
        }
        // The Flame's birth: it springs into being (with a little overshoot) when flameTarget becomes 1.
        appear.step(toward: flameTarget, dt: dt)
        hero.leanPivot.scale = .init(repeating: heroWorldScale * max(0, appear.value))
        hero.leanPivot.isEnabled = appear.value > 0.01 || flameTarget > 0
        // Life and wind first, so the Flame can react to them this frame.
        let chest = heroFeet + SIMD3(hero.standingX * heroWorldScale, 0.10 * heroWorldScale, 0.005)
        let watch = life.update(dt: dt, flameAt: chest)
        hero.wind = life.wind
        hero.hour = currentHour
        if !fingerDown {
            if let watch { hero.look(at: watch); watching = true }
            else if watching { hero.look(at: nil); watching = false }   // reset once when the moth leaves
        }
        hero.update(dt: dt)
        elements.update(dt: dt, hour: currentHour, wind: life.wind)
        flies?.position.x = life.wind * 0.03         // the fireflies drift with the wind (moving them is cheap)
        // The Flame's light on the painting follows it and flickers with the fire (A1); dimmer in the Hush.
        if let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            let u = hx(circle.x) + hero.standingX * heroWorldScale / paintingW
            let flicker = 0.85 + 0.15 * noise.sample(time * 7) + 0.05 * sin(time * 23)
            m.custom.value = [vitality, u - 0.03 * homeRatio, circle.y + 0.01, (flicker - 0.9) * 1.4 * max(0, min(1, appear.value))]   // the painted glow breathes with the Flame's fire (±)
            m.roughness = .init(floatLiteral: abs(life.wind))       // the shader reads wind from roughness_scale
            if Self.hourCycle { hourOverride = (6 + time * 0.8).truncatingRemainder(dividingBy: 24) }
            else if let h = Self.hourArg { hourOverride = h }
            if time - clockReadAt > 5 || clockReadAt == 0 {       // the clock is read every few seconds, not every frame
                let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
                clockHour = Float(comps.hour ?? 18) + Float(comps.minute ?? 0) / 60; clockReadAt = time
            }
            let hour = hourOverride ?? clockHour
            currentHour = hour
            m.metallic = .init(floatLiteral: hour / 24)              // and the time of day from metallic_scale
            m.specular = .init(floatLiteral: hx(0.88))               // the painted sun's u (sun rays, moon path)
            m.clearcoat = .init(floatLiteral: homeRatio)             // home width ÷ world width (for round shapes)
            if let backdrop, var bc = backdrop.model, var bm = bc.materials.first as? CustomMaterial {
                bm.custom.value = [m.custom.value.x, 2, 2, 0]; bm.metallic = m.metallic; bm.roughness = m.roughness; bm.specular = .init(floatLiteral: 2); bm.clearcoat = m.clearcoat
                bc.materials = [bm]; backdrop.model = bc
            }
            // The sky and sea only need slow values (vitality, hour, wind): refreshed twice a second.
            let refreshLayers = time - layersAt > 0.5
            if refreshLayers { layersAt = time }
            for layer in [sky, sea].compactMap({ $0 }) where refreshLayers {
                guard var lc = layer.model, var lm = lc.materials.first as? CustomMaterial else { continue }
                lm.custom.value = [m.custom.value.x, 0, 0, 0]; lm.metallic = m.metallic; lm.roughness = m.roughness
                lm.specular = m.specular; lm.clearcoat = m.clearcoat
                lc.materials = [lm]; layer.model = lc
            }
            comp.materials = [m]; painting.model = comp
        }
        // The camera breathes very slowly (an alive world), and follows the phone's tilt for parallax.
        let driftAmp: Float = layers != nil ? 0.03 : (autoDrift ? 0.12 : 0.04)     // a calm breath, not a sway
        let drift = SIMD2(noise.sample(time * 0.08), noise.sample(time * 0.06 + 30)) * driftAmp
        var offset = SIMD3<Float>(tilt.x * 0.11 + drift.x, -tilt.y * 0.07 + drift.y * 0.6, sin(time * 0.11) * (layers != nil ? 0.015 : 0.05))
        if CommandLine.arguments.contains("-camtest") { offset = SIMD3(sin(time * 1.2) > 0 ? 0.1 : -0.1, cos(time * 0.9) > 0 ? 0.07 : -0.07, 0.05) }
        offset.x = max(-0.1, min(0.1, offset.x)); offset.y = max(-0.07, min(0.07, offset.y))
        let (wantPos, wantLook): (SIMD3<Float>, SIMD3<Float>) = focus.map { f0 in
            // Glide toward the spot but keep the view inside the painting (side spots would show its edge).
            let f = SIMD3<Float>(max(-0.09, min(0.09, f0.x)), f0.y, f0.z)
            return (f * 0.42 + offset * 0.3, f) }
            ?? (offset, [offset.x * 0.3, offset.y * 0.3, -Self.distance])
        // Looking around: a critically damped spring toward the target (glides, never jerks, no overshoot).
        let pt = simd_clamp(panTarget, -panLimit - 0.05, panLimit + 0.05)
        let w0: Float = 7.5
        panVel += (w0 * w0 * (pt - pan) - 2 * w0 * panVel) * dt
        pan += panVel * dt
        let panV = SIMD3<Float>(pan.x, pan.y, 0)
        // The camera itself moves on springs too (fluid: smooth starts and stops, no sudden changes of speed).
        let wc: Float = 3.4
        // (The look-around pan is added after, so the world and the calls floating on it move exactly together.)
        camVel += (wc * wc * (wantPos - camPos) - 2 * wc * camVel) * dt
        camPos += camVel * dt
        lookVel += (wc * wc * (wantLook - camLook) - 2 * wc * lookVel) * dt
        camLook += lookVel * dt
        camera.look(at: camLook + panV, from: camPos + panV, relativeTo: nil)
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
