import SleeplessKit

final class MockShellExecutor: ShellExecuting {
    var calls: [(executable: String, arguments: [String])] = []
    var nextResult: (exitCode: Int32, output: String) = (0, "")
    var resultQueue: [(Int32, String)] = []

    @discardableResult
    func run(executable: String, arguments: [String]) -> (exitCode: Int32, output: String) {
        calls.append((executable, arguments))
        if !resultQueue.isEmpty {
            return resultQueue.removeFirst()
        }
        return nextResult
    }
}
