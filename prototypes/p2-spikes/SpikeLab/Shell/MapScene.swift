// The world map, alive (iteration 2, decision 124): Codex's map painting bent in depth like the Sanctuary, with
// moving water, waterfalls, glowing lanterns and the light of the hour (the same stoneLive shader), clouds floating
// at different heights between you and the land (you fly over it), grey mist resting on the realms still in the Hush,
// small lights along the road you've already lit, a beacon on each open realm, and your Spark where you are.
// You move around like on a Clash of Clans map (drag, pinch, soft edges), and entering a realm is a bird's dive.
import SwiftUI
import RealityKit
import Metal

@MainActor
final class MapScene {
    let root = Entity()
    let camera = PerspectiveCamera()
    static let distance: Float = 1.2
    static let fov: Float = 40
    static let mapPixels = SIMD2<Float>(803, 1958)

    private var painting: ModelEntity?
    private(set) var planeW: Float = 1, planeH: Float = 1
    private var screenAspect: Float = 0.46
    private var depth: (w: Int, h: Int, px: [UInt8])?
    private var clouds: [(e: Entity, speed: Float, baseX: Float, span: Float)] = []
    private var hushMists: [(e: Entity, phase: Float, base: SIMD3<Float>)] = []
    private var pathLights: [(e: Entity, phase: Float)] = []
    private var beacons: [(e: Entity, phase: Float)] = []
    private var spark: Entity?
    private var sparkBase = SIMD3<Float>(0, 0, 0)
    private var time: Float = 0
    var hourOverride: Float?

    // Camera: pan (meters on the map) and zoom (1 = the default view), both on critically damped springs.
    var panTarget = SIMD2<Float>(0, 0), zoomTarget: Float = 1
    private(set) var pan = SIMD2<Float>(0, 0), zoom: Float = 1
    private var panVel = SIMD2<Float>(0, 0), zoomVel: Float = 0
    /// The dive: 0 = at the map, 1 = right on top of the realm (the camera rushes down through the clouds).
    private(set) var dive: Float = 0
    private var diveTarget: Float = 0, diveVel: Float = 0, diveFrom = SIMD2<Float>(0, 0), diveTo = SIMD2<Float>(0, 0)
    var updates: EventSubscription?

    // MARK: Map coordinates

