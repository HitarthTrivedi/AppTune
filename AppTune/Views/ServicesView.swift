import SwiftUI

struct ServicesView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject var spotifyService = SpotifyService.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Music Services")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Connect and configure your music platforms")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    ServiceCard(
                        name: "Apple Music",
                        description: "Play playlists from your Apple Music library. AppTune uses AppleScript to control Music.app on your Mac.",
                        icon: "music.note",
                        accentColor: Color(hex: "#fc3c44"),
                        isConnected: settingsStore.appleMusicConnected,
                        isDefault: settingsStore.defaultService == .appleMusic,
                        requirements: ["Music app installed", "AppleScript permissions"],
                        onConnect: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Music.app"))
                        },
                        onSetDefault: {
                            settingsStore.defaultService = .appleMusic
                        }
                    )

                    SpotifyServiceCard()
                        .environmentObject(settingsStore)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Permissions Required", systemImage: "lock.shield")
                            .font(.system(size: 13, weight: .semibold))
                        Text("AppTune needs Automation permissions to control Music and Spotify apps. Go to System Settings → Privacy & Security → Automation to grant access if prompted.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Button("Open Privacy Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6c63ff"))
                    }
                    .padding(16)
                    .background(Color(hex: "#6c63ff").opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#6c63ff").opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(24)
            }
        }
    }
}

struct SpotifyServiceCard: View {
    @ObservedObject var spotifyService = SpotifyService.shared
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1db954").opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "waveform")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "#1db954"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Spotify")
                            .font(.system(size: 16, weight: .bold))
                        if settingsStore.defaultService == .spotify {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#1db954").opacity(0.15))
                                .foregroundStyle(Color(hex: "#1db954"))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(spotifyService.isAuthenticated ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(spotifyService.isAuthenticated ? "Connected" : "Not Connected")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Text("Play your personal Spotify playlists. Sign in with your Spotify account to access all your playlists.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if spotifyService.isAuthenticated {
                HStack {
                    Text("\(spotifyService.userPlaylists.count) playlists loaded")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if spotifyService.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Refresh") { spotifyService.fetchPlaylists() }
                            .buttonStyle(.link)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#1db954"))
                    }
                }
            }

            if let error = spotifyService.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }

            Divider()

            HStack(spacing: 10) {
                if spotifyService.isAuthenticated {
                    Button("Disconnect") { spotifyService.logout() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundStyle(.red)

                    if settingsStore.defaultService != .spotify {
                        Button("Set as Default") { settingsStore.defaultService = .spotify }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Ready").font(.system(size: 12)).foregroundStyle(.secondary)
                } else {
                    Button(action: { spotifyService.startOAuthFlow() }) {
                        Label("Connect Spotify", systemImage: "arrow.right.circle")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#1db954"))
                    .controlSize(.small)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct ServiceCard: View {
    let name: String
    let description: String
    let icon: String
    let accentColor: Color
    let isConnected: Bool
    let isDefault: Bool
    let requirements: [String]
    let onConnect: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(accentColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name).font(.system(size: 16, weight: .bold))
                        if isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor.opacity(0.15))
                                .foregroundStyle(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isConnected ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(isConnected ? "Connected" : "Not Installed")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                ForEach(requirements, id: \.self) { req in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(isConnected ? Color.green : Color.secondary)
                        Text(req).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack(spacing: 10) {
                if !isConnected {
                    Button(action: onConnect) {
                        Label("Install \(name)", systemImage: "arrow.down.circle")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .controlSize(.small)
                }
                if !isDefault && isConnected {
                    Button("Set as Default", action: onSetDefault)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Spacer()
                if isConnected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Ready").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
