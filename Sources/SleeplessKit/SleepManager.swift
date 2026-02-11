import Foundation

public protocol SleepManagerDelegate: AnyObject {
    func sleepStateDidChange(disabled: Bool, timerRemaining: TimeInterval?)
}

public final class SleepManager: TimerManagerDelegate {
    public weak var delegate: SleepManagerDelegate?

    public private(set) var isSleepDisabled: Bool = false
    public let timerManager = TimerManager()
    private let shell: ShellExecuting

    public init(shell: ShellExecuting = ShellExecutor()) {
        self.shell = shell
        timerManager.delegate = self
    }

    // MARK: - Polling

    public func poll() {
        let (_, output) = shell.run(executable: "/usr/bin/pmset", arguments: ["-g"])
        let disabled = PmsetParser.isSleepDisabled(pmsetOutput: output)
        let changed = disabled != isSleepDisabled
        isSleepDisabled = disabled

        // If something external re-enabled sleep while our timer was running, cancel it.
        if !disabled && timerManager.isActive {
            timerManager.stop()
        }

        if changed {
            notifyDelegate()
        }
    }

    // MARK: - Toggle

    public func enableSleep() {
        timerManager.stop()
        shell.run(executable: "/usr/bin/sudo", arguments: ["/usr/bin/pmset", "disablesleep", "0"])
        isSleepDisabled = false
        notifyDelegate()
    }

    public func disableSleep() {
        shell.run(executable: "/usr/bin/sudo", arguments: ["/usr/bin/pmset", "disablesleep", "1"])
        isSleepDisabled = true
        notifyDelegate()
    }

    public func disableSleep(for duration: TimeInterval) {
        disableSleep()
        timerManager.start(duration: duration)
    }

    /// Start a timer to re-enable sleep after a duration (when sleep is already disabled).
    public func enableSleep(after duration: TimeInterval) {
        timerManager.start(duration: duration)
        notifyDelegate()
    }

    // MARK: - TimerManagerDelegate

    public func timerDidTick(remaining: TimeInterval) {
        notifyDelegate()
    }

    public func timerDidExpire() {
        enableSleep()
    }

    // MARK: - Private

    private func notifyDelegate() {
        let remaining: TimeInterval? = timerManager.isActive ? timerManager.remaining : nil
        delegate?.sleepStateDidChange(disabled: isSleepDisabled, timerRemaining: remaining)
    }
}
