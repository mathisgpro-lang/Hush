// Import an image-generated 3x2 RGBA atlas without recoloring, quantizing or resampling its artwork.
// swift tools/import_flame_atlas.swift <atlas.png> [keyed|blink|happy]
import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 2,
      let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let atlas = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("Missing PNG atlas") }
let expression = args.count > 2 ? args[2] : "keyed"
let w = atlas.width, h = atlas.height
let stride = w * 4
var pixels = [UInt8](repeating: 0, count: stride * h)
let context = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: stride,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.draw(atlas, in: CGRect(x: 0, y: 0, width: w, height: h))
let transparent = pixels.enumerated().filter { $0.offset % 4 == 3 && $0.element < 8 }.count
guard Double(transparent) / Double(w * h) > 0.25 else { fatalError("Atlas has an opaque background; request alpha extraction") }
let names = ["spark", "flame", "blaze", "kindled", "radiant", "beyond"]
// Image-generated grids can be a little uneven. Find the transparent gutter instead of cutting a flame tip.
let split = (Int(Double(h) * 0.44)...Int(Double(h) * 0.54)).min { a, b in
    (0..<w).filter { pixels[a * stride + $0 * 4 + 3] > 12 }.count <
    (0..<w).filter { pixels[b * stride + $0 * 4 + 3] > 12 }.count
}!
for (i, name) in names.enumerated() {
    let x0 = i % 3 * w / 3, x1 = (i % 3 + 1) * w / 3
    let y0 = i < 3 ? 0 : split, y1 = i < 3 ? split : h
    var left = x1, right = x0, top = y1, bottom = y0
    for y in y0..<y1 { for x in x0..<x1 where pixels[y * stride + x * 4 + 3] > 12 {
        left = min(left, x); right = max(right, x); top = min(top, y); bottom = max(bottom, y)
    } }
    guard left < right && top < bottom else { fatalError("Empty cell: \(name)") }
    left = max(x0, left - 3); top = max(y0, top - 3)
    right = min(x1 - 1, right + 3); bottom = min(y1 - 1, bottom + 3)
    let crop = atlas.cropping(to: CGRect(x: left, y: top, width: right-left+1, height: bottom-top+1))!
    let path = "SpikeLab/Assets/depth-\(name)-\(expression).png"
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, crop, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Couldn't save \(path)") }
    print("\(name): \(crop.width)x\(crop.height)")
}
