import SwiftUI
import ServiceManagement

@main
struct AppTuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appMonitor = AppMonitorService()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        MenuBarExtra("AppTune", image: "apptune_logo") {
            MenuBarView()
                .environmentObject(appMonitor)
                .environmentObject(settingsStore)
        }
        .menuBarExtraStyle(.window)

        // Settings window is opened manually via WindowManager.shared.openSettings()
        // This avoids the bug where the SwiftUI Settings scene doesn't activate
        // unless the app was launched from Xcode.
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for login item on first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            registerLoginItem(enabled: true)
        }
        // Start monitoring immediately
        AppMonitorService.shared.startMonitoring()

        // Register custom URL scheme for Spotify OAuth callback
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    // MARK: - Handle Spotify OAuth Callback
    @objc func handleURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString),
              url.scheme == "apptune" else { return }
        SpotifyService.shared.handleCallback(url: url)
    }

    func registerLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Login item registration error: \(error)")
            }
        }
    }
}
