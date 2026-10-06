// The world map, alive (iteration 2, decision 124): Codex's map painting bent in depth like the Sanctuary, with
// moving water, waterfalls, glowing lanterns and the light of the hour (the same stoneLive shader), clouds floating
// at different heights between you and the land (you fly over it), grey mist resting on the realms still in the Hush,
// small lights along the road you've already lit, a beacon on each open realm, and your Spark where you are.
// You move around like on a Clash of Clans map (drag, pinch, soft edges), and entering a realm is a bird's dive.
import SwiftUI
import RealityKit
import Metal
import CoreMotion

@MainActor
final class MapScene {
    let root = Entity()
    let camera = PerspectiveCamera()
    static let distance: Float = 1.2
    static let fov: Float = 40
    /// The painting's size: the wide map (Codex's side panels stitched on, tools/stitch_map.py), and where the
    /// original 803-wide map (whose pixels place the realms) starts inside it.
    static let wide: (x0: Float, w: Float, h: Float) = {
        if let u = Bundle.main.url(forResource: "map-wide", withExtension: "json"), let d = try? Data(contentsOf: u),
           let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let x0 = j["x0"] as? Double, let w = j["width"] as? Double, let h = j["height"] as? Double { return (Float(x0), Float(w), Float(h)) }
        return (0, 803, 1958)
    }()
    static let mapPixels = SIMD2<Float>(wide.w, wide.h)

    private var painting: ModelEntity?
    private(set) var planeW: Float = 1, planeH: Float = 1
    private var screenAspect: Float = 0.46
    private var depth: (w: Int, h: Int, px: [UInt8])?
    private var clouds: [(e: Entity, speed: Float, baseX: Float, span: Float)] = []
    private var hushMists: [(e: Entity, phase: Float, base: SIMD3<Float>)] = []
    private var borderClouds: [(e: Entity, phase: Float, base: SIMD3<Float>)] = []
    private var pathLights: [(e: Entity, phase: Float)] = []
    private var shadows: [(e: Entity, speed: Float, span: Float)] = []
    private var floaters: [(e: Entity, base: SIMD3<Float>, phase: Float, book: Bool)] = []
    private var nearClouds: [(e: Entity, base: SIMD3<Float>, phase: Float, depth: Float)] = []
    private var circlers: [(e: Entity, center: SIMD3<Float>, radius: Float, speed: Float, phase: Float)] = []
    /// The living parallax: the camera orbits a little around what you look at (leaning as you drag, following the
    /// phone's tilt), so the relief really moves: hills and islands shift against the sea like a diorama.
    private let tiltSensor = CMMotionManager()
    private var tiltRef: (roll: Double, pitch: Double)?
    private var orbit = SIMD2<Float>(0, 0), orbitVel = SIMD2<Float>(0, 0)
    static let orbitMax: Float = 0.035
    private var birds: [(e: Entity, phase: Float, base: SIMD3<Float>, vel: SIMD2<Float>, span: SIMD2<Float>)] = []
    private var beacons: [(e: Entity, phase: Float)] = []
    private var mistRealm: [RealmID] = [], beaconRealm: [RealmID] = []
    /// A realm opened since the map was built: its mist lifts and its beacon lights.
    func refresh(open: Set<RealmID>) {
        for (i, r) in mistRealm.enumerated() { hushMists[i].e.isEnabled = !open.contains(r) }
        for (i, r) in beaconRealm.enumerated() { beacons[i].e.isEnabled = open.contains(r) }
    }
    private var spark: Entity?
    private var sparkBase = SIMD3<Float>(0, 0, 0)
    private var time: Float = 0
    var hourOverride: Float?
    private var clockHour: Float = 18, clockReadAt: Float = 0, lightSentAt: Float = -1

    // Camera: pan (meters on the map) and zoom (1 = the default view), both on critically damped springs.
    var panTarget = SIMD2<Float>(0, 0), zoomTarget: Float = 1
    var fingerDown = false
    private(set) var pan = SIMD2<Float>(0, 0), zoom: Float = 1
    private var panVel = SIMD2<Float>(0, 0), zoomVel: Float = 0
    /// The dive: 0 = at the map, 1 = right on top of the realm (the camera rushes down through the clouds).
    private(set) var dive: Float = 0
    private var diveTarget: Float = 0, diveVel: Float = 0, diveFrom = SIMD2<Float>(0, 0), diveTo = SIMD2<Float>(0, 0)
    var updates: EventSubscription?

