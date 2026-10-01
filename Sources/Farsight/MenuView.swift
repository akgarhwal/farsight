import SwiftUI

struct MenuView: View {
    @ObservedObject var model: TimerModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.phase == .work ? "Focus" : "Break")
                    .font(.headline)
                Spacer()
                Text(model.remainingText)
                    .font(.system(.title2, design: .monospaced))
            }

            HStack {
                Button(model.isRunning ? "Pause" : "Start") {
                    model.isRunning ? model.pause() : model.start()
                }
                Button("Reset") { model.reset() }
                Spacer()
                if model.phase == .work {
                    Button("Break Now") { model.startBreak() }
                } else {
                    Button("Skip Break") { model.skipBreak() }
                }
            }

            Divider()

            Stepper(value: $model.workMinutes, in: 1...180) {
                Text("Work: \(model.workMinutes) min")
            }
            Stepper(value: $model.breakMinutes, in: 1...60) {
                Text("Break: \(model.breakMinutes) min")
            }
            Text("New durations apply from the next phase (or press Reset).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    loginError = LaunchAtLogin.set(enabled)
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            if let loginError {
                Text(loginError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Button("Quit Farsight") { NSApp.terminate(nil) }
                Spacer()
                if let buildLabel = Self.buildLabel {
                    Text(buildLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    /// "v1.0.0 · Sep 29 11:18" from the build time build.sh stamps; nil outside the app bundle.
    private static let buildLabel: String? = {
        let info = Bundle.main.infoDictionary
        guard let version = info?["CFBundleShortVersionString"] as? String else { return nil }
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyyMMdd.HHmm"
        guard let build = info?["CFBundleVersion"] as? String,
              let date = stamp.date(from: build) else { return "v\(version)" }
        return "v\(version) · " + date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }()
}
