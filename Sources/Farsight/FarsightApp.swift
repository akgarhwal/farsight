import SwiftUI

@main
struct FarsightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: appDelegate.model)
        } label: {
            MenuBarLabel(model: appDelegate.model)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        Image(systemName: model.phase == .work ? "eye" : "eye.slash")
        Text(model.isRunning ? model.remainingText : "Paused")
            .monospacedDigit()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = TimerModel()
    private lazy var menuPanel = MenuPanelController(model: model)

    /// Opening Farsight while it's running (Spotlight, Finder, `open`) shows its controls,
    /// since the menu bar item may be hidden behind the notch.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuPanel.show()
        return false
    }
}
