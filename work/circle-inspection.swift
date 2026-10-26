import AppKit
let names=["sanctuary","grove","stillwater","highlands","forge","library","wilds"]
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:700,pixelsHigh:7*180,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
NSColor.black.setFill();NSRect(x:0,y:0,width:700,height:1260).fill()
for (i,n) in names.enumerated(){
 let img=NSImage(contentsOfFile:"prototypes/p2-spikes/SpikeLab/Assets/\(n)-wide-surround.png")!;img.size=NSSize(width:1122,height:1402)
 let y=(6-i)*180
 img.draw(in:NSRect(x:0,y:y,width:700,height:150),from:NSRect(x:211,y:1402-850,width:700,height:150),operation:.sourceOver,fraction:1)
 ("\(n) · x 211…911; y 700…850" as NSString).draw(at:NSPoint(x:5,y:y+155),withAttributes:[.foregroundColor:NSColor.white,.font:NSFont.systemFont(ofSize:14)])
}
NSGraphicsContext.restoreGraphicsState();try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/tmp/hush-circles.png"))
