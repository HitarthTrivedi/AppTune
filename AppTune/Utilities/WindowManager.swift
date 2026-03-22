import SwiftUI
import AppKit

class WindowManager: NSObject {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?

    func openSettings() {
        // If window already exists, just bring it forward
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Build the SwiftUI view with its environment objects
        let settingsView = SettingsView()
            .environmentObject(AppMonitorService.shared)
            .environmentObject(SettingsStore.shared)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "AppTune Settings"
        window.setContentSize(NSSize(width: 750, height: 520))
        window.minSize = NSSize(width: 700, height: 480)
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        self.settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Keep reference but mark as hidden — allows reopening cleanly
        settingsWindow = nil
    }
}
