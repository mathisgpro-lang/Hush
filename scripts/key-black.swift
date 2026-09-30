// Turns near-black pixels transparent with a soft ramp (for Codex art rendered on pure black).
// Usage: swift scripts/key-black.swift input.png output.png [low=0.06] [high=0.16]
import AppKit
import CoreImage

let args = CommandLine.arguments
guard args.count >= 3, let input = CIImage(contentsOf: URL(fileURLWithPath: args[1])) else {
    print("usage: key-black.swift in.png out.png [low] [high]"); exit(1)
}
let low = args.count > 3 ? Double(args[3])! : 0.06
let high = args.count > 4 ? Double(args[4])! : 0.16
let kernelSource = """
kernel vec4 keyBlack(__sample s, float lo, float hi) {
    float l = max(s.r, max(s.g, s.b));
    float a = smoothstep(lo, hi, l);
    return vec4(s.rgb * a, a);
}
"""
let kernel = CIColorKernel(source: kernelSource)!
let output = kernel.apply(extent: input.extent, arguments: [input, low, high])!
let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
try! ctx.writePNGRepresentation(of: output, to: URL(fileURLWithPath: args[2]), format: .RGBA8, colorSpace: cs)
print("wrote \(args[2])")
