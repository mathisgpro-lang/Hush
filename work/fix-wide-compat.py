from pathlib import Path
p=Path('prototypes/p2-spikes/SpikeLab')
for name in ['S2View.swift','S3View.swift']:
 f=p/name;s=f.read_text().replace(', surroundUVs: [SIMD2<Float>] = []','').replace('            surroundUVs.append(surround?.uv(u, v) ?? .zero)\n','').replace('; desc.textureCoordinates1 = .init(surroundUVs)','')
 if name=='S3View.swift':s=s.replace('.init(named: "groveRestore", in: lib)', '.init(named: surround == nil ? "groveRestore" : "\\(id)WideWorld", in: lib)')
 else:s=s.replace('composedStage ? "stageWorld" : "stoneLive"','composedStage ? (surround == nil ? "stageWorld" : "sanctuaryWideWorld") : "stoneLive"')
 f.write_text(s)
f=p/'Shaders.metal';s=f.read_text()
s=s.replace('[[visible]]\nvoid groveRestore(realitykit::surface_parameters params)','void groveRestoreImpl(realitykit::surface_parameters params, float4 registration)')
s=s.replace('float2 surroundUV = params.geometry().uv1();\n    if (surroundUV.x > 0.001 && surroundUV.y > 0.001)', 'float2 surroundUV = (float2(uv.x, 1.0 - uv.y) - 0.5) * registration.xy + registration.zw;\n    if (registration.x > 0.0)')
s=s.replace('// The light strand an action sends', '[[visible]]\nvoid groveRestore(realitykit::surface_parameters params) { groveRestoreImpl(params, float4(0)); }\n\n// The light strand an action sends')
s=s.replace('[[visible]]\nvoid stageWorld(realitykit::surface_parameters params) {','void stageWorldImpl(realitykit::surface_parameters params, float4 registration) {')
s=s.replace('float2 registeredUV = params.geometry().uv1();\n    bool registered = registeredUV.x > 0.001 && registeredUV.y > 0.001;', 'float2 registeredUV = (tuv - 0.5) * registration.xy + registration.zw;\n    bool registered = registration.x > 0.0;')
s+='\n[[visible]]\nvoid stageWorld(realitykit::surface_parameters params) { stageWorldImpl(params, float4(0)); }\n\n#include "WorldSurroundRegistration.h"\n'
f.write_text(s)
