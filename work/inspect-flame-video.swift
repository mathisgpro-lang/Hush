import AVFoundation
import AppKit
let asset=AVURLAsset(url:URL(fileURLWithPath:"/Users/mathis/Downloads/IMG_8546.MOV"))
let duration=try await asset.load(.duration).seconds
let tracks=try await asset.loadTracks(withMediaType:.video)
if let track=tracks.first { print("duration",duration,"size",try await track.load(.naturalSize),"fps",try await track.load(.nominalFrameRate)) }
let gen=AVAssetImageGenerator(asset:asset);gen.appliesPreferredTrackTransform=true;gen.maximumSize=CGSize(width:360,height:600)
let count=12, cw=280, ch=510
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:cw*4,pixelsHigh:ch*3,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep);NSColor.black.setFill();NSRect(x:0,y:0,width:cw*4,height:ch*3).fill()
for i in 0..<count {
 let t=min(duration-0.05,Double(i)*duration/Double(count))
 let result=try await gen.image(at:CMTime(seconds:t,preferredTimescale:600));let cg=result.image
 let image=NSImage(cgImage:cg,size:NSSize(width:cg.width,height:cg.height));let k=min(Double(cw)/Double(cg.width),Double(ch-25)/Double(cg.height))
 let x=(i%4)*cw,y=(2-i/4)*ch
 image.draw(in:NSRect(x:Double(x)+(Double(cw)-Double(cg.width)*k)/2,y:Double(y),width:Double(cg.width)*k,height:Double(cg.height)*k))
 (String(format:"%.2fs",t) as NSString).draw(at:NSPoint(x:x+5,y:y+ch-22),withAttributes:[.foregroundColor:NSColor.white,.font:NSFont.systemFont(ofSize:14)])
}
NSGraphicsContext.restoreGraphicsState();try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/tmp/hush-flame-video-contact.png"))
