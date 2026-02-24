import Cocoa
import ServiceManagement
import SleeplessKit

final class AppDelegate: NSObject, NSApplicationDelegate, SleepManagerDelegate {
    private var statusItem: NSStatusItem!
    private var pollTimer: Timer?
    private let sleepManager = SleepManager()
    private var statusMenuItem: NSMenuItem?
    private var lastKnownSleepDisabled: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        sleepManager.delegate = self
        sleepManager.startWatching()

        DispatchQueue.main.async { [self] in
            sleepManager.poll()
            updateUI()
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.sleepManager.poll()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if sleepManager.isSleepDisabled {
            sleepManager.enableSleep()
        }
    }

    func sleepStateDidChange(disabled: Bool, timerRemaining: TimeInterval?) {
        let stateChanged = disabled != lastKnownSleepDisabled
        lastKnownSleepDisabled = disabled
        stateChanged ? updateUI() : updateStatusTitle()
    }

    private func updateUI() {
        updateIcon()
        buildMenu()
    }

    private func updateStatusTitle() {
        guard sleepManager.isSleepDisabled, sleepManager.timerManager.isActive else { return }
        statusMenuItem?.title = "Sleep: Disabled (\(TimerManager.format(sleepManager.timerManager.remaining)) remaining)"
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if sleepManager.isSleepDisabled {
            let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Sleep Disabled")?
                .withSymbolConfiguration(config)
            image?.isTemplate = false
            button.image = image?.withTintColor(.systemYellow)
        } else {
            let image = NSImage(systemSymbolName: "bed.double.fill", accessibilityDescription: "Sleep Enabled")?
                .withSymbolConfiguration(config)
            image?.isTemplate = false
            button.image = image?.withTintColor(.systemGreen)
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        let statusText: String
        if sleepManager.isSleepDisabled {
            if sleepManager.timerManager.isActive {
                statusText = "Sleep: Disabled (\(TimerManager.format(sleepManager.timerManager.remaining)) remaining)"
            } else {
                statusText = "Sleep: Disabled"
            }
        } else {
            statusText = "Sleep: Enabled"
        }

        let statusItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        statusMenuItem = statusItem
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

        let launchItem = addItem(to: menu, title: "Open at Login", action: #selector(toggleLaunchAtLogin))
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off

        menu.addItem(.separator())
        addItem(to: menu, title: "Quit", action: #selector(quitApp), key: "q")

        self.statusItem.menu = menu
    }

    @discardableResult
    private func addItem(to menu: NSMenu, title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc private func enableSleep()  { sleepManager.enableSleep() }
    @objc private func disableSleep() { sleepManager.disableSleep() }
    @objc private func disable30()    { sleepManager.disableSleep(for: 30 * 60) }
    @objc private func disable60()    { sleepManager.disableSleep(for: 60 * 60) }
    @objc private func disable120()   { sleepManager.disableSleep(for: 120 * 60) }
    @objc private func enable30()     { sleepManager.enableSleep(after: 30 * 60) }
    @objc private func enable60()     { sleepManager.enableSleep(after: 60 * 60) }
    @objc private func enable120()    { sleepManager.enableSleep(after: 120 * 60) }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        if service.status == .enabled {
            try? service.unregister()
        } else {
            try? service.register()
        }
        buildMenu()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

extension NSImage {
    func withTintColor(_ color: NSColor) -> NSImage {
        let size = self.size
        return NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
