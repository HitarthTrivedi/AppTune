import Foundation
import AppKit
import Combine

class AppMonitorService: ObservableObject {
    static let shared = AppMonitorService()

    @Published var lastTriggeredApp: String = ""
    @Published var lastTriggeredPlaylist: String = ""
    @Published var isMonitoring: Bool = false

    private var workspace: NSWorkspace = .shared
    private var observers: [NSObjectProtocol] = []
    private var settingsStore: SettingsStore { SettingsStore.shared }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Watch for app launches
        let launchObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.handleAppEvent(app: app, isFocus: false)
            }
        }

        // Watch for app focus/activation
        let activateObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.handleAppEvent(app: app, isFocus: true)
            }
        }

        observers = [launchObserver, activateObserver]
    }

    func stopMonitoring() {
        observers.forEach { workspace.notificationCenter.removeObserver($0) }
        observers.removeAll()
        isMonitoring = false
    }

    private func handleAppEvent(app: NSRunningApplication, isFocus: Bool) {
        guard let bundleID = app.bundleIdentifier else { return }

        // Skip music apps themselves to avoid loops
        let musicBundleIDs = ["com.apple.Music", "com.spotify.client"]
        guard !musicBundleIDs.contains(bundleID) else { return }

        // Find matching rule
        let matchingRules = settingsStore.rules.filter {
            $0.isEnabled && $0.appBundleID == bundleID &&
            ((!isFocus && $0.triggerOnLaunch) || (isFocus && $0.triggerOnFocus))
        }

        for rule in matchingRules {
            triggerPlayback(rule: rule, appName: app.localizedName ?? rule.appName)
        }
    }

    private func triggerPlayback(rule: AppRule, appName: String) {
        DispatchQueue.main.async {
            self.lastTriggeredApp = appName
            self.lastTriggeredPlaylist = rule.playlistName
        }

        switch rule.service {
        case .appleMusic:
            playAppleMusicPlaylist(id: rule.playlistID, name: rule.playlistName)
        case .spotify:
            playSpotifyPlaylist(id: rule.playlistID)
        }
    }

    // MARK: - Apple Music Playback
    private func playAppleMusicPlaylist(id: String, name: String) {
        // AppleScript to play a playlist by name in Apple Music
        let script = """
        tell application "Music"
            activate
            try
                set thePlaylist to playlist "\(name.replacingOccurrences(of: "\"", with: "\\\""))"
                play thePlaylist
            on error
                -- Try playing first playlist if name not found
                play playlist 1
            end try
        end tell
        """

        runAppleScript(script)
    }

    // MARK: - Spotify Playback
    private func playSpotifyPlaylist(id: String) {
        // Use Spotify's URI scheme to play a playlist
        let script = """
        tell application "Spotify"
            activate
            play track "\(id)"
        end tell
        """
        runAppleScript(script)
    }

    private func runAppleScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObj = NSAppleScript(source: script) {
                scriptObj.executeAndReturnError(&error)
                if let err = error {
                    print("AppleScript error: \(err)")
                }
            }
        }
    }

    // MARK: - Fetch Playlists
    func fetchAppleMusicPlaylists(completion: @escaping ([Playlist]) -> Void) {
        let script = """
        tell application "Music"
            set playlistNames to {}
            set playlistIDs to {}
            repeat with p in user playlists
                set end of playlistNames to name of p
                set end of playlistIDs to persistent ID of p
            end repeat
            return {playlistNames, playlistIDs}
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObj = NSAppleScript(source: script) {
                let result = scriptObj.executeAndReturnError(&error)
                DispatchQueue.main.async {
                    var playlists: [Playlist] = []
                                    if let output = result.stringValue {
                                        let names = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                                        playlists = names.map {
                                            Playlist(id: $0, name: $0, service: .appleMusic)
                                        }
                                    }
                    // Fallback with sample playlists if AppleScript fails
                    if playlists.isEmpty {
                        playlists = [
                            Playlist(id: "am_liked", name: "Liked Songs", service: .appleMusic),
                            Playlist(id: "am_recently", name: "Recently Added", service: .appleMusic),
                            Playlist(id: "am_top25", name: "My Top 25 Most Played", service: .appleMusic),
                        ]
                    }
                    completion(playlists)
                }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    func fetchSpotifyPlaylists(completion: @escaping ([Playlist]) -> Void) {
        let spotifyPlaylists = SpotifyService.shared.userPlaylists
        if !spotifyPlaylists.isEmpty {
            let playlists = spotifyPlaylists.map {
                Playlist(id: $0.uri, name: $0.name, service: .spotify, trackCount: $0.tracks?.total)
            }
            DispatchQueue.main.async { completion(playlists) }
        } else if SpotifyService.shared.isAuthenticated {
            // Fetch if authenticated but not yet loaded
            SpotifyService.shared.fetchPlaylists()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let loaded = SpotifyService.shared.userPlaylists.map {
                    Playlist(id: $0.uri, name: $0.name, service: .spotify, trackCount: $0.tracks?.total)
                }
                completion(loaded)
            }
        } else {
            // Not connected — return empty with a note
            DispatchQueue.main.async {
                completion([Playlist(id: "", name: "⚠️ Connect Spotify in Services tab first", service: .spotify)])
            }
        }
    }
}