    /// Map pixel (y down) → uv (v up).
    func uv(_ p: CGPoint) -> SIMD2<Float> { [Float(p.x) / Self.mapPixels.x, 1 - Float(p.y) / Self.mapPixels.y] }
    private func depthAt(_ u: Float, _ v: Float) -> Float {
        guard let d = depth else { return 0.3 }
        let x = max(0, min(d.w - 1, Int(u * Float(d.w - 1)))), y = max(0, min(d.h - 1, Int((1 - v) * Float(d.h - 1))))
        return Float(d.px[y * d.w + x]) / 255
    }
    private func relief(_ g: Float) -> Float { 0.2 * pow(g, 0.6) - 0.065 }
    /// A point on the map's relief (world space), from uv.
    func spot(_ u: Float, _ v: Float, lift: Float = 0) -> SIMD3<Float> {
        let rest = SIMD3<Float>((u - 0.5) * planeW, (v - 0.5) * planeH, -Self.distance)
        let d = Self.distance - relief(depthAt(u, v)) - lift
        return rest * (d / Self.distance)
    }
    /// Where a map pixel shows on screen (points), for the tappable realms floating over the map.
    func screenPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let w = spot(uv(p).x, uv(p).y)
        let cam = camera.position(relativeTo: nil)
        let dz = max(0.01, cam.z - w.z)
        let t = tan(Self.fov / 2 * .pi / 180)
        let aspect = Float(size.width / size.height)
        let sx = (w.x - cam.x) / dz / (t * aspect), sy = (w.y - cam.y) / dz / t
        return CGPoint(x: CGFloat(0.5 + sx * 0.5) * size.width, y: CGFloat(0.5 - sy * 0.5) * size.height)
    }
    /// How far you may move from the center at a zoom (the view always stays on the map).
    func panLimit(zoom z: Float) -> SIMD2<Float> {
        let d = Self.distance / z
        let halfH = d * tan(Self.fov / 2 * .pi / 180), halfW = halfH * screenAspect
        return [max(0, planeW / 2 - halfW * 1.02), max(0, planeH / 2 - halfH * 1.02)]
    }

    // MARK: Build

    func build(open: Set<RealmID>, flameAt: RealmID, lastOpenRoadIndex: Int) async throws {
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
        planeW = visibleH * screenAspect * 1.3                       // a little wider than the screen: room to peek sideways
        planeH = planeW * Self.mapPixels.y / Self.mapPixels.x

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
            m.custom.texture = .init(motion)
            m.custom.value = [1, 0.5, 0.5, 0]                        // full vitality, no Flame light on the map
            m.specular = .init(floatLiteral: -5)                     // no sun rays (the sun is beyond the map's top)
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
            let bw = planeW * (1765.0 / 803.0) * k, bh = planeH * (2544.0 / 1958.0) * k
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
        for k in 0..<10 {
            let z = -Float.random(in: 0.55...1.05, using: &rng)
            let k01 = Float(k) / 9
            let y = (k01 - 0.5) * planeH * 0.95 * (-z / Self.distance)
            let size = Float.random(in: 0.25...0.42, using: &rng) * (-z / Self.distance)
            let e = card(cloudTex, [size, size * 0.42], tint: UIColor(red: 1, green: 0.95, blue: 0.92, alpha: CGFloat(Float.random(in: 0.12...0.24, using: &rng))))   // light wisps, never a fog
            let span = planeW * 0.9 * (-z / Self.distance)
            let x = Float.random(in: -span...span, using: &rng)
            e.position = [x, y, z]
            root.addChild(e); clouds.append((e, Float.random(in: 0.004...0.012, using: &rng), x, span))
        }

        // The Hush: soft grey mist resting over the realms not opened yet (nothing destroyed, only quiet).
        for r in roadOrder where !open.contains(r) {
            let c = uv(r.mapPoint)
            for j in 0..<2 {
                let base = spot(c.x, c.y, lift: 0.04 + Float(j) * 0.02) + SIMD3(Float(j) * 0.03 - 0.015, Float(j) * 0.02, 0)
                let e = card(cloudTex, [0.32, 0.17], tint: UIColor(red: 0.72, green: 0.72, blue: 0.78, alpha: 0.8))
                e.position = base
                root.addChild(e); hushMists.append((e, Float(j) * 2.1 + Float(c.y) * 9, base))
            }
        }

        // The road you've lit: small warm lights along it, twinkling.
        let pts = roadPoints.prefix(lastOpenRoadIndex + 1).map(\.p)
        for i in 0..<max(0, pts.count - 1) {
            for s in 0..<3 {
                let t = CGFloat(s) / 3
                let p = CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * t, y: pts[i].y + (pts[i + 1].y - pts[i].y) * t)
                let c = uv(p)
                let e = card(glowTex, [0.03, 0.03], tint: UIColor(red: 1, green: 0.82, blue: 0.5, alpha: 0.9))
                e.position = spot(c.x, c.y, lift: 0.01)
                root.addChild(e); pathLights.append((e, Float(i * 3 + s) * 0.7))
            }
        }

        // A beacon of light on each open realm, in its color.
        for r in roadOrder where open.contains(r) {
            let c = uv(r.mapPoint)
            let e = card(glowTex, [0.16, 0.16], tint: UIColor(r.color).withAlphaComponent(0.85))
            e.position = spot(c.x, c.y, lift: 0.03)
            root.addChild(e); beacons.append((e, Float(c.y) * 7))
        }

        // Your Spark, hovering where you are.
        let sparkTex = try await TextureResource(named: "spark-keyed.png")
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
        let w0: Float = 7
        let lim = panLimit(zoom: zoom)
        if CommandLine.arguments.contains("-edgetest") { panTarget = [-(lim.x + 0.06), pan.y] }   // (test: pushed past the left edge)
        let pt = simd_clamp(panTarget, -lim - 0.06, lim + 0.06)
        panVel += (w0 * w0 * (pt - pan) - 2 * w0 * panVel) * dt
        pan += panVel * dt
        zoomVel += (w0 * w0 * (zoomTarget - zoom) - 2 * w0 * zoomVel) * dt
        zoom += zoomVel * dt
        // The dive follows its own slower spring (a smooth, accelerating swoop).
        let wd: Float = 3.6
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
        camera.look(at: pos + SIMD3(0, 0, -1), from: pos, relativeTo: nil)

        // The light of the hour on the whole map.
        if let painting, var comp = painting.model, var m = comp.materials.first as? CustomMaterial {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let hour = hourOverride ?? (Float(comps.hour ?? 18) + Float(comps.minute ?? 0) / 60)
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
