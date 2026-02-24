import Foundation

public protocol TimerManagerDelegate: AnyObject {
    func timerDidTick(remaining: TimeInterval)
    func timerDidExpire()
}

public final class TimerManager {
    public weak var delegate: TimerManagerDelegate?
    public private(set) var remaining: TimeInterval = 0
    public var isActive: Bool { remaining > 0 }

    private var timer: Timer?

    public init() {}

    public func start(duration: TimeInterval) {
        stop()
        remaining = duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        remaining = 0
    }

    private func tick() {
        remaining -= 1
        if remaining <= 0 {
            remaining = 0
            timer?.invalidate()
            timer = nil
            delegate?.timerDidExpire()
        } else {
            delegate?.timerDidTick(remaining: remaining)
        }
    }

    public static func format(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
