import AppKit
let names = ["left", "right", "up", "down", "rest"]
let width = 280, height = 630
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * names.count, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor.black.setFill(); NSRect(x:0,y:0,width:width*names.count,height:height).fill()
for (index,name) in names.enumerated() {
 let img = NSImage(contentsOfFile: "docs/design/flame-depth/verification/sanctuary-look/\(name).png")!
 img.draw(in: NSRect(x:index*width,y:0,width:width,height:608))
 (name as NSString).draw(at: NSPoint(x:index*width+10,y:610),withAttributes:[.foregroundColor:NSColor.white,.font:NSFont.systemFont(ofSize:14)])
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/tmp/hush-sanctuary-contact.png"))
