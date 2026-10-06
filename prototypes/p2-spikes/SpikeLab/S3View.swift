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
final class RealmScene {
    @ObservationIgnored let root = Entity()
    @ObservationIgnored let camera = PerspectiveCamera()
    /// The Spark (decision 125), hovering over the Grove's stone circle.
    @ObservationIgnored let hero = HeroRig(base: "spark", footInset: 0.045, reflection: false, glows: true, wander: 0.004, spirit: true)
    @ObservationIgnored let life = SanctuaryLife()
    @ObservationIgnored private var painting: ModelEntity?
    @ObservationIgnored private var flies: Entity?
    /// Things that float in the sky, cut out of the painting (tools/build_life.py): books drift and flap their pages,
    /// islands bob, each in its own rhythm (decision 142).
    @ObservationIgnored private var floaters: [(e: Entity, base: SIMD3<Float>, phase: Float, book: Bool, scale: Float)] = []
    @ObservationIgnored private var strand: ModelEntity?
    @ObservationIgnored private var lanterns: [(pos: SIMD3<Float>, order: Float)] = []
    @ObservationIgnored private var depthMap: (w: Int, h: Int, px: [UInt8])?
    @ObservationIgnored private var time: Float = 0
    @ObservationIgnored private let noise = SmoothNoise(seed: 31)
    @ObservationIgnored private var heroFeet = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var heroScale: Float = 0.42
    @ObservationIgnored private var flareOrder: Float = -1
    @ObservationIgnored private var flareAge: Float = 10
    @ObservationIgnored private var fliesRate: Float = -1
    @ObservationIgnored private var clockReadAt: Float = 0
    @ObservationIgnored private var flight: (from: SIMD3<Float>, to: SIMD3<Float>, t: Float, lightTo: Float, flare: Float)?
    @ObservationIgnored var updates: EventSubscription?
    @ObservationIgnored var focus: SIMD3<Float>?
    @ObservationIgnored private var camPos = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var camLook = SIMD3<Float>(0, 0, -1.2)
    @ObservationIgnored private var camVel = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var lookVel = SIMD3<Float>(0, 0, 0)
    @ObservationIgnored private var pw: Float = 1
    @ObservationIgnored private var ph: Float = 1

    var heartDepth: Float = 0
    var vitality: Float = 1
    var lanternTotal = 0
    var litCount: Int { _ = heartDepth; return lanterns.filter { $0.order <= Restoration.amount(depth: heartDepth) }.count }

    static let distance: Float = 1.2, fov: Float = 40

    /// Which realm this is (one engine for every realm: the Grove, the Stillwater, the Highlands…). Its assets are
    /// named after it: <id>-world-paint/-lights/-depth.png and <id>-layout.json (tools/build_realm.py).
    @ObservationIgnored let realm: RealmID
    init(realm: RealmID = .grove) { self.realm = realm }
    private var id: String { realm.rawValue }
    /// Where the Spark hovers (the center of the realm's stone circle, painting uv, v up).
    @ObservationIgnored private var circleUV = SIMD2<Float>(0.5, 0.335)
    var circle: SIMD2<Float> { circleUV }

