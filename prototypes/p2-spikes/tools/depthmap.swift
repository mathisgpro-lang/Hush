// Depth maps for paintings, locally, with Apple's Depth Anything V2 (Core ML, Apache-2.0). Throwaway P2 tool.
// usage: swift depthmap.swift <model.mlmodelc> <in.png> <out.png> [scale]
// The model takes 518×392 landscape images; tall paintings are processed as overlapping landscape tiles from top
// to bottom, each tile's relative depth is aligned to the previous one on their overlap (least squares a·d + b),
// and the tiles are blended. Output: 8-bit grayscale, white = near, black = far, at `scale` × the input size.
import CoreML
import Vision
import AppKit

let args = CommandLine.arguments
let model = try VNCoreMLModel(for: MLModel(contentsOf: URL(fileURLWithPath: args[1])))
guard let src = NSImage(contentsOfFile: args[2])?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fatalError("can't read \(args[2])") }
let scale = args.count > 4 ? Double(args[4])! : 0.5
let W = Int(Double(src.width) * scale), H = Int(Double(src.height) * scale)

/// Runs the model on one crop and returns its depth resampled to (w, h).
func depth(of crop: CGImage, w: Int, h: Int) -> [Float] {
    let req = VNCoreMLRequest(model: model)
    req.imageCropAndScaleOption = .scaleFill
    try! VNImageRequestHandler(cgImage: crop).perform([req])
    guard let pb = (req.results?.first as? VNPixelBufferObservation)?.pixelBuffer else { fatalError("no depth") }
    CVPixelBufferLockBaseAddress(pb, .readOnly); defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
    let bw = CVPixelBufferGetWidth(pb), bh = CVPixelBufferGetHeight(pb), row = CVPixelBufferGetBytesPerRow(pb)
    let fmt = CVPixelBufferGetPixelFormatType(pb)
    let base = CVPixelBufferGetBaseAddress(pb)!
    func at(_ x: Int, _ y: Int) -> Float {
        switch fmt {
        case kCVPixelFormatType_OneComponent16Half:
            return Float(base.advanced(by: y * row + x * 2).assumingMemoryBound(to: Float16.self).pointee)
        case kCVPixelFormatType_OneComponent32Float:
            return base.advanced(by: y * row + x * 4).assumingMemoryBound(to: Float.self).pointee
        case kCVPixelFormatType_OneComponent8:
            return Float(base.advanced(by: y * row + x).assumingMemoryBound(to: UInt8.self).pointee)
        default: // 32BGRA / 32ARGB: use one color channel
            return Float(base.advanced(by: y * row + x * 4 + 1).assumingMemoryBound(to: UInt8.self).pointee)
        }
    }
    var out = [Float](repeating: 0, count: w * h)
    for y in 0..<h {
        let fy = (Float(y) + 0.5) / Float(h) * Float(bh) - 0.5
        let y0 = max(0, min(bh - 1, Int(floor(fy)))), y1 = min(bh - 1, y0 + 1), ty = max(0, min(1, fy - Float(y0)))
        for x in 0..<w {
            let fx = (Float(x) + 0.5) / Float(w) * Float(bw) - 0.5
            let x0 = max(0, min(bw - 1, Int(floor(fx)))), x1 = min(bw - 1, x0 + 1), tx = max(0, min(1, fx - Float(x0)))
            let a = at(x0, y0) * (1 - tx) + at(x1, y0) * tx
            let b = at(x0, y1) * (1 - tx) + at(x1, y1) * tx
            out[y * w + x] = a * (1 - ty) + b * ty
        }
    }
    return out
}

// Tiles: full width, the model's aspect (392/518), 40% overlap, top to bottom.
let tileH = Int(Double(src.width) * 392.0 / 518.0)
let step = Int(Double(tileH) * 0.6)
var starts: [Int] = []
var s0 = 0
while s0 + tileH < src.height { starts.append(s0); s0 += step }
starts.append(max(0, src.height - tileH))
print("tiles:", starts.count, "tile height:", tileH, "output:", W, "x", H)

var acc = [Float](repeating: 0, count: W * H), wsum = [Float](repeating: 0, count: W * H)
for (i, top) in starts.enumerated() {
    let crop = src.cropping(to: CGRect(x: 0, y: top, width: src.width, height: min(tileH, src.height - top)))!
    let ty0 = Int(Double(top) * scale), th = Int(Double(crop.height) * scale)
    var d = depth(of: crop, w: W, h: th)
    if i > 0 {
        // Fit a·d + b to what's already there on the overlap rows.
        var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0, n = 0.0
        for y in 0..<th where wsum[(ty0 + y) * W] > 0 {
            for x in stride(from: 0, to: W, by: 2) {
                let p = (ty0 + y) * W + x
                let have = Double(acc[p] / wsum[p]), mine = Double(d[y * W + x])
                sx += mine; sy += have; sxx += mine * mine; sxy += mine * have; n += 1
            }
        }
        if n > 10 {
            let a = (n * sxy - sx * sy) / max(1e-9, n * sxx - sx * sx), b = (sy - a * sx) / n
            for k in d.indices { d[k] = Float(a) * d[k] + Float(b) }
        }
    }
    for y in 0..<th {
        // Feather the tile's top and bottom so seams blend.
        let edge = min(Float(y), Float(th - 1 - y)) / (Float(th) * 0.2)
        let w = max(0.02, min(1, edge))
        for x in 0..<W { let p = (ty0 + y) * W + x; acc[p] += d[y * W + x] * w; wsum[p] += w }
    }
}
var depthMap = zip(acc, wsum).map { $1 > 0 ? $0 / $1 : 0 }
let lo = depthMap.min()!, hi = depthMap.max()!
var bytes = depthMap.map { UInt8(max(0, min(255, (($0 - lo) / max(1e-6, hi - lo)) * 255))) }
let ctx = CGContext(data: &bytes, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[3]))
print("wrote", args[3])
