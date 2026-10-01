import AppKit
import Combine

enum Phase {
    case work, rest
}

final class TimerModel: ObservableObject {
    @Published var workMinutes: Int {
        didSet { UserDefaults.standard.set(workMinutes, forKey: "workMinutes") }
    }
    @Published var breakMinutes: Int {
        didSet { UserDefaults.standard.set(breakMinutes, forKey: "breakMinutes") }
    }

    @Published private(set) var phase: Phase = .work
    @Published private(set) var isRunning = false
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var card: Card?

    // The phase is tracked by its end time, so sleep and timer drift don't matter.
    private var endDate: Date?
    private var ticker: Timer?
    private let overlay = BreakOverlayController()

    enum AwayReason { case screenLocked, systemAsleep }

    // While the screen is locked or the Mac is asleep, the timer is frozen.
    private var awayReasons: Set<AwayReason> = []
    private var awaySince: Date?
    private var wasRunningBeforeAway = false

    init() {
        let defaults = UserDefaults.standard
        workMinutes = defaults.object(forKey: "workMinutes") as? Int ?? 25
        breakMinutes = defaults.object(forKey: "breakMinutes") as? Int ?? 5
        remaining = TimeInterval(workMinutes * 60)

        overlay.onSkip = { [weak self] in self?.skipBreak() }

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) {
            [weak self] _ in self?.awayBegan(.systemAsleep)
        }
        workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) {
            [weak self] _ in self?.awayEnded(.systemAsleep)
        }
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) {
            [weak self] _ in self?.awayBegan(.screenLocked)
        }
        distributed.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) {
            [weak self] _ in self?.awayEnded(.screenLocked)
        }

        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(ticker!, forMode: .common)

        start()
    }

    var remainingText: String {
        let total = max(0, Int(remaining.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func start() {
        guard !isRunning else { return }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        clearAway()
    }

    func pause() {
        guard isRunning, let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        self.endDate = nil
        isRunning = false
    }

    func reset() {
        beginWork()
    }

    func startBreak() {
        phase = .rest
        card = CardDeck.random()
        setPhaseDuration(minutes: breakMinutes)
        NSSound(named: "Glass")?.play()
        overlay.show(model: self)
    }

    func skipBreak() {
        beginWork()
    }

    private func beginWork() {
        overlay.hide()
        phase = .work
        setPhaseDuration(minutes: workMinutes)
    }

    private func setPhaseDuration(minutes: Int) {
        remaining = TimeInterval(minutes * 60)
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        clearAway()
    }

    func awayBegan(_ reason: AwayReason, at now: Date = Date()) {
        let wasPresent = awayReasons.isEmpty
        awayReasons.insert(reason)
        guard wasPresent else { return }
        awaySince = now
        wasRunningBeforeAway = isRunning
        pause()
    }

    func awayEnded(_ reason: AwayReason, at now: Date = Date()) {
        guard awayReasons.remove(reason) != nil, awayReasons.isEmpty, let awaySince else { return }
        self.awaySince = nil
        guard wasRunningBeforeAway else { return }
        // Away for a whole break (or the rest of the current one) means the eyes already rested.
        let rest = phase == .work ? TimeInterval(breakMinutes * 60) : remaining
        if now.timeIntervalSince(awaySince) >= rest {
            beginWork()
        } else {
            start()
        }
    }

    /// Running means the user is here, even if an unlock or wake notification was missed.
    private func clearAway() {
        awayReasons.removeAll()
        awaySince = nil
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        guard remaining <= 0 else { return }

        switch phase {
        case .work:
            startBreak()
        case .rest:
            NSSound(named: "Hero")?.play()
            beginWork()
        }
    }
}