    /// The swipeable Grove (iteration 2): Codex's side panels stitched around the painting (tools/build_grove.py).
    @ObservationIgnored private lazy var layout: (total: Float, homeX0: Float, homeW: Float)? = {
        guard let url = Bundle.main.url(forResource: "\(id)-layout", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let d = try? JSONSerialization.jsonObject(with: data) as? [String: Double] else { return nil }
        return (Float(d["total"]!), Float(d["homeX0"]!), Float(d["homeW"]!))
    }()
    /// Grove painting u → wide world u.
    func hx(_ u: Float) -> Float { layout.map { ($0.homeX0 + u * $0.homeW) / $0.total } ?? u }
    /// Looking around: the view slides sideways (and a little up and down) on a spring; the view sets the target.
    @ObservationIgnored var panTarget = SIMD2<Float>(0, 0)
    @ObservationIgnored private(set) var pan = SIMD2<Float>(0, 0)
    @ObservationIgnored private var panVel = SIMD2<Float>(0, 0)
    @ObservationIgnored private(set) var panLimit = SIMD2<Float>(0, 0)
    @ObservationIgnored var fingerDown = false
    @ObservationIgnored private var homeShift: Float = 0
    var homeCenterX: Float { homeShift }

    private func relief(_ g: Float) -> Float { 0.2 * pow(g, 0.6) - 0.065 }      // gentle: no smeared gaps (as the Sanctuary)
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
        let wide = layout != nil
        let tex = try await TextureResource(named: wide ? "\(id)-world-paint.png" : "\(id)-paint.png")
        // New realms carry their lights and their water in one map (RGBA); the Grove's older map has no water channel.
        let hasWater = UIImage(named: "\(id)-world-lights.png") != nil
        let lanternTex = try await TextureResource(named: hasWater ? "\(id)-world-lights.png" : (wide ? "\(id)-world-lanterns.png" : "\(id)-lanterns.png"), options: .init(semantic: .raw))
        if let url = Bundle.main.url(forResource: "\(id)-layout", withExtension: "json"), let data = try? Data(contentsOf: url),
           let d = try? JSONSerialization.jsonObject(with: data) as? [String: Double], let cu = d["circleU"], let cv = d["circleV"] {
            circleUV = [Float(cu), Float(cv)]
        }
        if let img = UIImage(named: wide ? "\(id)-world-depth.png" : "\(id)-depth.png")?.cgImage {
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
        let screen = UIScreen.main.bounds.size
        let camH = visibleH, camW = camH * Float(screen.width / screen.height)
        // Sideways: up to ~45% of a screen each way (Clash of Clans: the stone circle stays in reach); never past the world.
        func nearest(_ pts: [(Float, Float)]) -> Float { pts.map { Self.distance - relief(depthAt($0.0, $0.1)) }.min() ?? Self.distance }
        let steps = (0...40).map { Float($0) / 40 }
        let edges = (l: nearest(steps.map { (0, $0) }), r: nearest(steps.map { (1, $0) }),
                     b: nearest(steps.map { ($0, 0) }), t: nearest(steps.map { ($0, 1) }))
        let safe = EdgeSafety.limit(planeW: w, planeH: h, restDistance: Self.distance, edges: edges, fov: Self.fov,
                                    aspect: Float(screen.width / screen.height), margin: EdgeSafety.rubber + 0.03)
        _ = camH
        // The view rests on the home painting (the circle), even when the world isn't centered on it (a panel
        // still missing): looking around stays inside the nearer edge.
        homeShift = (hx(0.5) - 0.5) * w
        panLimit = [max(0, min(camW * EdgeSafety.lookAround, safe.x - abs(homeShift))), safe.y]   // as in the Sanctuary; no edge ever shows
        func point(_ u: Float, _ v: Float, nearer extra: Float = 0) -> SIMD3<Float> {
            let rest = SIMD3<Float>((u - 0.5) * w, (v - 0.5) * h, -Self.distance)
            let d = Self.distance - relief(depthAt(u, v)) - extra
            return rest * (d / Self.distance)
        }

        let (nx, ny) = (wide ? 150 : 72, 162)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            pos.append(point(u, v)); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: id)
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .white, texture: .init(tex))
        var material: any RealityKit.Material = unlit
        if let lib {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "groveRestore", in: lib))
            if let lut = await SolarClock.lut() { m.emissiveColor = .init(texture: .init(lut)) }   // the looks of the hour
            m.custom.texture = .init(lanternTex)
            m.custom.value = [0, 1, -1, 10]
            m.metallic = .init(floatLiteral: hasWater ? 1 : 0)      // 1 = the water mask is in the lights map's alpha
            // Its life map (what breathes: foliage, cloth), when the tool has made one.
            if UIImage(named: "\(id)-world-life.png") != nil,
               let life = try? await TextureResource(named: "\(id)-world-life.png", options: .init(semantic: .raw)) {
                m.normal = .init(texture: .init(life))
                m.clearcoatRoughness = .init(floatLiteral: 1)
            }
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        // The floaters, each at its own depth a little in front of the painting (so they move against it).
        if let url = Bundle.main.url(forResource: "\(id)-floaters", withExtension: "json"), let data = try? Data(contentsOf: url),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for (k, f) in list.enumerated() {
                guard let file = f["file"] as? String, let tex = try? await TextureResource(named: "\(file).png"),
                      let u = f["u"] as? Double, let v = f["v"] as? Double, let fw = f["w"] as? Double, let fh = f["h"] as? Double else { continue }
                let extra = 0.03 + Float(k % 4) * 0.012
                let pos = point(Float(u), Float(v), nearer: extra)
                let ratio = -pos.z / Self.distance                          // keeps its painted size from the rest view
                var mat = UnlitMaterial(); mat.color = .init(tint: .white, texture: .init(tex))
                mat.blending = .transparent(opacity: .init(floatLiteral: 1)); mat.writesDepth = false
                let e = ModelEntity(mesh: .generatePlane(width: Float(fw) * w * ratio, height: Float(fh) * h * ratio), materials: [mat])
                e.position = pos
                root.addChild(e)
                floaters.append((e, pos, Float(k) * 1.37, (f["kind"] as? String ?? "book") == "book", 1))
            }
        }

        // Lantern positions (in front of the relief by a hair) and their relight order, from tools' detection.
        if let url = Bundle.main.url(forResource: "\(id)-lights", withExtension: "json") ?? Bundle.main.url(forResource: "\(id)-lanterns", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]] {
            let n = list.count
            lanterns = list.enumerated().map { k, l in
                let order = Float(1 + Int(254 * Double(k) / Double(max(1, n - 1)))) / 255
                return (point(hx(Float(l["u"]!)), Float(l["v"]!), nearer: 0.01), order)
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
        let circle = point(hx(circleUV.x), circleUV.y, nearer: 0.012)
        try await hero.build()
        let k = -circle.z / Self.distance
        heroScale = 0.105 * h * k / 0.27                            // the Spark's size, as in the Sanctuary
        hero.leanPivot.scale = .init(repeating: heroScale)
        hero.leanPivot.position = circle + SIMD3(0, 0.09 * heroScale, 0)
        hero.stationary = true
        root.addChild(hero.leanPivot)
        heroFeet = circle

        try await life.build()
        root.addChild(life.root)

        // Soft glowing motes drifting close to you, in front of the whole realm (depth and air), as at home.
        let motes = Entity()
        var mp = ParticleEmitterComponent()
        mp.emitterShape = .box; mp.emitterShapeSize = [0.5, 0.9, 0.25]
        mp.emissionDirection = [0.3, 1, 0]; mp.speed = 0.012; mp.speedVariation = 0.008
        mp.mainEmitter.birthRate = 5; mp.mainEmitter.lifeSpan = 7; mp.mainEmitter.lifeSpanVariation = 2
        mp.mainEmitter.size = 0.011; mp.mainEmitter.sizeVariation = 0.007; mp.mainEmitter.blendMode = .additive
        mp.mainEmitter.color = .evolving(start: .single(UIColor(red: 1, green: 0.85, blue: 0.6, alpha: 0.9)), end: .single(UIColor(red: 1, green: 0.7, blue: 0.4, alpha: 0.6)))
        mp.mainEmitter.opacityCurve = .gradualFadeInOut
        motes.components.set(mp); motes.position = [0, -0.05, -0.55]
        root.addChild(motes)
        camera.camera.fieldOfViewInDegrees = Self.fov
        root.addChild(camera)
    }

    /// A point of the Grove painting (its own uv, v up) on the relief, in world space.
    func spot(_ u0: Float, _ v: Float) -> SIMD3<Float> {
        let u = hx(u0)
        let rest = SIMD3<Float>((u - 0.5) * pw, (v - 0.5) * ph, -Self.distance)
        let d = Self.distance - relief(depthAt(u, v))
        return rest * (d / Self.distance)
    }

    /// Where a spot of the Grove painting shows on screen (points), following the camera.
    func screenPoint(_ u: Float, _ v: Float, in size: CGSize) -> CGPoint {
        let w = spot(u, v)
        let rel = camera.transformMatrix(relativeTo: root).inverse * SIMD4<Float>(w.x, w.y, w.z, 1)
        let dz = max(0.01, -rel.z), t = tan(Self.fov / 2 * .pi / 180), aspect = Float(size.width / size.height)
        return CGPoint(x: CGFloat(0.5 + rel.x / dz / (t * aspect) * 0.5) * size.width, y: CGFloat(0.5 - rel.y / dz / t * 0.5) * size.height)
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
        for f in floaters {             // drift, bob, tilt; books open and close their pages like wings
            let t = time + f.phase
            f.e.position = f.base + SIMD3(sin(t * 0.31) * 0.004, sin(t * 0.73) * 0.005 + sin(t * 0.21) * 0.002, 0)
            let tilt = sin(t * 0.52) * 0.09 + sin(t * 1.3) * 0.02
            f.e.orientation = simd_quatf(angle: tilt, axis: [0, 0, 1])
            if f.book {
                let flap = pow(0.5 + 0.5 * sin(t * 2.1), 3) * (0.5 + 0.5 * max(0, sin(t * 0.37)))   // bursts of flapping
                f.e.scale = [1 - flap * 0.35, 1 + flap * 0.04, 1]
            }
        }
        time += dt
        let chest = heroFeet + SIMD3(hero.standingX * heroScale, 0.13 * heroScale, 0.005)
        if let watch = life.update(dt: dt, flameAt: chest) { hero.look(at: watch) }
        hero.wind = life.wind
        if let i = CommandLine.arguments.firstIndex(of: "-hour"), i + 1 < CommandLine.arguments.count, let h = Float(CommandLine.arguments[i + 1]) {
            hero.hour = h                                            // (test: a given hour, as at home)
        } else if time - clockReadAt > 5 || clockReadAt == 0 {     // the real clock, read every few seconds
            hero.hour = SolarClock.lightHour(); clockReadAt = time          // the real sun (seasons included)
        }
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
            m.clearcoat = .init(floatLiteral: max(0.0001, hero.hour / 24))   // the light of the hour (new realms)
            m.specular = .init(floatLiteral: hx(0.5))                          // where the sun sits
            comp.materials = [m]; painting.model = comp
        }
        let rate: Float = (r < 0.25 ? 2 : 2 + (r - 0.25) * 18).rounded()      // always a few: the realm is never still
        if rate != fliesRate, let flies, var f = flies.components[ParticleEmitterComponent.self] {   // only on change (smooth)
            fliesRate = rate; f.mainEmitter.birthRate = rate; flies.components.set(f)
        }
        flies?.position.x = life.wind * 0.03
        let drift = SIMD2(noise.sample(time * 0.09), noise.sample(time * 0.07 + 30)) * 0.025
        let offset = SIMD3<Float>(drift.x, drift.y * 0.6, 0)
        let (wantPos, wantLook): (SIMD3<Float>, SIMD3<Float>) = focus.map { f0 in
            // Glide toward the spot but keep the view inside the painting (side spots would show its edge).
            let f = SIMD3<Float>(max(-0.09, min(0.09, f0.x)), f0.y, f0.z)
            return (f * 0.42 + offset * 0.3, f) }
            ?? (offset, [offset.x * 0.3, offset.y * 0.3, -Self.distance])
        // Critically damped springs (fluid starts and stops), as in the Sanctuary.
        let wc: Float = 3.4
        camVel += (wc * wc * (wantPos - camPos) - 2 * wc * camVel) * dt; camPos += camVel * dt
        lookVel += (wc * wc * (wantLook - camLook) - 2 * wc * lookVel) * dt; camLook += lookVel * dt
        // Looking around, added on top so the spots floating over the Grove move exactly with it.
        if let i = CommandLine.arguments.firstIndex(of: "-push"), i + 1 < CommandLine.arguments.count {   // (test: held past a limit)
            let d = CommandLine.arguments[i + 1]
            panTarget = [d == "left" ? -9 : d == "right" ? 9 : panTarget.x, d == "up" ? 9 : d == "down" ? -9 : panTarget.y]
        }
        let pt = simd_clamp(panTarget, -panLimit - EdgeSafety.rubber, panLimit + EdgeSafety.rubber)
        let w0: Float = 9
        if fingerDown {                       // 1:1 under the finger (no lag); its speed carries into the glide
            let v = (pt - pan) / max(dt, 0.001); panVel = panVel * 0.5 + v * 0.5; pan = pt
        } else {
            panVel += (w0 * w0 * (pt - pan) - 2 * w0 * panVel) * dt
            pan += panVel * dt
        }
        let pv = SIMD3<Float>(pan.x + homeShift, pan.y, 0)
        camera.look(at: camLook + pv, from: camPos + pv, relativeTo: root)
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
    @State private var scene = RealmScene()
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
