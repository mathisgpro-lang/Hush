// Step 0, the pipeline probe (P2 plan §B.2): Blender skinned model → USDZ → RealityKit, with
// two blended clips (idle/cheer cut from one timeline), a face texture swap, and a hair geometry modifier, all at once.
import SwiftUI
import RealityKit
import Metal

@MainActor
final class ProbeModel {
    var root: Entity?
    var idle: AnimationResource?
    var cheer: AnimationResource?
    var faceTextures: [TextureResource] = []
    var faceSlot: (entity: ModelEntity, index: Int)?
    var log: [String] = []
    var idleController: AnimationPlaybackController?
    var speed: Float = 1

    // Clip map from PIPELINE.md (30 fps; the timeline starts at frame 1 = 0 s).
    static let idleRange: (Double, Double) = (0, 59.0 / 30)
    static let cheerRange: (Double, Double) = (60.0 / 30, 89.0 / 30)

    func load() async throws -> Entity {
        let entity = try await Entity(named: "probe")
        root = entity
        log.append("animations: \(entity.availableAnimations.count)")

        for (i, a) in entity.availableAnimations.enumerated() {
            log.append(String(format: "anim[%d] %@ duration %.2fs", i, a.name ?? "-", a.definition.duration))
        }
        if let source = entity.availableAnimations.first {
            idle = try AnimationResource.generate(with: AnimationView(
                source: source.definition, name: "idle", repeatMode: .repeat,
                trimStart: Self.idleRange.0, trimEnd: Self.idleRange.1))
            cheer = try AnimationResource.generate(with: AnimationView(
                source: source.definition, name: "cheer",
                trimStart: Self.cheerRange.0, trimEnd: Self.cheerRange.1))
        }

        faceTextures = try await [
            TextureResource(named: "face-0.png"),
            TextureResource(named: "face-1.png"),
        ]
        try applyMaterials(entity)
        return entity
    }

    /// Materials are applied after import (PIPELINE.md step 4). Parts are identified by their export order:
    /// 0 body, 1 hair, 2 face (the imported tint doesn't round-trip reliably, so it's not used).
    private func applyMaterials(_ entity: Entity) throws {
        // The hair shader needs Xcode's Metal Toolchain; without it the probe still tests skinning, clips and the face.
        let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()
        let hairModifier = library.map { CustomMaterial.GeometryModifier(named: "hairSway", in: $0) }
        if hairModifier == nil { log.append("no Metal library: hair shader skipped") }
        for model in Self.models(in: entity) {
            guard var comp = model.model else { continue }
            log.append("\(model.name): \(comp.materials.count) materials")
            for (i, material) in comp.materials.enumerated() {
                guard let pbr = material as? PhysicallyBasedMaterial else { continue }
                if pbr.baseColor.texture != nil {
                    faceSlot = (model, i)
                    var face = UnlitMaterial()
                    face.color = .init(tint: .white, texture: .init(faceTextures[0]))
                    face.blending = .transparent(opacity: 1.0)
                    face.opacityThreshold = 0.5
                    comp.materials[i] = face
                    log.append("  [\(i)] face → unlit texture")
                } else if i == 1, let hairModifier {
                    comp.materials[i] = try CustomMaterial(from: pbr, geometryModifier: hairModifier)
                    log.append("  [\(i)] hair → custom geometry modifier")
                } else {
                    log.append("  [\(i)] body (kept)")
                }
            }
            model.model = comp
        }
    }

    static func green(of color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return g
    }

    static func models(in entity: Entity) -> [ModelEntity] {
        var found: [ModelEntity] = []
        if let m = entity as? ModelEntity { found.append(m) }
        for child in entity.children { found += models(in: child) }
        return found
    }

    func playIdle(transition: TimeInterval = 0.3) {
        guard let root, let idle else { log.append("idle missing"); return }
        let c = root.playAnimation(idle, transitionDuration: transition)
        c.speed = speed
        idleController = c
        log.append("idle playing: \(c.isPlaying)")
    }

    func playCheer() {
        guard let root, let cheer else { log.append("cheer missing"); return }
        let c = root.playAnimation(cheer, transitionDuration: 0.2)
        c.speed = speed
        log.append("cheer playing: \(c.isPlaying)")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds((Self.cheerRange.1 - Self.cheerRange.0) / Double(self.speed) - 0.15))
            self.playIdle()
        }
    }

    func setSpeed(_ s: Float) { speed = s; idleController?.speed = s }

    /// Body glow from mood, tinted by the season (slot 0 = body).
    func setBodyGlow(intensity: Float, tint: UIColor) {
        guard let root else { return }
        for model in Self.models(in: root) {
            guard var comp = model.model, !comp.materials.isEmpty else { continue }
            if var body = comp.materials[0] as? PhysicallyBasedMaterial {
                body.emissiveColor = .init(color: tint)
                body.emissiveIntensity = intensity
                comp.materials[0] = body
                model.model = comp
            }
        }
    }

    func setFace(_ index: Int) {
        guard let slot = faceSlot, var comp = slot.entity.model,
              var face = comp.materials[slot.index] as? UnlitMaterial else { return }
        face.color = .init(tint: .white, texture: .init(faceTextures[index]))
        comp.materials[slot.index] = face
        slot.entity.model = comp
    }
}

struct ProbeView: View {
    @State private var meter = FrameMeter()
    @State private var probe = ProbeModel()
    @State private var log: [String] = []
    @State private var failure: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.08, green: 0.06, blue: 0.1).ignoresSafeArea()
            RealityView { content in
                content.camera = .virtual
                do {
                    let flame = try await probe.load()
                    let b = flame.visualBounds(relativeTo: nil)
                    probe.log.append(String(format: "bounds min %.3f %.3f %.3f max %.3f %.3f %.3f",
                                            b.min.x, b.min.y, b.min.z, b.max.x, b.max.y, b.max.z))
                    // Center the model and frame it at gameplay distance whatever unit scale the export used.
                    let height = max(b.extents.y, 0.001)
                    flame.scale = .init(repeating: 0.3 / height)
                    flame.position = -b.center * (0.3 / height)
                    content.add(flame)

                    let camera = PerspectiveCamera()
                    camera.camera.fieldOfViewInDegrees = 40
                    camera.look(at: [0, 0, 0], from: [0, 0.05, 0.9], relativeTo: nil)
                    content.add(camera)

                    let sun = DirectionalLight()
                    sun.light.intensity = 3000
                    sun.look(at: .zero, from: [0.4, 0.8, 0.6], relativeTo: nil)
                    content.add(sun)

                    probe.playIdle(transition: 0)
                    if CommandLine.arguments.contains("-closedeyes") { probe.setFace(1) }
                    if CommandLine.arguments.contains("-autocheer") {
                        Task { @MainActor in
                            while true {
                                try? await Task.sleep(for: .seconds(3))
                                probe.playCheer()
                                log = probe.log
                            }
                        }
                    }
                } catch {
                    failure = "\(error)"
                }
                log = probe.log
            }
            VStack(spacing: 8) {
                HUDView(meter: meter)
                if let failure { Text(failure).font(.caption).foregroundStyle(.red) }
                Spacer()
                ScrollView { Text(log.reversed().joined(separator: "\n")).font(.system(size: 10, design: .monospaced)) }
                    .frame(maxHeight: 110).foregroundStyle(.secondary)
                HStack {
                    Button("Cheer") { probe.playCheer() }
                    Button("Blink") {
                        probe.setFace(1)
                        Task { try? await Task.sleep(for: .milliseconds(160)); probe.setFace(0) }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Pipeline probe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { meter.start() }
        .onDisappear { meter.stop() }
    }
}
