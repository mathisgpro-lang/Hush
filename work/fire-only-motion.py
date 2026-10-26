from pathlib import Path
p=Path('prototypes/p2-spikes/SpikeLab')
f=p/'Alive/HeroRig.swift';s=f.read_text().replace('        body.step(dt: dt)','        if !dimensional { body.step(dt: dt) }')
s=s.replace('walkPivot.transform.translation = [stationary ? 0 : body.x, 0, 0]','walkPivot.transform.translation = [dimensional || stationary ? 0 : body.x, 0, 0]')
s=s.replace('dimensional ? (floating ? 0.016 + 0.005 * sin(hoverTime * 1.5) + 0.002 * sin(hoverTime * 0.63) : 0)', 'dimensional ? 0')
s=s.replace('bodyPivot.transform = Transform(scale: [body.scaleX, body.scaleY, 1],','bodyPivot.transform = dimensional ? Transform.identity : Transform(scale: [body.scaleX, body.scaleY, 1],')
s=s.replace('let k = (dimensional ? sqrt(growth) : 1) * (1 - max(0, body.y + hover) * 3)','let k = dimensional ? sqrt(growth) : (1 - max(0, body.y + hover) * 3)')
s=s.replace('let drag = body.hairDrag + SIMD2(wind * 0.012, 0)','let drag = dimensional ? SIMD2<Float>.zero : body.hairDrag + SIMD2(wind * 0.012, 0)')
s=s.replace('    func perform(_ idle: IdleBehavior) {','    func perform(_ idle: IdleBehavior) {\n        guard !dimensional else { return }')
s=s.replace('    func react(_ reaction: Reaction) {','    func react(_ reaction: Reaction) {\n        if dimensional { smile(0.6); return }')
s=s.replace('    func look(at point: SIMD2<Float>?) {','    func look(at point: SIMD2<Float>?) {\n        guard !dimensional else { return }')
s=s.replace('func lean(_ tilt: SIMD2<Float>) { leanPivot.orientation', 'func lean(_ tilt: SIMD2<Float>) { guard !dimensional else { return }; leanPivot.orientation')
f.write_text(s)
f=p/'S2View.swift';s=f.read_text().replace('        if CommandLine.arguments.contains("-camtest") {','        if surround != nil { offset = .zero } // the world rests still; only deliberate look-around moves it\n        if CommandLine.arguments.contains("-camtest") {');f.write_text(s)
f=p/'S3View.swift';s=f.read_text().replace('let offset = SIMD3<Float>(drift.x, drift.y * 0.6, 0)','let offset = surround != nil ? SIMD3<Float>.zero : SIMD3<Float>(drift.x, drift.y * 0.6, 0)');f.write_text(s)
f=p/'Shell/LiveIcon.swift';s=f.read_text().replace('.scaleEffect(x: kind == .flame ? (flicker ? 0.97 : 1.02) : 1,\n                             y: kind == .flame ? (flicker ? 1.06 : 0.98) : (kind == .satchel && idle ? 1.035 : 1), anchor: .bottom)', '.scaleEffect(x: 1, y: kind == .satchel && idle ? 1.035 : 1, anchor: .bottom)')
s=s.replace('trigger: taps)', 'trigger: kind == .flame ? 0 : taps)');f.write_text(s)
f=p/'Shaders.metal';s=f.read_text();a=s.index('void depthLive(');b=s.index('\n[[visible]]\nvoid depthFire',a)
s=s[:a]+'''void depthLive(realitykit::geometry_parameters params) {
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    // Fire travels upward through the tips. Feet, face and torso never translate, scale or bounce.
    float crown = smoothstep(0.70, 0.98, uv.y);
    float fringe = smoothstep(0.30, 0.48, abs(uv.x - 0.5)) * smoothstep(0.15, 0.40, uv.y);
    float fire = max(crown, fringe * 0.75);
    float2 q = float2(uv.x * 11.0, uv.y * 8.0 - t * 1.35);
    float curl = (s2noise(q) - 0.5) + 0.4 * (s2noise(q * 2.1 + float2(3.7, -t * 0.55)) - 0.5);
    float lift = s2noise(q + float2(6.1, -t * 0.8)) - 0.5;
    params.geometry().set_model_position_offset(float3(curl * 0.010 * fire, lift * 0.006 * fire, 0));
}
''' +s[b:]
a=s.index('void depthFire(');b=s.index('\n//',a)
old=s[a:b]
old=old.replace('    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y));\n','')
old=old.replace('float edge = smoothstep(0.2, 0.46, abs(uv.x - 0.5));','float edge = smoothstep(0.30, 0.48, abs(uv.x - 0.5));')
old=old.replace('float fire = max(smoothstep(0.72, 1.0, uv.y), edge) * (1.0 - face);','''float fire = max(smoothstep(0.68, 0.95, uv.y), edge) * (1.0 - face) * smoothstep(0.12, 0.30, uv.y);
    float2 q = float2(uv.x * 16.0, uv.y * 12.0 - t * 2.1);
    float rising = s2noise(q), fine = s2noise(q * 2.3 + float2(5.0, -t * 0.9));
    float2 heat = float2((rising - 0.5) * 0.014, (fine - 0.5) * 0.009) * fire;
    half4 col = params.textures().base_color().sample(s, float2(uv.x + heat.x, 1.0 - uv.y - heat.y));''')
old=old.replace('float pulse = 1.0 + 0.025 * sin(t * 2.3) + 0.018 * sin(t * 5.1 + uv.y * 15.0) * fire;', 'float pulse = 1.0 + ((rising - 0.5) * 0.16 + (fine - 0.5) * 0.07) * fire;')
s=s[:a]+old+s[b:];f.write_text(s)
