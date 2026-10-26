from pathlib import Path
p=Path('prototypes/p2-spikes/SpikeLab/S2View.swift');s=p.read_text()
s=s.replace('private var stageCoverage = SIMD2<Float>(1, 1)','private let surround = WorldSurround.load("sanctuary")\n    private var stageCoverage = SIMD2<Float>(1, 1)')
s=s.replace('static let fov: Float = 30','static let fov: Float = 40')
s=s.replace('(composedStage ? Self.fov : Self.paintFov)','(composedStage ? 30 : Self.paintFov)')
s=s.replace('stageCoverage = expandedStage ? [1.8, 1.35] : [1, 1]','stageCoverage = surround?.coverage ?? (expandedStage ? [1.8, 1.35] : [1, 1])')
s=s.replace('var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []','var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], surroundUVs: [SIMD2<Float>] = [], idx: [UInt32] = []',1)
s=s.replace('pos.append(rest * (d / Self.distance)); uvs.append([u, v])','pos.append(rest * (d / Self.distance)); uvs.append([u, v])\n            surroundUVs.append(surround?.uv(u, v) ?? .zero)',1)
s=s.replace('desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)','desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.textureCoordinates1 = .init(surroundUVs); desc.primitives = .triangles(idx)',1)
s=s.replace('if expandedStage {\n                let surround', 'if surround != nil {\n                let texture = try await TextureResource(named: "sanctuary-wide-surround.png")\n                m.ambientOcclusion = .init(texture: .init(texture))\n            } else if expandedStage {\n                let surround',1)
s=s.replace('d == "left" ? -9 : d == "right" ? 9','d.contains("left") ? -9 : d.contains("right") ? 9').replace('d == "up" ? 9 : d == "down" ? -9','d.contains("up") ? 9 : d.contains("down") ? -9')
p.write_text(s)
p=Path('prototypes/p2-spikes/SpikeLab/S3View.swift');s=p.read_text().replace('fov: Float = 30, paintFov','fov: Float = 40, paintFov')
s=s.replace('private var homeShift: Float = 0','private var homeShift: Float = 0\n    @ObservationIgnored private var safePan = SIMD2<Float>(0, 0)\n    @ObservationIgnored private lazy var surround = WorldSurround.load(id)')
s=s.replace('let safe = EdgeSafety.limit(planeW: w, planeH: h,','let coverage = surround?.coverage ?? SIMD2<Float>(1, 1)\n        let safe = EdgeSafety.limit(planeW: w * coverage.x, planeH: h * coverage.y,')
s=s.replace('_ = camH','safePan = safe')
s=s.replace('let (nx, ny) = (wide ? 150 : 72, 162)','let (nx, ny) = (surround != nil ? 180 : wide ? 150 : 72, surround != nil ? 210 : 162)')
s=s.replace('var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], idx: [UInt32] = []','var pos: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = [], surroundUVs: [SIMD2<Float>] = [], idx: [UInt32] = []',1)
s=s.replace('let u = Float(i) / Float(nx), v = Float(j) / Float(ny)\n            pos.append(point(u, v)); uvs.append([u, v])','let u = 0.5 + (Float(i) / Float(nx) - 0.5) * coverage.x\n            let v = 0.5 + (Float(j) / Float(ny) - 0.5) * coverage.y\n            pos.append(point(u, v)); uvs.append([u, v])\n            surroundUVs.append(surround?.uv(u, v) ?? .zero)',1)
s=s.replace('desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.primitives = .triangles(idx)','desc.positions = .init(pos); desc.textureCoordinates = .init(uvs); desc.textureCoordinates1 = .init(surroundUVs); desc.primitives = .triangles(idx)',1)
s=s.replace('m.custom.texture = .init(lanternTex)','if surround != nil {\n                let texture = try await TextureResource(named: "\\(id)-wide-surround.png")\n                m.ambientOcclusion = .init(texture: .init(texture))\n            }\n            m.custom.texture = .init(lanternTex)',1)
s=s.replace('if PixelMode.world && wide, let pm','if surround == nil && PixelMode.world && wide, let pm',1)
s=s.replace('d == "left" ? -9 : d == "right" ? 9','d.contains("left") ? -9 : d.contains("right") ? 9').replace('d == "up" ? 9 : d == "down" ? -9','d.contains("up") ? 9 : d.contains("down") ? -9')
s=s.replace('let pt = simd_clamp(panTarget, -panLimit - EdgeSafety.rubber, panLimit + EdgeSafety.rubber)','if surround != nil {\n            let viewH = 2 * Self.distance * tan(Self.fov / 2 * .pi / 180)\n            panLimit.y = min(viewH * 0.07, max(0, safePan.y - abs(liftNow * viewH)))\n        }\n        let pt = simd_clamp(panTarget, -panLimit - EdgeSafety.rubber, panLimit + EdgeSafety.rubber)',1)
s=s.replace('let rel = camera.transformMatrix(relativeTo: root).inverse * SIMD4<Float>(heroFeet.x, heroFeet.y, heroFeet.z, 1)','let framingFeet = heroFeet + SIMD3<Float>(pan.x, pan.y, 0)\n            let rel = camera.transformMatrix(relativeTo: root).inverse * SIMD4<Float>(framingFeet.x, framingFeet.y, framingFeet.z, 1)',1)
p.write_text(s)
p=Path('prototypes/p2-spikes/SpikeLab/Shell/HomeView.swift');s=p.read_text()
old='''        // One ground anchor in every form; growth rises into the available space, never into the quests/header.
        let feet = bandBottom - 34
        let available = max(48, feet - bandTop - 14)
        let bodyHeight = min(available, h * 0.16 * CGFloat(model.form.growth))'''
