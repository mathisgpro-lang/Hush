import AppKit
let base = "docs/design/flame-depth/verification/wider-worlds/"
let names = Array(CommandLine.arguments.dropFirst())
let width = 240, height = 550
let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width*names.count,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
NSColor.black.setFill();NSRect(x:0,y:0,width:width*names.count,height:height).fill()
for (i,n) in names.enumerated() {
 if let img=NSImage(contentsOfFile:base+n+".png") {img.draw(in:NSRect(x:i*width,y:0,width:width,height:524))}
 (n as NSString).draw(at:NSPoint(x:i*width+4,y:530),withAttributes:[.foregroundColor:NSColor.white,.font:NSFont.systemFont(ofSize:12)])
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/tmp/hush-wide-contact.png"))