    // MARK: Map coordinates

    /// Map pixel (y down) → uv (v up).
    func uv(_ p: CGPoint) -> SIMD2<Float> { [(Float(p.x) + Self.wide.x0) / Self.mapPixels.x, 1 - Float(p.y) / Self.mapPixels.y] }
    private func depthAt(_ u: Float, _ v: Float) -> Float {
        guard let d = depth else { return 0.3 }
        let x = max(0, min(d.w - 1, Int(u * Float(d.w - 1)))), y = max(0, min(d.h - 1, Int((1 - v) * Float(d.h - 1))))
        return Float(d.px[y * d.w + x]) / 255
    }
    private func relief(_ g: Float) -> Float { 0.27 * pow(g, 0.6) - 0.085 }    // deep enough that the parallax shows
    /// A point on the map's relief (world space), from uv.
    func spot(_ u: Float, _ v: Float, lift: Float = 0) -> SIMD3<Float> {
        let rest = SIMD3<Float>((u - 0.5) * planeW, (v - 0.5) * planeH, -Self.distance)
        let d = Self.distance - relief(depthAt(u, v)) - lift
        return rest * (d / Self.distance)
    }
    /// Where a map pixel shows on screen (points), for the tappable realms floating over the map.
    func screenPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let w = spot(uv(p).x, uv(p).y)                       // through the camera as it really is (it orbits)
        let rel = camera.transformMatrix(relativeTo: root).inverse * SIMD4<Float>(w.x, w.y, w.z, 1)
        let dz = max(0.01, -rel.z), t = tan(Self.fov / 2 * .pi / 180), aspect = Float(size.width / size.height)
        return CGPoint(x: CGFloat(0.5 + rel.x / dz / (t * aspect) * 0.5) * size.width, y: CGFloat(0.5 - rel.y / dz / t * 0.5) * size.height)
    }
    /// How far you may move from the center at a zoom: no edge of the map can ever come into view (EdgeSafety:
    /// each edge's nearness from the relief, the zoom bringing the camera closer, the rubber band and breathing).
    private var edgeDist: (l: Float, r: Float, b: Float, t: Float) = (1.2, 1.2, 1.2, 1.2)
    func panLimit(zoom z: Float) -> SIMD2<Float> {
        var lim = EdgeSafety.limit(planeW: planeW, planeH: planeH, restDistance: Self.distance, edges: edgeDist,
                                   camForward: Self.distance - Self.distance / max(0.5, z), fov: Self.fov, aspect: screenAspect,
                                   margin: EdgeSafety.rubber + 0.008 + Self.orbitMax)
        // Sideways only a little past the realms (Mathis: "no need to go so much on each side"): the land beyond is
        // there for breathing room, not to wander into. Zoomed in, you can still reach every realm.
        let realmsW = planeW * 803 / Self.mapPixels.x
        let visibleW = 2 * Self.distance * tan(Self.fov / 2 * .pi / 180) * screenAspect / max(0.5, z)
        lim.x = min(lim.x, max(0, realmsW * 0.56 - visibleW / 2))
        return lim
    }

    // MARK: Build

    func build(open: Set<RealmID>, flameAt: RealmID, lastOpenRoadIndex: Int, ember: String = "craft") async throws {
        let lib = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let tex = try await TextureResource(named: "map-paint.png")
        let motion = try await TextureResource(named: "map-motion.png", options: .init(semantic: .raw))
        if let img = UIImage(named: "map-depth.png")?.cgImage {
            let (w, h) = (img.width, img.height)
            var px = [UInt8](repeating: 0, count: w * h)
            let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
            depth = (w, h, px)
        }
        let screen = UIScreen.main.bounds.size
        screenAspect = Float(screen.width / screen.height)
        let visibleH = 2 * Self.distance * tan(Self.fov / 2 * .pi / 180)
        planeW = visibleH * screenAspect * 1.05 * Self.mapPixels.x / 803   // the realms fit across the screen; the land goes on past them
        planeH = planeW * Self.mapPixels.y / Self.mapPixels.x

        func nearest(_ pts: [(Float, Float)]) -> Float { pts.map { Self.distance - relief(depthAt($0.0, $0.1)) }.min() ?? Self.distance }
        let steps = (0...40).map { Float($0) / 40 }
        edgeDist = (nearest(steps.map { (0, $0) }), nearest(steps.map { (1, $0) }), nearest(steps.map { ($0, 0) }), nearest(steps.map { ($0, 1) }))

        // The painting, bent in depth.
        let (nx, ny) = (48, 140)
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), v = Float(j) / Float(ny)
            pos.append(spot(u, v)); uvs.append([u, v])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: "map")
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var unlit = UnlitMaterial(); unlit.color = .init(tint: .white, texture: .init(tex))
        var material: any RealityKit.Material = unlit
        if let lib {
            var m = try CustomMaterial(from: unlit, surfaceShader: .init(named: "stoneLive", in: lib))
            if let lut = await SolarClock.lut() { m.emissiveColor = .init(texture: .init(lut)) }   // the looks of the hour
            m.custom.texture = .init(motion)
            m.custom.value = [1, 0.5, 0.5, 0]                        // full vitality, no Flame light on the map
            m.specular = .init(floatLiteral: -5)                     // no sun rays (the sun is beyond the map's top)
            m.clearcoatRoughness = .init(floatLiteral: 1)            // its sea of clouds drifts (stoneLive)
            m.clearcoat = .init(floatLiteral: 0.4615 / (Self.mapPixels.x / Self.mapPixels.y))
            material = m
        }
        let p = ModelEntity(mesh: try MeshResource.generate(from: [desc]), materials: [material])
        root.addChild(p); painting = p

        // The map never ends at its edge: a soft continuation of it (mirrored, softly blurred) a little behind,
        // much wider, so moving to the sides never shows black. (Codex's side panels will replace it.)
        if let bTex = try? await TextureResource(named: "map-backdrop.png") {
            var u = UnlitMaterial(); u.color = .init(tint: UIColor(white: 0.92, alpha: 1), texture: .init(bTex))
            let back: Float = 0.06, k = (Self.distance + back) / Self.distance
            let bw = planeW * 1.3 * k, bh = planeH * 1.3 * k
            let b = ModelEntity(mesh: .generatePlane(width: bw, height: bh), materials: [u])
            b.position = [0, 0, -(Self.distance + back)]
            root.addChild(b)
        }

        let cloudTex = try await TextureResource(named: "cloud.png")
        let glowTex = try await TextureResource(named: "glow.png")
        func card(_ t: TextureResource, _ size: SIMD2<Float>, tint: UIColor) -> ModelEntity {
            var u = UnlitMaterial(); u.color = .init(tint: tint, texture: .init(t))
            u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false
            return ModelEntity(mesh: .generatePlane(width: size.x, height: size.y), materials: [u])
        }

        // Clouds at different heights between you and the land: they drift, and slide past at different speeds
        // when you move (parallax), and the dive rushes through them.
        var rng = SeededRandom(seed: 41)
        for k in 0..<16 {
            let z = -Float.random(in: 0.55...1.05, using: &rng)
            let k01 = Float(k) / 15
            let y = (k01 - 0.5) * planeH * 0.95 * (-z / Self.distance)
            let size = Float.random(in: 0.25...0.42, using: &rng) * (-z / Self.distance)
            let e = card(cloudTex, [size, size * 0.42], tint: UIColor(red: 1, green: 0.95, blue: 0.92, alpha: CGFloat(Float.random(in: 0.12...0.24, using: &rng))))   // light wisps, never a fog
            let span = planeW * 0.9 * (-z / Self.distance)
            let x = Float.random(in: -span...span, using: &rng)
            e.position = [x, y, z]
            root.addChild(e); clouds.append((e, Float.random(in: 0.004...0.012, using: &rng), x, span))
        }

        // The world's border (Clash of Clans): beyond the map's sides, the land dissolves into banks of cloud that
        // slowly roll and drift, so moving sideways never finds an edge, only more sky.
        for side in [-1, 1] as [Float] {
            for k in 0..<22 {
                let z = -Self.distance + 0.06 + Float(k % 3) * 0.02
                let kz = -z / Self.distance
                let size = Float.random(in: 0.15...0.22, using: &rng) * kz
                let y = (Float(k) / 21 - 0.5) * planeH * 1.02 * kz
                let x = side * (planeW / 2 + Float.random(in: 0.015...0.07, using: &rng)) * kz
                // Warm and bright like the clouds painted on the map (never a grey fog).
                let tint = UIColor(red: 1, green: CGFloat.random(in: 0.9...0.96, using: &rng), blue: CGFloat.random(in: 0.86...0.93, using: &rng), alpha: 1)
                let e = card(cloudTex, [size, size * 0.62], tint: tint)
                e.position = [x, y, z]
                root.addChild(e); borderClouds.append((e, Float(k) * 1.7 + side, [x, y, z]))
            }
        }

        // Depth you can feel: soft cloud shadows sliding over the land (drawn on top of the relief, below the
        // clouds), and small flocks of birds gliding over the realms between you and the ground.
        for _ in 0..<7 {
            let size = Float.random(in: 0.3...0.55, using: &rng)
            var u = UnlitMaterial(); u.color = .init(tint: UIColor(red: 0.12, green: 0.08, blue: 0.2, alpha: 0.16), texture: .init(cloudTex))
            u.blending = .transparent(opacity: .init(floatLiteral: 1.0)); u.writesDepth = false; u.readsDepth = false
            let e = ModelEntity(mesh: .generatePlane(width: size, height: size * 0.5), materials: [u])
            let span = planeW * 0.55
            e.position = [Float.random(in: -span...span, using: &rng), Float.random(in: -0.45...0.45, using: &rng) * planeH, -Self.distance + 0.02]
            root.addChild(e); shadows.append((e, Float.random(in: 0.006...0.012, using: &rng), span))
        }
        if let birdTex = try? await TextureResource(named: "bird.png") {
            for f in 0..<3 {
                let z = -Self.distance * Float.random(in: 0.7...0.82, using: &rng), kz = -z / Self.distance
                let span = SIMD2(planeW * 0.6, planeH * 0.5) * kz
                let start = SIMD3<Float>(Float.random(in: -span.x...span.x, using: &rng), Float.random(in: -span.y...span.y, using: &rng), z)
                let dir: Float = f % 2 == 0 ? 1 : -1
                let vel = SIMD2<Float>(dir * Float.random(in: 0.018...0.03, using: &rng), Float.random(in: 0.004...0.01, using: &rng))
                for b in 0..<4 {
                    let e = card(birdTex, [0.022, 0.014], tint: UIColor(red: 0.2, green: 0.13, blue: 0.16, alpha: 0.85))
                    if dir < 0 { e.scale = [-1, 1, 1] }
                    let off = SIMD3<Float>(-dir * Float(b) * 0.018 + Float.random(in: -0.006...0.006, using: &rng), Float(b % 2) * 0.012 - 0.006, 0)
                    e.position = start + off
                    root.addChild(e); birds.append((e, Float(b) * 1.3 + Float(f), start + off, vel, span))
                }
            }
        }

        // The islands and books floating around the Library, cut out of the map (tools/map_floaters.py): they bob,
        // tilt and flap, each in its own rhythm, just in front of the painting.
        if let url = Bundle.main.url(forResource: "map-floaters", withExtension: "json"), let data = try? Data(contentsOf: url),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for (k, f) in list.enumerated() {
                guard let file = f["file"] as? String, let tex = try? await TextureResource(named: "\(file).png"),
                      let u = f["u"] as? Double, let v = f["v"] as? Double, let fw = f["w"] as? Double, let fh = f["h"] as? Double else { continue }
                let pos = spot(Float(u), Float(v), lift: 0.012 + Float(k % 3) * 0.006)
                let ratio = -pos.z / Self.distance
                var mat = UnlitMaterial(); mat.color = .init(tint: .white, texture: .init(tex))
                mat.blending = .transparent(opacity: .init(floatLiteral: 1)); mat.writesDepth = false
                let e = ModelEntity(mesh: .generatePlane(width: Float(fw) * planeW * ratio, height: Float(fh) * planeH * ratio), materials: [mat])
                e.position = pos
                root.addChild(e)
                floaters.append((e, pos, Float(k) * 1.61, (f["kind"] as? String) == "book"))
            }
        }

        // A sky you look down through: soft cloud banks close to you at the edges, sliding past much faster than the
        // land when you move (they are near), so the map reads as a world far below.
        for k in 0..<8 {
            let side: Float = k % 2 == 0 ? -1 : 1
            let d: Float = 0.45 + Float(k / 2) * 0.06, z = -d, kz = d / Self.distance
            let half = d * tan(Self.fov / 2 * .pi / 180) * screenAspect             // half the screen's width at that depth
            let y = (Float(k / 2) / 3 - 0.5) * 2 * d * tan(Self.fov / 2 * .pi / 180) * 0.85
            let size = half * Float.random(in: 0.8...1.0, using: &rng)
            let e = card(cloudTex, [size, size * 0.55], tint: UIColor(red: 1, green: 0.96, blue: 0.93, alpha: CGFloat(Float.random(in: 0.35...0.5, using: &rng))))
            let base = SIMD3<Float>(side * (half + size * 0.12), y, z)               // only peeking in from the side
            e.position = base
            root.addChild(e); nearClouds.append((e, base, Float(k) * 1.9, kz))
        }
        // Each realm alive (small particle systems, cheap on the graphics chip).
        func emitter(at r: RealmID, lift: Float = 0.02, _ make: (inout ParticleEmitterComponent) -> Void) {
            let c = uv(r.mapPoint)
            let e = Entity(); var p = ParticleEmitterComponent()
            p.emitterShape = .sphere; p.emitterShapeSize = [0.05, 0.03, 0.02]
            p.mainEmitter.blendMode = .additive
            make(&p)
            e.components.set(p); e.position = spot(c.x, c.y, lift: lift)
            root.addChild(e)
        }
        emitter(at: .forge, lift: 0.03) { p in           // smoke rising from the forge, and its sparks
            p.emitterShapeSize = [0.03, 0.01, 0.01]; p.emissionDirection = [0, 1, 0.3]; p.speed = 0.012; p.speedVariation = 0.004
            p.mainEmitter.birthRate = 6; p.mainEmitter.lifeSpan = 6; p.mainEmitter.size = 0.03; p.mainEmitter.sizeMultiplierAtEndOfLifespan = 3
            p.mainEmitter.blendMode = .alpha
            p.mainEmitter.color = .evolving(start: .single(UIColor(red: 0.45, green: 0.38, blue: 0.4, alpha: 0.35)), end: .single(UIColor(red: 0.6, green: 0.55, blue: 0.6, alpha: 0)))
        }
        emitter(at: .forge, lift: 0.025) { p in
            p.emissionDirection = [0, 1, 0.2]; p.speed = 0.02; p.speedVariation = 0.01; p.emitterShapeSize = [0.02, 0.01, 0.01]
            p.mainEmitter.birthRate = 14; p.mainEmitter.lifeSpan = 1.8; p.mainEmitter.size = 0.0022
            p.mainEmitter.color = .evolving(start: .single(UIColor(red: 1, green: 0.7, blue: 0.3, alpha: 1)), end: .single(UIColor(red: 1, green: 0.3, blue: 0.1, alpha: 0)))
        }
        emitter(at: .grove) { p in                          // fireflies among the lantern trees
            p.emitterShapeSize = [0.12, 0.08, 0.03]; p.speed = 0.003; p.speedVariation = 0.003
            p.mainEmitter.birthRate = 10; p.mainEmitter.lifeSpan = 4; p.mainEmitter.lifeSpanVariation = 1.5; p.mainEmitter.size = 0.0025
            p.mainEmitter.color = .evolving(start: .single(UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)), end: .single(UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 0)))
        }
        emitter(at: .library, lift: 0.04) { p in            // motes of magic rising around the floating library
            p.emitterShapeSize = [0.1, 0.07, 0.03]; p.emissionDirection = [0, 1, 0]; p.speed = 0.006; p.speedVariation = 0.003
            p.mainEmitter.birthRate = 9; p.mainEmitter.lifeSpan = 4; p.mainEmitter.size = 0.0022
            p.mainEmitter.color = .evolving(start: .single(UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 1)), end: .single(UIColor(red: 0.6, green: 0.6, blue: 1, alpha: 0)))
        }
        emitter(at: .wilds) { p in                          // green fireflies in the wild woods
            p.emitterShapeSize = [0.1, 0.07, 0.03]; p.speed = 0.003; p.speedVariation = 0.003
            p.mainEmitter.birthRate = 8; p.mainEmitter.lifeSpan = 4; p.mainEmitter.size = 0.0022
            p.mainEmitter.color = .evolving(start: .single(UIColor(red: 0.7, green: 1, blue: 0.5, alpha: 1)), end: .single(UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0)))
        }
        for r in [RealmID.stillwater, .sanctuary] {          // mist breathing over the lake and the falls
            emitter(at: r, lift: 0.01) { p in
                p.emitterShapeSize = [0.14, 0.04, 0.02]; p.emissionDirection = [1, 0.2, 0]; p.speed = 0.004; p.speedVariation = 0.002
                p.mainEmitter.birthRate = 2; p.mainEmitter.lifeSpan = 6; p.mainEmitter.size = 0.022; p.mainEmitter.sizeMultiplierAtEndOfLifespan = 1.8
                p.mainEmitter.blendMode = .alpha
                p.mainEmitter.color = .evolving(start: .single(UIColor(white: 1, alpha: 0.12)), end: .single(UIColor(white: 1, alpha: 0)))
            }
        }
        if let birdTex = try? await TextureResource(named: "bird.png") {      // birds circling the Highlands' peaks
            let c = uv(RealmID.highlands.mapPoint)
            let center = spot(c.x, c.y, lift: 0.07)
            for b in 0..<3 {
                let e = card(birdTex, [0.018, 0.011], tint: UIColor(red: 0.2, green: 0.13, blue: 0.16, alpha: 0.9))
                root.addChild(e); circlers.append((e, center, 0.05 + Float(b) * 0.012, 0.5 + Float(b) * 0.08, Float(b) * 2.1))
            }
        }
        if tiltSensor.isDeviceMotionAvailable {
            tiltSensor.deviceMotionUpdateInterval = 1.0 / 60
            tiltSensor.startDeviceMotionUpdates()
        }

        // The Hush: soft grey mist resting over the realms not opened yet (nothing destroyed, only quiet).
        // Every realm gets its mist and its beacon; which one shows follows what's open (updated on each visit).
        for r in roadOrder where r != .sanctuary {
            let c = uv(r.mapPoint)
            for j in 0..<2 {
                let base = spot(c.x, c.y, lift: 0.04 + Float(j) * 0.02) + SIMD3(Float(j) * 0.03 - 0.015, Float(j) * 0.02, 0)
                let e = card(cloudTex, [0.32, 0.17], tint: UIColor(red: 0.72, green: 0.72, blue: 0.78, alpha: 0.8))
                e.position = base
                e.isEnabled = !open.contains(r)
                root.addChild(e); hushMists.append((e, Float(j) * 2.1 + Float(c.y) * 9, base)); mistRealm.append(r)
            }
        }

        // The road you've lit: small warm lights along it, twinkling.
        let pts = roadPoints.prefix(lastOpenRoadIndex + 1).map(\.p)
        for i in 0..<max(0, pts.count - 1) {
            for s in 0..<3 {
                let t = CGFloat(s) / 3
                let p = CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * t, y: pts[i].y + (pts[i + 1].y - pts[i].y) * t)
                let c = uv(p)
                let e = card(glowTex, [0.018, 0.018], tint: UIColor(red: 1, green: 0.82, blue: 0.5, alpha: 0.7))
                e.position = spot(c.x, c.y, lift: 0.01)
                root.addChild(e); pathLights.append((e, Float(i * 3 + s) * 0.7))
            }
        }

        // A beacon of light on each open realm, in its color.
        for r in roadOrder {
            let c = uv(r.mapPoint)
            let e = card(glowTex, [0.07, 0.07], tint: UIColor(r.color).withAlphaComponent(0.4))       // a soft halo, never a blotch
            e.position = spot(c.x, c.y, lift: 0.03)
            e.isEnabled = open.contains(r)
            root.addChild(e); beacons.append((e, Float(c.y) * 7)); beaconRealm.append(r)
        }

        // Your Spark, hovering where you are.
        let sparkTex: TextureResource = if let cg = SparkTint.image("spark-keyed.png", ember: ember)?.cgImage {
            try await TextureResource(image: cg, options: .init(semantic: .color))
        } else { try await TextureResource(named: "spark-keyed.png") }
        var su = UnlitMaterial(); su.color = .init(tint: .white, texture: .init(sparkTex))
        su.blending = .transparent(opacity: .init(floatLiteral: 1.0)); su.writesDepth = false
        let sp = ModelEntity(mesh: .generatePlane(width: 0.03, height: 0.03 * Float(sparkTex.height) / Float(sparkTex.width)), materials: [su])
        let fc = uv(flameAt.mapPoint)
        sparkBase = spot(fc.x, fc.y, lift: 0.06) + SIMD3(0.0, 0.03, 0)
        sp.position = sparkBase
        root.addChild(sp); spark = sp

        camera.camera.fieldOfViewInDegrees = Self.fov
        root.addChild(camera)
        // Start over the Sanctuary, near the bottom of the map.
        let start = startPan(for: flameAt)
        panTarget = start; pan = start
    }

    /// The pan that centers a realm (clamped to the map).
    func centerPan(on p: CGPoint, zoom z: Float) -> SIMD2<Float> {
        let s = spot(uv(p).x, uv(p).y)
        return simd_clamp(SIMD2(s.x, s.y), -panLimit(zoom: z), panLimit(zoom: z))
    }
    func startPan(for r: RealmID) -> SIMD2<Float> { centerPan(on: r.mapPoint, zoom: 1) }

    /// Coming back to the map: the view is over the realm you're in, the dive undone, your Spark there.
    func arrive(at r: RealmID) {
        dive = 0; diveVel = 0; diveTarget = 0
        let p = startPan(for: r); pan = p; panTarget = p; panVel = .zero; zoom = 1; zoomTarget = 1; zoomVel = 0
        let fc = uv(r.mapPoint)
        sparkBase = spot(fc.x, fc.y, lift: 0.06) + SIMD3(0.0, 0.03, 0)
    }

    /// Dive into a realm: the camera rises a little, then swoops down onto it through the clouds.
    func startDive(to p: CGPoint) {
        diveFrom = pan
        let s = spot(uv(p).x, uv(p).y)
        diveTo = [s.x, s.y]
        diveTarget = 1
    }

    // MARK: Every frame

    func update(dt: Float) {
        time += dt
        let w0: Float = 9
        let lim = panLimit(zoom: zoom)
        if let i = CommandLine.arguments.firstIndex(of: "-push"), i + 1 < CommandLine.arguments.count {   // (test: held past a limit)
            let d = CommandLine.arguments[i + 1]
            panTarget = [d == "left" ? -9 : d == "right" ? 9 : panTarget.x, d == "up" ? 9 : d == "down" ? -9 : panTarget.y]
        }
        let pt = simd_clamp(panTarget, -lim - EdgeSafety.rubber, lim + EdgeSafety.rubber)
        if fingerDown {                       // 1:1 under the finger (no lag); its speed carries into the glide
            let v = (pt - pan) / max(dt, 0.001); panVel = panVel * 0.5 + v * 0.5; pan = pt
        } else {
            panVel += (w0 * w0 * (pt - pan) - 2 * w0 * panVel) * dt
            pan += panVel * dt
        }
        zoomVel += (w0 * w0 * (zoomTarget - zoom) - 2 * w0 * zoomVel) * dt
        zoom += zoomVel * dt
        // The dive follows its own slower spring (a smooth, accelerating swoop).
        let wd: Float = 5.2      // the swoop: quick and accelerating
        diveVel += (wd * wd * (diveTarget - dive) - 2 * wd * diveVel) * dt
        dive += diveVel * dt

        var camXY = pan, camZ = Self.distance - Self.distance / zoom
        if dive > 0.001 {
            // The swoop: forward and down onto the realm, accelerating (never backward: the map's edge stays hidden).
            let k = min(1, dive)
            let ease = k * k * k * (k * (6 * k - 15) + 10)                    // smootherstep: soft start, rushing end
            camXY = diveFrom + (diveTo - diveFrom) * min(1, ease * 1.4)
            camZ = camZ + ease * (Self.distance - 0.12 - camZ)                // down to just above the realm
            let effectiveZoom = Self.distance / max(0.05, Self.distance - camZ)
            camXY = simd_clamp(camXY, -panLimit(zoom: effectiveZoom), panLimit(zoom: effectiveZoom))
        }
        let breathe = SIMD3<Float>(sin(time * 0.21) * 0.004, sin(time * 0.17) * 0.003, 0)
        let pos = SIMD3<Float>(camXY.x, camXY.y, -camZ) + breathe        // closer = toward the map (−z)
        // The living parallax: lean with the drag and with the phone's tilt, always looking at the same spot on the
        // land, so near hills slide against the far sea. Calm when nothing moves (it drifts back to centre).
        var want = -panVel * 0.06
        if let a = tiltSensor.deviceMotion?.attitude {
            if tiltRef == nil { tiltRef = (a.roll, a.pitch) }
            if let r = tiltRef {
                want += SIMD2(Float(a.roll - r.roll), Float(r.pitch - a.pitch)) * 0.09
                tiltRef = (r.roll + (a.roll - r.roll) * 0.004, r.pitch + (a.pitch - r.pitch) * 0.004)    // slowly re-centres
            }
        }
        want += SIMD2(sin(time * 0.13), sin(time * 0.11 + 1)) * 0.006 * (1 - dive)           // a slow living sway
        want = simd_clamp(want, SIMD2(repeating: -Self.orbitMax), SIMD2(repeating: Self.orbitMax)) * (1 - min(1, dive))
        let wo: Float = 4
        orbitVel += (wo * wo * (want - orbit) - 2 * wo * orbitVel) * dt; orbit += orbitVel * dt
        let focus = SIMD3<Float>(pos.x, pos.y, -Self.distance + 0.05)
        let eye = pos + SIMD3(orbit.x, orbit.y, 0)
        camera.look(at: focus, from: eye, relativeTo: root)

        // The light of the hour on the whole map.
        // (Re-sent four times a second, not every frame: the wind and the hour change slowly.)
        if time - lightSentAt > 0.25, let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            lightSentAt = time
            if time - clockReadAt > 5 || clockReadAt == 0 { clockHour = SolarClock.lightHour(); clockReadAt = time }
            let hour = hourOverride ?? clockHour
            m.metallic = .init(floatLiteral: hour / 24)
            m.roughness = .init(floatLiteral: 0.25 + 0.15 * sin(time * 0.3))
            comp.materials = [m]; painting.model = comp
        }
        for i in clouds.indices {
            var p = clouds[i].e.position
            p.x += clouds[i].speed * dt
            if p.x > clouds[i].span { p.x = -clouds[i].span }
            clouds[i].e.position = p
        }
        for i in shadows.indices {
            var p = shadows[i].e.position
            p.x += shadows[i].speed * dt
            if p.x > shadows[i].span { p.x = -shadows[i].span }
            shadows[i].e.position = p
        }
        for i in birds.indices {       // glide (a gentle wave), flap now and then, and come round again
            var b = birds[i].base
            b.x += birds[i].vel.x * dt; b.y += birds[i].vel.y * dt
            if b.x > birds[i].span.x { b.x = -birds[i].span.x } else if b.x < -birds[i].span.x { b.x = birds[i].span.x }
            if b.y > birds[i].span.y { b.y = -birds[i].span.y }
            birds[i].base = b
            let ph = birds[i].phase
            birds[i].e.position = b + SIMD3(0, 0.004 * sin(time * 0.8 + ph), 0)
            let flap = 0.55 + 0.45 * abs(sin(time * 7 + ph)) * (0.5 + 0.5 * max(0, sin(time * 0.6 + ph)))
            birds[i].e.scale = [birds[i].vel.x < 0 ? -1 : 1, flap, 1]
        }
        for f in floaters {            // floating islands and books: bob, tilt, books flap
            let t = time + f.phase
            f.e.position = f.base + SIMD3(sin(t * 0.27) * 0.0016, sin(t * 0.6) * 0.0022 + sin(t * 0.19) * 0.001, 0)
            f.e.orientation = simd_quatf(angle: sin(t * 0.45) * 0.05, axis: [0, 0, 1])
            if f.book { let flap = pow(0.5 + 0.5 * sin(t * 2.3), 3); f.e.scale = [1 - flap * 0.35, 1, 1] }
        }
        for c in nearClouds {          // near clouds drift slowly and breathe
            c.e.position = c.base + SIMD3(sin(time * 0.07 + c.phase) * 0.02 * c.depth, sin(time * 0.05 + c.phase) * 0.008, 0)
        }
        for c in circlers {            // birds wheeling over the peaks, flapping now and then
            let a = time * c.speed + c.phase
            c.e.position = c.center + SIMD3(cos(a) * c.radius, sin(a) * c.radius * 0.55, sin(a * 2) * 0.004)
            let flap = 0.55 + 0.45 * abs(sin(time * 7 + c.phase)) * (0.5 + 0.5 * max(0, sin(time * 0.5 + c.phase)))
            c.e.scale = [-sin(a) < 0 ? -1 : 1, flap, 1]
        }
        for c in borderClouds {        // the border breathes: clouds roll slowly in and out
            c.e.position = c.base + SIMD3(sin(time * 0.12 + c.phase) * 0.02, sin(time * 0.09 + c.phase * 1.3) * 0.01, 0)
        }
        for h in hushMists {
            h.e.position = h.base + SIMD3(sin(time * 0.25 + h.phase) * 0.015, sin(time * 0.19 + h.phase) * 0.006, 0)
        }
        for l in pathLights {
            let s = 0.75 + 0.25 * sin(time * 2.2 + l.phase) * sin(time * 0.9 + l.phase * 1.3)
            l.e.scale = [s, s, 1]
        }
        for b in beacons {
            let s = 0.9 + 0.12 * sin(time * 1.6 + b.phase)
            b.e.scale = [s, s, 1]
        }
        spark?.position = sparkBase + SIMD3(0, 0.006 * sin(time * 1.5) + 0.002 * sin(time * 0.6), 0)
    }
}
