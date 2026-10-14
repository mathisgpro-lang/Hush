// Derive a lightweight runtime motion mask from the approved stage; never recolor its painting.
// Run from prototypes/p2-spikes: swift tools/build_stage_mask.swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

let path = "SpikeLab/Assets/stage-home"
let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path + "-paint.png") as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let w = image.width / 4, h = image.height / 4
var pixels = [UInt8](repeating: 0, count: w * h * 4)
let space = CGColorSpaceCreateDeviceRGB()
let info = CGImageAlphaInfo.premultipliedLast.rawValue
let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space, bitmapInfo: info)!
ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
var mask = [UInt8](repeating: 0, count: pixels.count)
for y in 0..<h { for x in 0..<w {
    let i = (y * w + x) * 4
    let r = Float(pixels[i]) / 255, g = Float(pixels[i+1]) / 255, b = Float(pixels[i+2]) / 255
    let top = Float(y) / Float(h)
    let water = top < 0.42 && b > r * 1.15 && g > r * 1.12 && b > 0.35
    let fire = top > 0.2 && top < 0.42 && r > 0.93 && g > 0.63 && b < 0.38
    mask[i] = water ? 255 : 0
    mask[i+1] = water && g > 0.7 ? 255 : 0
    mask[i+2] = fire ? 255 : 0
    mask[i+3] = 255
} }
let out = CGContext(data: &mask, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space, bitmapInfo: info)!.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path + "-motion.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, out, nil)
precondition(CGImageDestinationFinalize(dest))
print("Stage motion mask: \(w)x\(h)")
