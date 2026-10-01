import AppKit
import SwiftUI

/// Borderless panels can't become key by default, which would swallow button clicks.
private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

/// The menu bar popover's controls in a panel just under the menu bar. On a notched Mac, macOS
/// hides menu bar items that don't fit, so this is how to reach Farsight when its icon is hidden.
final class MenuPanelController {
    private let model: TimerModel
    private let panel: NSPanel

    init(model: TimerModel) {
        self.model = model
        // Non-activating: macOS may refuse to activate Farsight on reopen, and the panel
        // must still take clicks and keys (and close on a click elsewhere) without that.
        panel = KeyPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        // Close like the popover does: on a click anywhere else (or Esc, above).
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in self?.panel.orderOut(nil) }
    }

    func show() {
        // A fresh view each time, so state like "Launch at login" is current.
        let host = NSHostingView(rootView: MenuView(model: model)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10)))
        let size = host.fittingSize
        panel.contentView = host

        // Top center, which on a notched Mac is right under the notch.
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let origin = NSPoint(x: screen.frame.midX - size.width / 2, y: screen.visibleFrame.maxY - size.height - 8)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)

        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
    }
}
