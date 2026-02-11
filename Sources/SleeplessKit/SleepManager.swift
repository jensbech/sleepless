import Foundation

public protocol SleepManagerDelegate: AnyObject {
    func sleepStateDidChange(disabled: Bool, timerRemaining: TimeInterval?)
}

public final class SleepManager: TimerManagerDelegate {
    public weak var delegate: SleepManagerDelegate?

    public private(set) var isSleepDisabled: Bool = false
    public let timerManager = TimerManager()
    private let shell: ShellExecuting
    private var fileWatcherSource: DispatchSourceFileSystemObject?

    private static let pmsetPlistPath = "/Library/Preferences/com.apple.PowerManagement.plist"

    public init(shell: ShellExecuting = ShellExecutor()) {
        self.shell = shell
        timerManager.delegate = self
    }

    deinit {
        stopWatching()
    }

    // MARK: - File Watching

    /// Start watching the pmset plist for changes. Call once on app launch.
    public func startWatching() {
        setupFileWatcher()
    }

    public func stopWatching() {
        fileWatcherSource?.cancel()
        fileWatcherSource = nil
    }

    private func setupFileWatcher() {
        fileWatcherSource?.cancel()

        let fd = open(Self.pmsetPlistPath, O_EVTONLY)
        guard fd >= 0 else {
            // File doesn't exist yet — retry after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.setupFileWatcher()
            }
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.poll()
            // Re-create watcher in case the file was replaced atomically
            let events = source.data
            if events.contains(.delete) || events.contains(.rename) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.setupFileWatcher()
                }
            }
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        fileWatcherSource = source
    }

    // MARK: - Status Check

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
