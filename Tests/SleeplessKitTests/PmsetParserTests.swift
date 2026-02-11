import XCTest
@testable import SleeplessKit

final class PmsetParserTests: XCTestCase {
    func testSleepEnabled() {
        let output = """
        System-wide power settings:
        Currently in use:
         SleepDisabled          0
        """
        XCTAssertFalse(PmsetParser.isSleepDisabled(pmsetOutput: output))
    }

    func testSleepDisabled() {
        let output = """
        System-wide power settings:
        Currently in use:
         SleepDisabled          1
        """
        XCTAssertTrue(PmsetParser.isSleepDisabled(pmsetOutput: output))
    }

    func testDisableSleepKeyVariant() {
        XCTAssertTrue(PmsetParser.isSleepDisabled(pmsetOutput: " disablesleep         1\n"))
        XCTAssertFalse(PmsetParser.isSleepDisabled(pmsetOutput: " disablesleep         0\n"))
    }

    func testEmptyOutput() {
        XCTAssertFalse(PmsetParser.isSleepDisabled(pmsetOutput: ""))
    }

    func testNoMatchingLine() {
        XCTAssertFalse(PmsetParser.isSleepDisabled(pmsetOutput: "Some unrelated pmset output\n"))
    }

    func testTabSeparated() {
        XCTAssertTrue(PmsetParser.isSleepDisabled(pmsetOutput: " SleepDisabled\t\t1\n"))
        XCTAssertFalse(PmsetParser.isSleepDisabled(pmsetOutput: " SleepDisabled\t\t0\n"))
    }
}
