import XCTest
@testable import SleeplessKit

final class SleepManagerTests: XCTestCase {
    func testPollDetectsSleepDisabled() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, " SleepDisabled          1\n")
        let mgr = SleepManager(shell: mock)
        mgr.poll()
        XCTAssertTrue(mgr.isSleepDisabled)
    }

    func testPollDetectsSleepEnabled() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, " SleepDisabled          0\n")
        let mgr = SleepManager(shell: mock)
        mgr.poll()
        XCTAssertFalse(mgr.isSleepDisabled)
    }

    func testPollCallsPmset() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.poll()

        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.calls[0].executable, "/usr/bin/pmset")
        XCTAssertEqual(mock.calls[0].arguments, ["-g"])
    }

    func testDisableSleepCallsSudo() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.disableSleep()

        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.calls[0].executable, "/usr/bin/sudo")
        XCTAssertEqual(mock.calls[0].arguments, ["/usr/bin/pmset", "disablesleep", "1"])
        XCTAssertTrue(mgr.isSleepDisabled)
    }

    func testEnableSleepCallsSudo() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.enableSleep()

        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.calls[0].executable, "/usr/bin/sudo")
        XCTAssertEqual(mock.calls[0].arguments, ["/usr/bin/pmset", "disablesleep", "0"])
        XCTAssertFalse(mgr.isSleepDisabled)
    }

    func testDisableSleepWithTimerStartsTimer() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.disableSleep(for: 1800)

        XCTAssertTrue(mgr.isSleepDisabled)
        XCTAssertTrue(mgr.timerManager.isActive)
        XCTAssertEqual(mgr.timerManager.remaining, 1800, accuracy: 1)
        mgr.timerManager.stop()
    }

    func testEnableSleepCancelsTimer() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.disableSleep(for: 1800)
        mgr.enableSleep()

        XCTAssertFalse(mgr.timerManager.isActive)
        XCTAssertFalse(mgr.isSleepDisabled)
    }

    func testExternalReenableCancelsTimer() {
        let mock = MockShellExecutor()
        let mgr = SleepManager(shell: mock)

        // Disable with timer
        mock.nextResult = (0, "")
        mgr.disableSleep(for: 1800)
        XCTAssertTrue(mgr.timerManager.isActive)

        // Simulate external re-enable via poll
        mock.nextResult = (0, " SleepDisabled          0\n")
        mgr.poll()

        XCTAssertFalse(mgr.isSleepDisabled)
        XCTAssertFalse(mgr.timerManager.isActive)
    }

    func testEnableSleepAfterStartsTimerWithoutToggling() {
        let mock = MockShellExecutor()
        mock.nextResult = (0, "")
        let mgr = SleepManager(shell: mock)
        mgr.disableSleep()
        mock.calls.removeAll()

        mgr.enableSleep(after: 1800)

        // Should not have called sudo again — sleep is already disabled
        XCTAssertEqual(mock.calls.count, 0)
        XCTAssertTrue(mgr.timerManager.isActive)
        XCTAssertEqual(mgr.timerManager.remaining, 1800, accuracy: 1)
        mgr.timerManager.stop()
    }

    func testDelegateNotifiedOnStateChange() {
        let mock = MockShellExecutor()
        let mgr = SleepManager(shell: mock)
        let spy = SleepDelegateSpy()
        mgr.delegate = spy

        mock.nextResult = (0, " SleepDisabled          1\n")
        mgr.poll()

        XCTAssertEqual(spy.callCount, 1)
        XCTAssertTrue(spy.lastDisabled!)
    }

    func testDelegateNotCalledWhenStateUnchanged() {
        let mock = MockShellExecutor()
        let mgr = SleepManager(shell: mock)
        let spy = SleepDelegateSpy()
        mgr.delegate = spy

        // Poll with sleep enabled (default state) — no change
        mock.nextResult = (0, " SleepDisabled          0\n")
        mgr.poll()

        XCTAssertEqual(spy.callCount, 0)
    }
}

private final class SleepDelegateSpy: SleepManagerDelegate {
    var callCount = 0
    var lastDisabled: Bool?
    var lastTimerRemaining: TimeInterval?

    func sleepStateDidChange(disabled: Bool, timerRemaining: TimeInterval?) {
        callCount += 1
        lastDisabled = disabled
        lastTimerRemaining = timerRemaining
    }
}
