import AppKit
import SwiftUI

/// Borderless windows can't become key by default, which would swallow button clicks.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class BreakOverlayController {
    var onSkip: (() -> Void)?
    private var windows: [NSWindow] = []

    func show(model: TimerModel) {
        hide()
        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: BreakView(model: model, onSkip: { [weak self] in self?.onSkip?() })
            )
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

private struct BreakView: View {
    @ObservedObject var model: TimerModel
    let onSkip: () -> Void

    var body: some View {
        BreakScreen(remainingText: model.remainingText, card: model.card, onSkip: onSkip)
    }
}

/// The break screen's content, independent of the live model (also used to render README screenshots).
struct BreakScreen: View {
    let remainingText: String
    let card: Card?
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "eye")
                    .font(.system(size: 64))
                Text("Time for a break")
                    .font(.system(size: 44, weight: .semibold))
                Text("Look at something 20 feet away and let your eyes relax.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                Text(remainingText)
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                if let card {
                    CardView(card: card)
                }
                Button("Skip Break", action: onSkip)
                    .controlSize(.large)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .foregroundStyle(.white)
        }
    }
}

private struct CardView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 10) {
            Text(card.category.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.6))
            Text(card.text)
                .font(.title2)
                .multilineTextAlignment(.center)
            if let author = card.author {
                Text("- \(author)")
                    .font(.title3.italic())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(24)
        .frame(maxWidth: 720)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
