#!/usr/bin/env swift
import AppKit
import CryptoKit

struct Language: Decodable { let ascLocale: String }
struct Shot: Decodable { let id: String; let screens: [String]; let captions: [String: String] }
struct Plan: Decodable { let version: String; let languages: [String: Language]; let shots: [Shot] }
struct Capture: Decodable { let version: String; let language: String; let sha256: [String: String] }
enum Failure: Error, CustomStringConvertible {
    case message(String)
    var description: String { switch self { case .message(let s): return s } }
}
let fm = FileManager.default
let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let repo = scriptURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let plan = try JSONDecoder().decode(Plan.self, from: Data(contentsOf: scriptURL.deletingLastPathComponent().appendingPathComponent("plan.json")))
var args = Array(CommandLine.arguments.dropFirst())
func option(_ name: String, _ fallback: String) throws -> String {
    guard let i = args.firstIndex(of: name) else { return fallback }
    guard i + 1 < args.count else { throw Failure.message("Missing value for \(name)") }
    let value = args[i+1]; args.removeSubrange(i...i+1); return value
}
let requestedDevice = try option("--device", "iphone")
let device = ["iphone":"iphone-6.7", "ipad":"ipad-12.9"][requestedDevice] ?? requestedDevice
guard ["iphone-6.7", "ipad-12.9"].contains(device) else { throw Failure.message("Unsupported device \(device)") }
let rawRoot = URL(fileURLWithPath: try option("--raw-root", repo.appendingPathComponent("screenshots/v1.2.0/raw").path))
let outputRoot = URL(fileURLWithPath: try option("--output-root", repo.appendingPathComponent("screenshots/v1.2.0").path))
let languages = try option("--languages", "en,no").split(separator: ",").map(String.init)
let sample = try option("--sample", "")
let secondary = try option("--secondary", "")
let sampleCaption = try option("--caption", "Daily missions motivate")
let sampleOutput = try option("--output", "/tmp/geni-compose-test/03.png")
guard args.isEmpty else { throw Failure.message("Unknown arguments: \(args)") }
let ipad = device == "ipad-12.9"
let width = ipad ? 2048 : 1290
let height = ipad ? 2732 : 2796
let W = CGFloat(width), H = CGFloat(height)
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r,g,b,1])!
}
func rect(_ x: CGFloat, _ top: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x:x,y:H-top-h,width:w,height:h)
}
func rounded(_ r: CGRect, _ radius: CGFloat, _ color: CGColor, _ ctx: CGContext) {
    ctx.addPath(CGPath(roundedRect:r,cornerWidth:radius,cornerHeight:radius,transform:nil))
    ctx.setFillColor(color); ctx.fillPath()
}
func load(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source,0,nil) else {
        throw Failure.message("Cannot read \(url.path)")
    }
    let valid = ipad ? [(2048,2732),(2064,2752)] : [(1206,2622)]
    guard valid.contains(where: { image.width == $0.0 && image.height == $0.1 }) else {
        throw Failure.message("\(url.lastPathComponent): expected full-resolution \(device) raw capture, got \(image.width)x\(image.height)")
    }
    return image
}
func compose(_ images: [CGImage], caption: String, output: URL) throws {
    guard (1...2).contains(images.count) else { throw Failure.message("Use one or two screens per shot") }
    // RGB, with no PNG alpha channel (required by ASC).
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    // Sampled at x=10, y=0/2795 from the old EN screenshot-2, converted to sRGB.
    let gradient = CGGradient(colorsSpace:space,colors:[rgb(0.26476,0.79293,0.99787),rgb(0,0.92223,0.99776)] as CFArray,locations:[0,1])!
    ctx.drawLinearGradient(gradient,start:CGPoint(x:0,y:H),end:CGPoint(x:0,y:0),options:[])
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext:ctx,flipped:false)
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center; paragraph.lineBreakMode = .byWordWrapping
    let base = NSFont.systemFont(ofSize:ipad ? 112 : 110,weight:.bold)
    let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    var font = NSFont(descriptor:descriptor,size:base.pointSize)!
    let text = caption as NSString
    let captionWidth = W - (ipad ? 180 : 110)
    func attributes(_ font: NSFont) -> [NSAttributedString.Key:Any] {
        [.font:font,.foregroundColor:NSColor.white,.paragraphStyle:paragraph,.kern:-2]
    }
    // Old shots use one or two centered lines. Fit those lines without clipping NO text.
    var bounds = text.boundingRect(with:CGSize(width:captionWidth,height:500),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attributes(font))
    while bounds.height > 270 && font.pointSize > 76 {
        font = NSFont(descriptor:descriptor,size:font.pointSize-2)!
        bounds = text.boundingRect(with:CGSize(width:captionWidth,height:500),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attributes(font))
    }
    text.draw(with:rect((W-captionWidth)/2,ipad ? 205 : 200,captionWidth,280),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attributes(font))
    NSGraphicsContext.restoreGraphicsState()

    let dual = images.count == 2
    for (i,image) in images.enumerated() {
        let bezel: CGFloat = ipad ? (dual ? 16 : 24) : (dual ? 12 : 19)
        let maxWidth = dual ? (W-120)/2 : (ipad ? 1610 : 930)
        let maxHeight: CGFloat = ipad ? 2090 : 1990
        let ratio = CGFloat(image.height)/CGFloat(image.width)
        let screenW = min(maxWidth-2*bezel,(maxHeight-2*bezel)/ratio)
        let screenH = screenW*ratio
        let frameW = screenW+bezel*2, frameH = screenH+bezel*2
        let x = dual ? (W-frameW*2-36)/2+CGFloat(i)*(frameW+36) : (W-frameW)/2
        let top = (ipad ? 450.0 : 520.0) + (maxHeight-frameH)/2
        let outer = rect(x,top,frameW,frameH)
        let radius: CGFloat = ipad ? 55 : frameW*0.15
        ctx.saveGState()
        ctx.setShadow(offset:CGSize(width:0,height:-12),blur:22,color:rgb(0.04,0.25,0.32).copy(alpha:0.35))
        rounded(outer,radius,rgb(0.20,0.21,0.22),ctx)
        ctx.restoreGState()
        rounded(outer.insetBy(dx:3,dy:3),radius-3,rgb(0.65,0.66,0.65),ctx)
        // Old iPad artwork has a quiet silver/white rim, without an island or phone buttons.
        rounded(outer.insetBy(dx:7,dy:7),radius-7,ipad ? rgb(0.96,0.96,0.95) : rgb(0.07,0.08,0.09),ctx)
        let screen = rect(x+bezel,top+bezel,screenW,screenH)
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect:screen,cornerWidth:max(8,radius-bezel),cornerHeight:max(8,radius-bezel),transform:nil)); ctx.clip()
        ctx.draw(image,in:screen)
        ctx.restoreGState()
        if !ipad {
            // Raw simctl captures omit hardware; place the island in the status-bar safe area.
            let scale = screenW/CGFloat(image.width)
            rounded(rect(x+bezel+screenW/2-180*scale,top+bezel+33*scale,360*scale,105*scale),52.5*scale,CGColor(gray:0,alpha:1),ctx)
            // Quiet side-button details stay outside the visible display.
            rounded(rect(x-4,top+frameH*0.19,5,frameH*0.055),2,rgb(0.4,0.41,0.42),ctx)
            rounded(rect(x+frameW-1,top+frameH*0.28,5,frameH*0.075),2,rgb(0.4,0.41,0.42),ctx)
        }
    }
    try fm.createDirectory(at:output.deletingLastPathComponent(),withIntermediateDirectories:true)
    let rep = NSBitmapImageRep(cgImage:ctx.makeImage()!)
    guard let data = rep.representation(using:.png,properties:[:]) else { throw Failure.message("PNG encoding failed") }
    try data.write(to:output,options:.atomic)
    print(output.path)
}
if !sample.isEmpty {
    let urls = [sample,secondary].filter{ !$0.isEmpty }.map{URL(fileURLWithPath:$0)}
    try compose(urls.map(load),caption:sampleCaption,output:URL(fileURLWithPath:sampleOutput))
} else {
    // Preflight every raw file before producing any deliverable. Samples never get a receipt.
    var captures: [String:[String:CGImage]] = [:]
    for lang in languages {
        guard plan.languages[lang] != nil else { throw Failure.message("Unknown language \(lang)") }
        let dir = rawRoot.appendingPathComponent("\(device)/\(lang)")
        let receipt = try JSONDecoder().decode(Capture.self,from:Data(contentsOf:dir.appendingPathComponent(".capture.json")))
        guard receipt.version == plan.version && receipt.language == lang else { throw Failure.message("Wrong capture receipt for \(lang)") }
        var images: [String:CGImage] = [:]
        for screen in Set(plan.shots.flatMap(\.screens)) {
            let file = dir.appendingPathComponent("\(screen).png")
            let hash = SHA256.hash(data:try Data(contentsOf:file)).map{String(format:"%02x",$0)}.joined()
            guard hash == receipt.sha256[screen] else { throw Failure.message("Stale or changed capture: \(file.path)") }
            images[screen] = try load(file)
        }
        captures[lang] = images
    }
    for lang in languages {
        let dir = outputRoot.appendingPathComponent("\(device)/\(lang)")
        try fm.createDirectory(at:dir,withIntermediateDirectories:true)
        let receiptURL = dir.appendingPathComponent(".composed.json")
        if fm.fileExists(atPath:receiptURL.path) { try fm.removeItem(at:receiptURL) }
        var hashes: [String:String] = [:]
        for shot in plan.shots {
            let output = dir.appendingPathComponent("\(shot.id).png")
            try compose(shot.screens.map{captures[lang]![$0]!},caption:shot.captions[lang]!,output:output)
            hashes[output.lastPathComponent] = SHA256.hash(data:try Data(contentsOf:output)).map{String(format:"%02x",$0)}.joined()
        }
        let receipt: [String:Any] = ["version":plan.version,"language":lang,"device":device,"sha256":hashes]
        try JSONSerialization.data(withJSONObject:receipt,options:[.prettyPrinted,.sortedKeys]).write(to:receiptURL,options:.atomic)
    }
}
