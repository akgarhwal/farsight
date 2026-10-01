import AppKit

/// Checks how TimerModel handles screen lock and sleep. Built and run by test.sh.
/// Lock/unlock is driven by calling the handlers directly: posting the real
/// com.apple.screenIsLocked notification would broadcast it to every running app.
@main
struct Tests {
    static var failures = 0

    static func check(_ condition: Bool, _ message: String, line: Int = #line) {
        if condition {
            print("  ok    \(message)")
        } else {
            print("  FAIL  \(message) (line \(line))")
            failures += 1
        }
    }

    static func near(_ value: TimeInterval, _ expected: TimeInterval) -> Bool {
        abs(value - expected) < 1
    }

    static func minutes(_ m: Double) -> Date { Date().addingTimeInterval(m * 60) }

    /// A running model with 10:00 of work left but configured for 25 min work / 5 min break,
    /// so resuming (10:00) and starting a fresh cycle (25:00) are distinguishable.
    static func freshModel() -> TimerModel {
        let model = TimerModel()
        model.breakMinutes = 5
        model.workMinutes = 10
        model.reset()
        model.workMinutes = 25
        return model
    }

    static func test(_ name: String, _ body: () -> Void) {
        print(name)
        body()
    }

    static func main() {
        _ = NSApplication.shared

        test("short lock during work resumes where it froze") {
            let m = freshModel()
            m.awayBegan(.screenLocked)
            check(!m.isRunning, "frozen while locked")
            m.awayEnded(.screenLocked, at: minutes(2))
            check(m.isRunning && m.phase == .work, "running work")
            check(near(m.remaining, 10 * 60), "remaining still ~10:00, got \(m.remainingText)")
        }

        test("lock of exactly one break length during work starts a fresh cycle") {
            let m = freshModel()
            m.awayBegan(.screenLocked)
            m.awayEnded(.screenLocked, at: minutes(5))
            check(m.isRunning && m.phase == .work, "running work")
            check(near(m.remaining, 25 * 60), "fresh 25:00")
        }

        test("lock during a break shorter than what's left finishes the break") {
            let m = freshModel()
            m.startBreak()
            m.awayBegan(.screenLocked)
            m.awayEnded(.screenLocked, at: minutes(3))
            check(m.isRunning && m.phase == .rest, "still on break")
            check(near(m.remaining, 5 * 60), "remaining break ~05:00, got \(m.remainingText)")
        }

        test("lock during a break outlasting it ends the break") {
            let m = freshModel()
            m.startBreak()
            m.awayBegan(.screenLocked)
            check(m.remaining > 4 * 60, "break had time left (not the zero edge case)")
            m.awayEnded(.screenLocked, at: minutes(5))
            check(m.isRunning && m.phase == .work, "back to work")
            check(near(m.remaining, 25 * 60), "fresh 25:00")
        }

        test("manual pause survives a long lock") {
            let m = freshModel()
            m.pause()
            let before = m.remaining
            m.awayBegan(.screenLocked)
            m.awayEnded(.screenLocked, at: minutes(30))
            check(!m.isRunning, "still paused")
            check(m.phase == .work && m.remaining == before, "time unchanged")
        }

        test("sleep with lock: wake alone keeps it frozen, unlock decides from sleep start") {
            let m = freshModel()
            m.awayBegan(.systemAsleep)
            m.awayBegan(.screenLocked, at: minutes(0.1))
            m.awayEnded(.systemAsleep, at: minutes(4))
            check(!m.isRunning, "still frozen after wake while locked")
            m.awayEnded(.screenLocked, at: minutes(6))
            check(m.isRunning && near(m.remaining, 25 * 60), "fresh cycle after 6 min away")
        }

        test("short sleep with lock resumes") {
            let m = freshModel()
            m.awayBegan(.screenLocked)
            m.awayBegan(.systemAsleep)
            m.awayEnded(.systemAsleep, at: minutes(1))
            m.awayEnded(.screenLocked, at: minutes(2))
            check(m.isRunning && m.phase == .work && near(m.remaining, 10 * 60), "resumed ~10:00")
        }

        test("sleep without lock (no password on wake)") {
            let m = freshModel()
            m.startBreak()
            m.awayBegan(.systemAsleep)
            m.awayEnded(.systemAsleep, at: minutes(10))
            check(m.isRunning && m.phase == .work && near(m.remaining, 25 * 60), "fresh work cycle")
        }

        test("unlock without a lock is ignored") {
            let m = freshModel()
            m.startBreak()
            m.awayEnded(.screenLocked, at: minutes(60))
            check(m.isRunning && m.phase == .rest, "break untouched")
        }

        test("duplicate lock notification keeps the first lock time") {
            let m = freshModel()
            m.awayBegan(.screenLocked)
            m.awayBegan(.screenLocked, at: minutes(4))
            m.awayEnded(.screenLocked, at: minutes(5))
            check(near(m.remaining, 25 * 60) && m.phase == .work, "counted 5 min away -> fresh cycle")
            let m2 = freshModel()
            m2.startBreak()
            m2.awayBegan(.screenLocked)
            m2.awayBegan(.screenLocked, at: minutes(4))
            m2.awayEnded(.screenLocked, at: minutes(5))
            check(m2.phase == .work, "5 min from first lock ended the break")
        }

        test("pressing Start after a missed unlock re-arms lock handling") {
            let m = freshModel()
            m.awayBegan(.screenLocked)  // unlock never arrives
            m.start()
            check(m.isRunning, "user started it")
            m.awayBegan(.screenLocked)
            check(!m.isRunning, "next lock freezes it again")
            m.awayEnded(.screenLocked, at: minutes(1))
            check(m.isRunning && near(m.remaining, 10 * 60), "and resumes on unlock")
        }

        test("Skip Break / Break Now while away state is stale also re-arm") {
            let m = freshModel()
            m.awayBegan(.systemAsleep)  // wake never arrives
            m.startBreak()
            check(m.isRunning && m.phase == .rest, "break running")
            m.awayBegan(.screenLocked)
            check(!m.isRunning, "lock freezes the break")
        }

        test("real NSWorkspace sleep/wake notifications are wired up") {
            let m = freshModel()
            let center = NSWorkspace.shared.notificationCenter
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            check(!m.isRunning, "frozen on willSleep")
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            check(m.isRunning && m.phase == .work && near(m.remaining, 10 * 60), "resumed on short sleep")
        }

        test("existing controls still work") {
            let m = freshModel()
            m.pause()
            check(!m.isRunning && m.remainingText == "10:00", "pause")
            m.start()
            check(m.isRunning, "start")
            m.startBreak()
            check(m.phase == .rest && near(m.remaining, 5 * 60), "break now")
            m.skipBreak()
            check(m.phase == .work && near(m.remaining, 25 * 60), "skip break")
            m.reset()
            check(m.isRunning && m.phase == .work, "reset")
        }

        // Non-bundled binaries keep defaults under the process name; don't leave them behind.
        UserDefaults.standard.removePersistentDomain(forName: ProcessInfo.processInfo.processName)
        print(failures == 0 ? "\nAll tests passed" : "\n\(failures) failed")
        exit(failures == 0 ? 0 : 1)
    }
}
