import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// Renders the app's real SwiftUI views off-screen to PNGs and creates an animated preview GIF for the README.
/// Built and run by screenshots.sh; nothing is shown on screen.
@main
struct Screenshots {
    static func main() {
        _ = NSApplication.shared
        let out = CommandLine.arguments.dropFirst().first ?? "docs"

        let model = TimerModel()
        render(
            MenuScreen(model: model),
            size: CGSize(width: 1440, height: 900),
            to: "\(out)/menu.png"
        )

        render(
            BreakScreen(
                remainingText: "04:32",
                card: Card(text: "Premature optimization is the root of all evil.",
                           author: "Donald Knuth", category: "Tech Quote"),
                onSkip: {}
            ),
            size: CGSize(width: 1440, height: 900),
            to: "\(out)/break-quote.png"
        )

        render(
            BreakScreen(
                remainingText: "02:17",
                card: Card(text: "Consistent hashing: nodes and keys hash onto a ring and each key belongs to the next node clockwise, so adding a node moves only ~1/N of keys instead of nearly all of them.",
                           author: nil, category: "Distributed Systems"),
                onSkip: {}
            ),
            size: CGSize(width: 1440, height: 900),
            to: "\(out)/break-tip.png"
        )

        createGIF(
            from: [
                "\(out)/menu.png",
                "\(out)/break-quote.png",
                "\(out)/break-tip.png"
            ],
            to: "\(out)/demo.gif",
            frameDelay: 3.0
        )
    }

    static func createGIF(from imagePaths: [String], to outputPath: String, frameDelay: Double) {
        let outputURL = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            imagePaths.count,
            nil
        ) else {
            print("Failed to create CGImageDestination for \(outputPath)")
            return
        }

        let fileProps: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProps as CFDictionary)

        let frameProps: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime: frameDelay
            ]
        ]

        for path in imagePaths {
            let url = URL(fileURLWithPath: path)
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                print("Failed to load image from \(path)")
                continue
            }
            CGImageDestinationAddImage(destination, image, frameProps as CFDictionary)
        }

        if CGImageDestinationFinalize(destination) {
            print("wrote \(outputPath) (animated GIF, \(imagePaths.count) frames, \(frameDelay)s delay)")
        } else {
            print("Failed to finalize GIF at \(outputPath)")
        }
    }


    struct MenuScreen: View {
        let model: TimerModel

        var body: some View {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.05, blue: 0.14), Color(red: 0.10, green: 0.08, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        HStack(spacing: 18) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 14))
                            Text("Farsight").bold()
                            Text("File")
                            Text("Edit")
                            Text("View")
                            Text("Window")
                            Text("Help")
                        }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))

                        Spacer()

                        HStack(spacing: 14) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye")
                                Text("25:00").monospacedDigit()
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 5))

                            Image(systemName: "wifi")
                            Image(systemName: "battery.100")
                            Text("Thu Oct 1  4:53 PM")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 32)
                    .background(.ultraThinMaterial)

                    HStack {
                        Spacer()
                        MenuView(model: model)
                            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 12)
                            .padding(.trailing, 90)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
            }
        }
    }

    static func render<V: View>(_ view: V, size: CGSize?, to path: String) {
        let host = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
        host.appearance = NSAppearance(named: .darkAqua)
        let size = size ?? host.fittingSize
        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: size.width, height: size.height),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        // Draw at 2x so the images stay sharp on Retina displays.
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        let png = rep.representation(using: .png, properties: [:])!
        try! png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path) (\(Int(size.width))x\(Int(size.height)) pt)")
    }
}
