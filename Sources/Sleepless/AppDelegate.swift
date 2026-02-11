import Cocoa
import SleeplessKit

class AppDelegate: NSObject, NSApplicationDelegate, SleepManagerDelegate {
    var statusItem: NSStatusItem!
    var pollTimer: Timer?
    let sleepManager = SleepManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        sleepManager.delegate = self

        sleepManager.poll()
        updateUI()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sleepManager.poll()
        }
    }

    // MARK: - SleepManagerDelegate

    func sleepStateDidChange(disabled: Bool, timerRemaining: TimeInterval?) {
        updateUI()
    }

    // MARK: - UI

    func updateUI() {
        updateIcon()
        buildMenu()
    }

    func updateIcon() {
        guard let button = statusItem.button else { return }
        if sleepManager.isSleepDisabled {
            let image = NSImage(
                systemSymbolName: "eye.fill",
                accessibilityDescription: "Sleep Disabled")
            image?.isTemplate = false
            button.image = image?.withTintColor(.systemYellow)
        } else {
            let image = NSImage(
                systemSymbolName: "moon.zzz",
                accessibilityDescription: "Sleep Enabled")
            image?.isTemplate = true
            button.image = image
        }
    }

    func buildMenu() {
        let menu = NSMenu()

        // Status line
        let statusText: String
        if sleepManager.isSleepDisabled {
            if sleepManager.timerManager.isActive {
                let fmt = TimerManager.format(sleepManager.timerManager.remaining)
                statusText = "Sleep: Disabled (\(fmt) remaining)"
            } else {
                statusText = "Sleep: Disabled"
            }
        } else {
            statusText = "Sleep: Enabled"
        }
        let item = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(.separator())

        if sleepManager.isSleepDisabled {
            if sleepManager.timerManager.isActive {
                addItem(to: menu, title: "Enable Sleep Now", action: #selector(enableSleep))
            } else {
                addItem(to: menu, title: "Enable Sleep", action: #selector(enableSleep))
                addItem(to: menu, title: "Enable Sleep in 30 min", action: #selector(enable30))
                addItem(to: menu, title: "Enable Sleep in 1 hour", action: #selector(enable60))
                addItem(to: menu, title: "Enable Sleep in 2 hours", action: #selector(enable120))
            }
        } else {
            addItem(to: menu, title: "Disable Sleep", action: #selector(disableSleep))
            addItem(to: menu, title: "Disable Sleep for 30 min", action: #selector(disable30))
            addItem(to: menu, title: "Disable Sleep for 1 hour", action: #selector(disable60))
            addItem(to: menu, title: "Disable Sleep for 2 hours", action: #selector(disable120))
        }

        menu.addItem(.separator())
        addItem(to: menu, title: "Quit", action: #selector(quitApp), key: "q")

        statusItem.menu = menu
    }

    private func addItem(to menu: NSMenu, title: String, action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Actions

    @objc func enableSleep() {
        sleepManager.enableSleep()
    }

    @objc func disableSleep() {
        sleepManager.disableSleep()
    }

    @objc func disable30() {
        sleepManager.disableSleep(for: 30 * 60)
    }

    @objc func disable60() {
        sleepManager.disableSleep(for: 60 * 60)
    }

    @objc func disable120() {
        sleepManager.disableSleep(for: 120 * 60)
    }

    @objc func enable30() {
        sleepManager.enableSleep(after: 30 * 60)
    }

    @objc func enable60() {
        sleepManager.enableSleep(after: 60 * 60)
    }

    @objc func enable120() {
        sleepManager.enableSleep(after: 120 * 60)
    }

    @objc func quitApp() {
        if sleepManager.isSleepDisabled {
            sleepManager.enableSleep()
        }
        NSApp.terminate(nil)
    }
}

// MARK: - NSImage tinting helper

extension NSImage {
    func withTintColor(_ color: NSColor) -> NSImage {
        let tinted = self.copy() as! NSImage
        tinted.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: tinted.size)
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()
        return tinted
    }
}
