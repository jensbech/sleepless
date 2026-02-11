import Foundation

public protocol ShellExecuting {
    @discardableResult
    func run(executable: String, arguments: [String]) -> (exitCode: Int32, output: String)
}

public final class ShellExecutor: ShellExecuting {
    public init() {}

    @discardableResult
    public func run(executable: String, arguments: [String]) -> (exitCode: Int32, output: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            return (-1, "")
        }
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (task.terminationStatus, output)
    }
}
