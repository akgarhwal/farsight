import AppKit

/// Draws the 1024x1024 Farsight app icon: an eye whose iris is a window onto a
/// distant sunset horizon, on a starry night squircle, with an "insight" sparkle.
/// Built and run by icon.sh.
@main
struct Icon {
    static let size: CGFloat = 1024

    static func main() {
        let out = CommandLine.arguments.dropFirst().first ?? "icon.png"
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw(in: NSGraphicsContext.current!.cgContext)
        NSGraphicsContext.current = nil
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
        print("wrote \(out)")
    }

    static func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
        CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }

    static func gradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
    }

    static func draw(in ctx: CGContext) {
        // macOS icon grid: 824pt rounded square centered on a 1024 canvas.
        let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
        let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

        // Soft drop shadow under the tile.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
        ctx.addPath(tilePath)
        ctx.setFillColor(color(0x0F0C29))
        ctx.fillPath()
        ctx.restoreGState()

        // Night sky background.
        ctx.saveGState()
        ctx.addPath(tilePath)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient([color(0x0B0A2A), color(0x2A1F66), color(0x4B2A7B)], [0, 0.55, 1]),
            start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: []
        )
        // Stars (fixed positions so the icon is reproducible).
        let stars: [(CGFloat, CGFloat, CGFloat)] = [
            (190, 860, 5), (270, 790, 3), (330, 880, 4), (430, 830, 3), (610, 875, 4),
            (680, 810, 3), (850, 700, 4), (170, 690, 3), (880, 560, 3), (150, 300, 3),
            (230, 210, 4), (840, 250, 4), (760, 170, 3), (400, 180, 3), (600, 205, 4),
        ]
        for (x, y, r) in stars {
            ctx.setFillColor(color(0xFFFFFF, 0.75))
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        ctx.restoreGState()

        // Eye (almond) with a glow.
        let eye = CGMutablePath()
        eye.move(to: CGPoint(x: 205, y: 500))
        eye.addCurve(to: CGPoint(x: 819, y: 500), control1: CGPoint(x: 330, y: 720), control2: CGPoint(x: 694, y: 720))
        eye.addCurve(to: CGPoint(x: 205, y: 500), control1: CGPoint(x: 694, y: 280), control2: CGPoint(x: 330, y: 280))
        eye.closeSubpath()

        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 60, color: color(0x9FB8FF, 0.55))
        ctx.addPath(eye)
        ctx.setFillColor(color(0xF4F6FF))
        ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(eye)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient([color(0xFFFFFF), color(0xD9E0FF)], [0, 1]),
            start: CGPoint(x: 512, y: 700), end: CGPoint(x: 512, y: 300), options: []
        )

        // Iris: a window onto a sunset over distant mountains.
        let center = CGPoint(x: 512, y: 500)
        let r: CGFloat = 160
        let iris = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        ctx.saveGState()
        ctx.addEllipse(in: iris)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient([color(0x3B2A8C), color(0xE0529C), color(0xFF9A5A), color(0xFFD27A)], [0, 0.45, 0.75, 1]),
            start: CGPoint(x: 512, y: center.y + r), end: CGPoint(x: 512, y: center.y - 40), options: [.drawsAfterEndLocation]
        )
        // Setting sun.
        ctx.setShadow(offset: .zero, blur: 30, color: color(0xFFE08A, 0.9))
        ctx.setFillColor(color(0xFFE9A8))
        ctx.fillEllipse(in: CGRect(x: 512 - 52, y: 468, width: 104, height: 104))
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        // Far mountain range, then a nearer, darker one.
        let far = CGMutablePath()
        far.move(to: CGPoint(x: 340, y: 470))
        for (x, y) in [(400, 530), (450, 490), (520, 555), (590, 495), (640, 530), (690, 480)] as [(CGFloat, CGFloat)] {
            far.addLine(to: CGPoint(x: x, y: y))
        }
        far.addLine(to: CGPoint(x: 690, y: 330))
        far.addLine(to: CGPoint(x: 340, y: 330))
        far.closeSubpath()
        ctx.addPath(far)
        ctx.setFillColor(color(0x6A3A9C))
        ctx.fillPath()
        let near = CGMutablePath()
        near.move(to: CGPoint(x: 340, y: 440))
        for (x, y) in [(420, 490), (480, 450), (560, 505), (630, 445), (690, 470)] as [(CGFloat, CGFloat)] {
            near.addLine(to: CGPoint(x: x, y: y))
        }
        near.addLine(to: CGPoint(x: 690, y: 330))
        near.addLine(to: CGPoint(x: 340, y: 330))
        near.closeSubpath()
        ctx.addPath(near)
        ctx.setFillColor(color(0x2A1A5E))
        ctx.fillPath()
        ctx.restoreGState()

        // Iris ring and catch-light.
        ctx.addEllipse(in: iris.insetBy(dx: 6, dy: 6))
        ctx.setStrokeColor(color(0x1B1446))
        ctx.setLineWidth(14)
        ctx.strokePath()
        ctx.setFillColor(color(0xFFFFFF, 0.9))
        ctx.fillEllipse(in: CGRect(x: 425, y: 565, width: 46, height: 46))
        ctx.restoreGState()

        // Eye outline.
        ctx.addPath(eye)
        ctx.setStrokeColor(color(0x1B1446, 0.6))
        ctx.setLineWidth(10)
        ctx.strokePath()

        // Insight sparkle, top right.
        sparkle(ctx, at: CGPoint(x: 760, y: 760), radius: 70)
        sparkle(ctx, at: CGPoint(x: 845, y: 850), radius: 28)
    }

    static func sparkle(_ ctx: CGContext, at c: CGPoint, radius R: CGFloat) {
        let r = R * 0.22
        let p = CGMutablePath()
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4 + .pi / 2
            let len = i % 2 == 0 ? R : r
            let pt = CGPoint(x: c.x + cos(angle) * len, y: c.y + sin(angle) * len)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: R * 0.6, color: color(0xFFE58A, 0.9))
        ctx.addPath(p)
        ctx.setFillColor(color(0xFFF3C4))
        ctx.fillPath()
        ctx.restoreGState()
    }
}
