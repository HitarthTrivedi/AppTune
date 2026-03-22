import Foundation
import AppKit

class SpotifyService: ObservableObject {
    static let shared = SpotifyService()

    // MARK: - Replace these with your actual credentials
    private let clientID = "f989c6cee8fa443cb3ea026c401bcd1e"
    private let clientSecret = "5a5c3eb0b5e945c1804b00763fc78759"
    private let redirectURI = "apptune://callback"
    private let scopes = "playlist-read-private playlist-read-collaborative user-library-read"

    // MARK: - Published State
    @Published var isAuthenticated: Bool = false
    @Published var userPlaylists: [SpotifyPlaylist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Token Storage (Keychain)
    private let accessTokenKey = "spotify_access_token"
    private let refreshTokenKey = "spotify_refresh_token"
    private let expiryKey = "spotify_token_expiry"

    private var accessToken: String? {
        get { KeychainHelper.get(key: accessTokenKey) }
        set {
            if let value = newValue { KeychainHelper.set(key: accessTokenKey, value: value) }
            else { KeychainHelper.delete(key: accessTokenKey) }
        }
    }

    private var refreshToken: String? {
        get { KeychainHelper.get(key: refreshTokenKey) }
        set {
            if let value = newValue { KeychainHelper.set(key: refreshTokenKey, value: value) }
            else { KeychainHelper.delete(key: refreshTokenKey) }
        }
    }

    private var tokenExpiry: Date? {
        get {
            let interval = UserDefaults.standard.double(forKey: expiryKey)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: expiryKey)
        }
    }

    init() {
        isAuthenticated = accessToken != nil && tokenExpiry ?? Date() > Date()
        if isAuthenticated {
            fetchPlaylists()
        }
    }

    // MARK: - Step 1: Open Spotify Login in Browser
    func startOAuthFlow() {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Step 2: Handle Callback (called from AppDelegate)
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to get authorization code from Spotify."
            }
            return
        }
        exchangeCodeForToken(code: code)
    }

    // MARK: - Step 3: Exchange Code for Token
    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }

        let credentials = "\(clientID):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else { return }
        let base64Credentials = credentialsData.base64EncodedString()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }
            self.parseTokenResponse(data: data)
        }.resume()
    }

    // MARK: - Refresh Token
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refresh = refreshToken,
              let url = URL(string: "https://accounts.spotify.com/api/token") else {
            completion(false)
            return
        }

        let credentials = "\(clientID):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else { completion(false); return }
        let base64Credentials = credentialsData.base64EncodedString()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=refresh_token&refresh_token=\(refresh)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion(false)
                return
            }
            self.parseTokenResponse(data: data)
            completion(true)
        }.resume()
    }

    // MARK: - Parse Token Response
    private func parseTokenResponse(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else { return }

        accessToken = token
        if let refresh = json["refresh_token"] as? String {
            refreshToken = refresh
        }
        if let expiresIn = json["expires_in"] as? Double {
            tokenExpiry = Date().addingTimeInterval(expiresIn)
        }

        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.fetchPlaylists()
        }
    }

    // MARK: - Fetch User Playlists
    func fetchPlaylists() {
        guard let token = accessToken else { return }

        // Check if token needs refresh
        if let expiry = tokenExpiry, expiry < Date() {
            refreshAccessToken { [weak self] success in
                if success { self?.fetchPlaylists() }
            }
            return
        }

        DispatchQueue.main.async { self.isLoading = true }

        var components = URLComponents(string: "https://api.spotify.com/v1/me/playlists")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "50")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }

            if let response = try? JSONDecoder().decode(SpotifyPlaylistResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.userPlaylists = response.items
                    self.isLoading = false
                }
            }
        }.resume()
    }

    // MARK: - Play a Playlist
    func playPlaylist(uri: String) {
        // Use AppleScript to tell Spotify to play the URI
        let script = """
        tell application "Spotify"
            activate
            play track "\(uri)"
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    // MARK: - Logout
    func logout() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userPlaylists = []
        }
    }
}

// MARK: - Spotify Models
struct SpotifyPlaylistResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let uri: String
    let tracks: SpotifyTrackInfo?
    let images: [SpotifyImage]?

    var thumbnailURL: URL? {
        guard let urlString = images?.last?.url else { return nil }
        return URL(string: urlString)
    }
}

struct SpotifyTrackInfo: Codable {
    let total: Int
}

struct SpotifyImage: Codable {
    let url: String
}

// MARK: - Keychain Helper
struct KeychainHelper {
    static func set(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
