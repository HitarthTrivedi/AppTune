import Foundation
import Combine
import AppKit
import ServiceManagement
// MARK: - Music Service
enum MusicService: String, CaseIterable, Codable, Identifiable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appleMusic: return "applemusic"
        case .spotify: return "spotify"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .appleMusic: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        }
    }
}

// MARK: - Playlist Model
struct Playlist: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let service: MusicService
    var trackCount: Int?
    var artworkURL: String?
}

// MARK: - App Rule
struct AppRule: Identifiable, Codable {
    var id: UUID = UUID()
    var appName: String
    var appBundleID: String
    var appIconPath: String?
    var service: MusicService
    var playlistID: String
    var playlistName: String
    var isEnabled: Bool = true
    var triggerOnLaunch: Bool = true
    var triggerOnFocus: Bool = false
}

// MARK: - Settings Store
class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var rules: [AppRule] = [] {
        didSet { save() }
    }

    @Published var launchAtLogin: Bool = false {
        didSet {
            setLoginItem(enabled: launchAtLogin)
            save()
        }
    }

    @Published var defaultService: MusicService = .appleMusic {
        didSet { save() }
    }

    @Published var spotifyConnected: Bool = false
    @Published var appleMusicConnected: Bool = false

    private let rulesKey = "appTuneRules"
    private let settingsKey = "appTuneSettings"

    init() {
        load()
        checkConnections()
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: rulesKey)
        }
        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        UserDefaults.standard.set(defaultService.rawValue, forKey: "defaultService")
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: rulesKey),
           let decoded = try? JSONDecoder().decode([AppRule].self, from: data) {
            rules = decoded
        }
        launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        if let svc = UserDefaults.standard.string(forKey: "defaultService"),
           let service = MusicService(rawValue: svc) {
            defaultService = service
        }
    }

    func checkConnections() {
        // Check if Apple Music is available
        let musicURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music")
        appleMusicConnected = musicURL != nil

        // Check if Spotify is installed
        let spotifyURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client")
        spotifyConnected = spotifyURL != nil
    }

    func addRule(_ rule: AppRule) {
        rules.append(rule)
    }

    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    func updateRule(_ rule: AppRule) {
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx] = rule
        }
    }

    private func setLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try ServiceManagement.SMAppService.mainApp.register()
                } else {
                    try ServiceManagement.SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set login item: \(error)")
            }
        }
    }
}
