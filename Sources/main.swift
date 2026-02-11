import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var sleepDisabled = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        updateStatus()
        buildMenu()

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
            self?.buildMenu()
        }
    }

    func updateStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            return
        }
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("sleepdisabled") || lower.contains("disablesleep") {
                sleepDisabled = line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
                break
            }
        }

        if let button = statusItem.button {
            if sleepDisabled {
                button.image = NSImage(
                    systemSymbolName: "eye.fill",
                    accessibilityDescription: "Sleep Disabled")
            } else {
                button.image = NSImage(
                    systemSymbolName: "moon.zzz",
                    accessibilityDescription: "Sleep Enabled")
            }
        }
    }

    func buildMenu() {
        let menu = NSMenu()

        let statusText = sleepDisabled ? "Sleep: Disabled" : "Sleep: Enabled"
        let item = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)

        menu.addItem(NSMenuItem.separator())

        if sleepDisabled {
            let enable = NSMenuItem(
                title: "Enable Sleep", action: #selector(enableSleep), keyEquivalent: "")
            enable.target = self
            menu.addItem(enable)
        } else {
            let disable = NSMenuItem(
                title: "Disable Sleep", action: #selector(disableSleep), keyEquivalent: "")
            disable.target = self
            menu.addItem(disable)
        }

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc func enableSleep() {
        runWithAdmin("pmset disablesleep 0")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.updateStatus()
            self?.buildMenu()
        }
    }

    @objc func disableSleep() {
        runWithAdmin("pmset disablesleep 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.updateStatus()
            self?.buildMenu()
        }
    }

    func runWithAdmin(_ command: String) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