new='''        // The wider camera gives scenery breathing room; keep the complete hero centered above the quests.
        let top = bandTop + 14, bottom = bandBottom - 34
        let available = max(48, bottom - top)
        let bodyHeight = min(available, h * 0.16 * CGFloat(model.form.growth)) * 0.70
        let feet = (top + bottom + bodyHeight) * 0.5'''
assert old in s;s=s.replace(old,new);p.write_text(s)
p=Path('prototypes/p2-spikes/SpikeLab/Shaders.metal');s=p.read_text()
old='''    float3 anchor = float3(params.material_constants().base_color_tint().rgb);
    if (anchor.b < 0.5) graded = depthStoneLight'''
new='''    float2 surroundUV = params.geometry().uv1();
    if (surroundUV.x > 0.001 && surroundUV.y > 0.001) {
        float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
        float coverage = smoothstep(-0.05, 0.08, edge);
        if (coverage < 1.0) {
            float3 outer = float3(params.textures().ambient_occlusion().sample(s, surroundUV).rgb);
            if (!s2isPixel(pxTint)) outer = s2look(params.textures().emissive_color(), outer, 0.0, s2moods(hourK * 24.0));
            graded = mix(outer, graded, coverage);
        }
    }
    float3 anchor = float3(params.material_constants().base_color_tint().rgb);
    if (anchor.b < 0.5) graded = depthStoneLight'''
assert old in s;s=s.replace(old,new,1)
s=s.replace('bool expanded = params.material_constants().clearcoat_roughness_scale() > 0.5;','float2 registeredUV = params.geometry().uv1();\n    bool registered = registeredUV.x > 0.001 && registeredUV.y > 0.001;\n    bool expanded = registered || params.material_constants().clearcoat_roughness_scale() > 0.5;',1)
s=s.replace('float3 outer = float3(params.textures().emissive_color().sample(s, outerUV).rgb);','float3 outer = registered\n            ? float3(params.textures().ambient_occlusion().sample(s, registeredUV).rgb)\n            : float3(params.textures().emissive_color().sample(s, outerUV).rgb);',1)
p.write_text(s)
