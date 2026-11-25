// Draws the Sample Space app icon and writes every macOS size into the asset catalog.
//   swift scripts/make_app_icon.swift
// A survey ship's view: deep space, a nebula glow, a ringed planet, and a normal curve with
// its tail shaded, because every planet in the game is a piece of statistics.
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let set = root.appendingPathComponent("SampleSpace/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let s = size / 1024
    ctx.scaleBy(x: s, y: s)

    // macOS icon grid: an 824-point rounded square centred on the 1024 canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0, 0, 0, 0.45).cgColor)
    ctx.addPath(shape); ctx.setFillColor(color(0.03, 0.04, 0.11).cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(shape); ctx.clip()

    let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [color(0.10, 0.05, 0.22).cgColor, color(0.02, 0.03, 0.10).cgColor] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(space, start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
    func glow(_ c: CGPoint, _ r: CGFloat, _ col: NSColor) {
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [col.cgColor, col.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }
    glow(CGPoint(x: 300, y: 720), 420, color(0.45, 0.22, 0.75, 0.55))
    glow(CGPoint(x: 780, y: 300), 380, color(0.10, 0.55, 0.65, 0.45))

    // Stars (fixed pattern)
    var seed: UInt64 = 2026
    func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 33) / CGFloat(1 << 31) }
    for _ in 0..<70 {
        let p = CGPoint(x: 100 + rnd() * 824, y: 100 + rnd() * 824)
        let r = 2 + rnd() * 5
        ctx.setFillColor(color(1, 1, 1, 0.35 + rnd() * 0.6).cgColor)
        ctx.fillEllipse(in: CGRect(x: p.x - r / 2, y: p.y - r / 2, width: r, height: r))
    }

    // Normal curve across the lower half, upper tail shaded gold.
    let base: CGFloat = 250, height: CGFloat = 330, mid: CGFloat = 512, spread: CGFloat = 120
    func y(_ x: CGFloat) -> CGFloat { base + height * exp(-pow((x - mid) / spread, 2) / 2) }
    let curve = CGMutablePath()
    curve.move(to: CGPoint(x: 140, y: y(140)))
    for x in stride(from: 140, through: 884, by: 4) { curve.addLine(to: CGPoint(x: CGFloat(x), y: y(CGFloat(x)))) }
    let tail = CGMutablePath()
    let cut: CGFloat = mid + 1.65 * spread
    tail.move(to: CGPoint(x: cut, y: base))
    for x in stride(from: cut, through: 884, by: 4) { tail.addLine(to: CGPoint(x: x, y: y(x))) }
    tail.addLine(to: CGPoint(x: 884, y: base)); tail.closeSubpath()
    ctx.addPath(tail); ctx.setFillColor(color(1.0, 0.80, 0.35, 0.85).cgColor); ctx.fillPath()
    let body = CGMutablePath()
    body.move(to: CGPoint(x: 140, y: base))
    for x in stride(from: 140, through: cut, by: 4) { body.addLine(to: CGPoint(x: CGFloat(x), y: y(CGFloat(x)))) }
    body.addLine(to: CGPoint(x: cut, y: base)); body.closeSubpath()
    ctx.addPath(body); ctx.setFillColor(color(0.42, 0.85, 1.0, 0.18).cgColor); ctx.fillPath()
    ctx.addPath(curve); ctx.setStrokeColor(color(0.42, 0.85, 1.0).cgColor); ctx.setLineWidth(16)
    ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.strokePath()
    ctx.setStrokeColor(color(1, 1, 1, 0.35).cgColor); ctx.setLineWidth(6)
    ctx.move(to: CGPoint(x: 150, y: base)); ctx.addLine(to: CGPoint(x: 874, y: base)); ctx.strokePath()

    // Ringed planet, upper right, sitting on the curve's shoulder.
    let pc = CGPoint(x: 690, y: 700), pr: CGFloat = 112
    func ring(front: Bool) {
        // Half an ellipse, tilted: the back half (above the axis) before the planet, the front after.
        let rx = pr * 1.85, ry = pr * 0.48, tilt: CGFloat = 0.42
        let path = CGMutablePath()
        for i in 0...60 {
            let t = CGFloat(i) / 60 * .pi
            let ex = rx * cos(t), ey = (front ? -ry : ry) * sin(t)
            let p = CGPoint(x: pc.x + ex * cos(-tilt) - ey * sin(-tilt), y: pc.y + ex * sin(-tilt) + ey * cos(-tilt))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        ctx.addPath(path)
        ctx.setStrokeColor(color(1.0, 0.86, 0.55, 0.92).cgColor); ctx.setLineWidth(20); ctx.setLineCap(.round)
        ctx.strokePath()
    }
    ring(front: false)
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: pc.x - pr, y: pc.y - pr, width: pr * 2, height: pr * 2)); ctx.clip()
    let planet = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: [color(1.0, 0.85, 0.45).cgColor, color(0.85, 0.42, 0.25).cgColor, color(0.35, 0.12, 0.25).cgColor] as CFArray,
                            locations: [0, 0.55, 1])!
    ctx.drawRadialGradient(planet, startCenter: CGPoint(x: pc.x - 40, y: pc.y + 45), startRadius: 4,
                           endCenter: pc, endRadius: pr * 1.05, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
    ring(front: true)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = points * scale
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        let data = drawIcon(size: CGFloat(px)).representation(using: .png, properties: [:])!
        try data.write(to: set.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: set.appendingPathComponent("Contents.json"))
try #"{"info":{"version":1,"author":"xcode"}}"#.data(using: .utf8)!
    .write(to: set.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icon sizes to \(set.path)")
