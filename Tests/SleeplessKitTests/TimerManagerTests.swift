import XCTest
@testable import SleeplessKit

final class TimerManagerTests: XCTestCase {
    func testFormatSeconds() {
        XCTAssertEqual(TimerManager.format(0), "0:00")
        XCTAssertEqual(TimerManager.format(59), "0:59")
        XCTAssertEqual(TimerManager.format(60), "1:00")
        XCTAssertEqual(TimerManager.format(754), "12:34")
    }

    func testFormatHours() {
        XCTAssertEqual(TimerManager.format(3600), "1:00:00")
        XCTAssertEqual(TimerManager.format(3661), "1:01:01")
        XCTAssertEqual(TimerManager.format(7200), "2:00:00")
    }

    func testFormatNegative() {
        XCTAssertEqual(TimerManager.format(-10), "0:00")
    }

    func testStartSetsRemaining() {
        let tm = TimerManager()
        tm.start(duration: 120)
        XCTAssertTrue(tm.isActive)
        XCTAssertEqual(tm.remaining, 120, accuracy: 1)
        tm.stop()
    }

    func testStopClearsTimer() {
        let tm = TimerManager()
        tm.start(duration: 120)
        tm.stop()
        XCTAssertFalse(tm.isActive)
        XCTAssertEqual(tm.remaining, 0)
    }

    func testNotActiveByDefault() {
        let tm = TimerManager()
        XCTAssertFalse(tm.isActive)
        XCTAssertEqual(tm.remaining, 0)
    }

    func testDelegateCalledOnExpiry() {
        let tm = TimerManager()
        let spy = TimerDelegateSpy()
        tm.delegate = spy

        tm.start(duration: 1)

        let exp = expectation(description: "timer expires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)

        XCTAssertTrue(spy.didExpire)
        XCTAssertFalse(tm.isActive)
    }
}

private final class TimerDelegateSpy: TimerManagerDelegate {
    var didExpire = false
    var tickCount = 0

    func timerDidTick(remaining: TimeInterval) {
        tickCount += 1
    }

    func timerDidExpire() {
        didExpire = true
    }
}
