from pathlib import Path
import json
p=Path('prototypes/p2-spikes/SpikeLab')
centers={'sanctuary':(556,718),'grove':(534,773),'stillwater':(542,800),'highlands':(534,761),'forge':(562,813),'library':(551,742),'wilds':(532,754)}
for name,(x,y) in centers.items():
 for f in [p/'Assets'/(name+'-wide-surround.json'),Path('docs/design/flame-depth/wider-worlds/surrounds')/(name+'.json')]:
  d=json.loads(f.read_text());d['circle']=[x/1122,y/1402];f.write_text(json.dumps(d,indent=2)+'\n')
f=p/'Alive/WorldSurround.swift';s=f.read_text().replace('    let center: [Float]','    let center: [Float]\n    let circle: [Float]?')
s=s.replace('    func uv(','''    var circleUV: SIMD2<Float>? {
        guard let circle, circle.count == 2 else { return nil }
        return [0.5 + (circle[0] - center[0]) / scale[0], 0.5 - (circle[1] - center[1]) / scale[1]]
    }

    func uv(''');f.write_text(s)
f=p/'S2View.swift';s=f.read_text().replace('        if composedStage { return [0.5, 0.515] }','        if let calibrated = surround?.circleUV { return calibrated }\n        if composedStage { return [0.5, 0.515] }');s=s.replace('feet + SIMD3(0, (PixelMode.world ? 0.0 : 0.09) * scale, 0)','feet + SIMD3(0, (composedStage || PixelMode.world ? 0.0 : 0.09) * scale, 0)');f.write_text(s)
f=p/'S3View.swift';s=f.read_text().replace('        if let img = UIImage(named: wide ?', '        if let calibrated = surround?.circleUV { circleUV = calibrated }\n        if let img = UIImage(named: wide ?')
s=s.replace('homeShift = (hx(0.5) - 0.5) * w','homeShift = (hx(circleUV.x) - 0.5) * w')
s=s.replace('if let url = Bundle.main.url(forResource: "\\(id)-floaters"','if surround == nil, let url = Bundle.main.url(forResource: "\\(id)-floaters"')
s=s.replace('circle + SIMD3(0, (PixelMode.world ? 0.0 : 0.09) * heroScale, 0)','circle + SIMD3(0, (surround != nil || PixelMode.world ? 0.0 : 0.09) * heroScale, 0)');f.write_text(s)
f=p/'Alive/HeroRig.swift';s=f.read_text()
helper='''    /// Visible foot contact, measured from the opaque bottom band of each delivered sprite.
    /// Growth changes around this point, so switching forms cannot move the feet off the world anchor.
    private func spriteOffset(aspect: Float) -> SIMD3<Float> {
        guard dimensional else { return [0, -footInset * 0.27, 0] }
        let anchors: [String: SIMD2<Float>] = [
            "depth-spark": [0.50741, 0.98246], "depth-flame": [0.58027, 0.99362],
            "depth-blaze": [0.50242, 0.99793], "depth-kindled": [0.54566, 0.99022],
            "depth-radiant": [0.58559, 0.99025], "depth-beyond": [0.46848, 0.99018]]
        let a = anchors[base] ?? [0.5, 1]
        return [(0.5 - a.x) * 0.27 * growth * aspect, -(1 - a.y) * 0.27 * growth, 0]
    }

'''
s=s.replace('    func build() async throws {',helper+'    func build() async throws {')
s=s.replace('e.position = [0, dimensional ? -0.002 : -footInset * h, 0]','e.position = spriteOffset(aspect: Float(tex.width) / Float(tex.height))')
s=s.replace('            comp.mesh = mesh\n','            comp.mesh = mesh\n            if e === hero { e.position = spriteOffset(aspect: Float(tex.width) / Float(tex.height)) }\n');f.write_text(s)
