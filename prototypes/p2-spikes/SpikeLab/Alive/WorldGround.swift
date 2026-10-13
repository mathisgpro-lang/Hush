// The ground below a pixel world (decision 160). With the world raised as a stage above the quests (157–158), the
// painting stopped short of the bottom of the screen. Codex painted every world taller; tools/build_ext.py cuts out
// the part below the painting, on its pixel grid and in its palette. This draws it right under the painting, as a
// flat continuation of the painting's bottom edge (same depth there, so the seam can't open when the camera moves),
// with the painting's own shader: its water ripples and its waterfalls fall like the rest.
import RealityKit
import UIKit

enum WorldGround {
    /// The strip under a painting, or nil if this world has none yet.
    /// - `asset`: the painting's name without "-paint.png" (its strip is "<asset>-ext.png", its mask "<asset>-ext-<mask>.png").
    /// - `paintTexH`: the painting texture's height (texels), so the strip keeps the painting's scale.
    /// - `width`/`height`: the painting plane's size; `bottomDistance(u)`: how far the painting's bottom edge is at u.
    @MainActor static func make(asset: String, mask: String, from painting: CustomMaterial, paintTexH: Int,
                                width w: Float, height h: Float, distance: Float,
                                bottomDistance: (Float) -> Float) async -> ModelEntity? {
        guard UIImage(named: "\(asset)-ext.png") != nil,
              let tex = try? await TextureResource(named: "\(asset)-ext.png"),
              let maskTex = try? await TextureResource(named: "\(asset)-ext-\(mask).png", options: .init(semantic: .raw))
        else { return nil }
        let e = Float(tex.height) / Float(paintTexH)          // its height, as a share of the painting's
        let (nx, ny) = (48, max(4, Int(e * 40)))
        var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...ny { for i in 0...nx {
            let u = Float(i) / Float(nx), t = Float(j) / Float(ny)          // t: 0 at its bottom, 1 at the seam
            let v = (t - 1) * e                                           // below the painting (v < 0)
            let rest = SIMD3<Float>((u - 0.5) * w, (v - 0.5) * h, -distance)
            pos.append(rest * (bottomDistance(u) / distance)); uvs.append([u, t])
        } }
        for j in 0..<ny { for i in 0..<nx {
            let a = UInt32(j * (nx + 1) + i), b = a + 1, c = a + UInt32(nx + 1), d = c + 1
            idx += [a, b, d, a, d, c]
        } }
        var desc = MeshDescriptor(name: "ground")
        desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)
        var m = painting
        m.baseColor = .init(tint: .white, texture: .init(tex))
        m.custom.texture = .init(maskTex)
        m.normal = .init(texture: nil)                         // no life map down here
        m.clearcoatRoughness = .init(floatLiteral: 0)
        guard let mesh = try? MeshResource.generate(from: [desc]) else { return nil }
        return ModelEntity(mesh: mesh, materials: [m])
    }

    /// Mirrors the painting's live values (wind, hour, Vitality…) onto the strip, keeping its own textures and pixel grid.
    /// `customValue` lets a scene switch off effects tied to the painting's own places (the Flame's light on the circle).
    @MainActor static func follow(_ ground: ModelEntity?, _ m: CustomMaterial, customValue: SIMD4<Float>? = nil, specular: Float? = nil) {
        guard let ground, var comp = ground.model, var g = comp.materials.first as? CustomMaterial else { return }
        g.custom.value = customValue ?? m.custom.value
        g.roughness = m.roughness; g.metallic = m.metallic; g.clearcoat = m.clearcoat
        g.specular = specular.map { .init(floatLiteral: $0) } ?? m.specular
        comp.materials = [g]; ground.model = comp
    }
}
