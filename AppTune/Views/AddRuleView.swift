import SwiftUI
import AppKit

struct AddRuleView: View {
    @EnvironmentObject var appMonitor: AppMonitorService
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) var dismiss

    var editingRule: AppRule? = nil

    @State private var selectedApp: NSRunningApplication? = nil
    @State private var selectedAppName: String = ""
    @State private var selectedAppBundleID: String = ""
    @State private var selectedAppIconPath: String? = nil
    @State private var selectedService: MusicService = .appleMusic
    @State private var selectedPlaylist: Playlist? = nil
    @State private var triggerOnLaunch: Bool = true
    @State private var triggerOnFocus: Bool = false
    @State private var playlists: [Playlist] = []
    @State private var isLoadingPlaylists = false
    @State private var showAppPicker = false
    @State private var step: Int = 1

    var canSave: Bool {
        !selectedAppBundleID.isEmpty && selectedPlaylist != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(editingRule == nil ? "Add New Rule" : "Edit Rule")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Step \(step) of 3")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            // Progress
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { s in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(s <= step ? Color(hex: "#6c63ff") : Color(NSColor.separatorColor))
                        .frame(height: 4)
                        .animation(.easeInOut, value: step)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Divider()

            // Step Content
            ScrollView {
                VStack(spacing: 20) {
                    switch step {
                    case 1: stepOneAppPicker
                    case 2: stepTwoServicePicker
                    case 3: stepThreeTrigger
                    default: EmptyView()
                    }
                }
                .padding(20)
            }
            .frame(height: 320)

            Divider()

            // Footer
            HStack {
                if step > 1 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                if step < 3 {
                    Button("Next →") { step += 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#6c63ff"))
                        .disabled(step == 1 && selectedAppBundleID.isEmpty)
                        .disabled(step == 2 && selectedPlaylist == nil)
                } else {
                    Button("Save Rule") { saveRule() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#6c63ff"))
                        .disabled(!canSave)
                }
            }
            .padding(20)
        }
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if let rule = editingRule {
                selectedAppName = rule.appName
                selectedAppBundleID = rule.appBundleID
                selectedService = rule.service
                selectedPlaylist = Playlist(id: rule.playlistID, name: rule.playlistName, service: rule.service)
                triggerOnLaunch = rule.triggerOnLaunch
                triggerOnFocus = rule.triggerOnFocus
                step = 1
                loadPlaylists(for: rule.service)
            } else {
                loadPlaylists(for: selectedService)
            }
        }
    }

    // MARK: - Step 1: App Picker
    var stepOneAppPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Choose an App", systemImage: "app.badge")
                .font(.system(size: 15, weight: .semibold))

            Text("Select which app should trigger music playback.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Selected App Display
            if !selectedAppBundleID.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 44, height: 44)
                        if let iconPath = selectedAppIconPath,
                           let img = NSImage(contentsOfFile: iconPath) {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "#6c63ff"))
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedAppName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(selectedAppBundleID)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button("Change") { pickApp() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6c63ff"))
                }
                .padding(12)
                .background(Color(hex: "#6c63ff").opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Button(action: pickApp) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color(hex: "#6c63ff"))
                        Text("Choose Application...")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#6c63ff").opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    )
                }
                .buttonStyle(.plain)
            }

            // Running Apps Quick Picker
            Text("RUNNING APPS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                ForEach(runningUserApps(), id: \.bundleIdentifier) { app in
                    RunningAppChip(app: app, isSelected: app.bundleIdentifier == selectedAppBundleID) {
                        selectApp(app)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Service & Playlist
    var stepTwoServicePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Music Service & Playlist", systemImage: "music.note.list")
                .font(.system(size: 15, weight: .semibold))

            // Service Toggle
            HStack(spacing: 0) {
                ForEach(MusicService.allCases) { service in
                    Button(action: {
                        selectedService = service
                        loadPlaylists(for: service)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: service == .appleMusic ? "music.note" : "waveform")
                                .font(.system(size: 14))
                            Text(service.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedService == service ?
                            (service == .appleMusic ? Color(hex: "#fc3c44") : Color(hex: "#1db954")) :
                            Color.clear
                        )
                        .foregroundStyle(selectedService == service ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Playlist List
            if isLoadingPlaylists {
                HStack {
                    Spacer()
                    ProgressView("Loading playlists...")
                        .padding()
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(playlists) { playlist in
                        PlaylistRow(playlist: playlist, isSelected: selectedPlaylist?.id == playlist.id) {
                            selectedPlaylist = playlist
                        }
                        if playlist.id != playlists.last?.id {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if selectedService == .spotify {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("For Spotify, you can also enter a playlist URI manually.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Step 3: Trigger Settings
    var stepThreeTrigger: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("When to Trigger", systemImage: "bolt.fill")
                .font(.system(size: 15, weight: .semibold))

            Text("Choose when music should start playing.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                TriggerOption(
                    icon: "play.circle.fill",
                    color: Color(hex: "#10b981"),
                    title: "On App Launch",
                    subtitle: "Play when the app starts",
                    isOn: $triggerOnLaunch
                )
                TriggerOption(
                    icon: "hand.tap.fill",
                    color: Color(hex: "#3b82f6"),
                    title: "On App Focus",
                    subtitle: "Play when you switch to the app",
                    isOn: $triggerOnFocus
                )
            }

            // Summary
            if !selectedAppBundleID.isEmpty, let playlist = selectedPlaylist {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUMMARY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("App:").foregroundStyle(.secondary)
                                Text(selectedAppName).fontWeight(.medium)
                            }
                            HStack {
                                Text("Service:").foregroundStyle(.secondary)
                                ServiceBadge(service: selectedService)
                            }
                            HStack {
                                Text("Playlist:").foregroundStyle(.secondary)
                                Text(playlist.name).fontWeight(.medium)
                            }
                        }
                        .font(.system(size: 12))
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers
    func pickApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Choose"
        panel.message = "Select an application to trigger music playback"

        if panel.runModal() == .OK, let url = panel.url {
            let bundle = Bundle(url: url)
            selectedAppBundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
            selectedAppName = url.deletingPathExtension().lastPathComponent
            // Get icon
            if let iconFile = bundle?.infoDictionary?["CFBundleIconFile"] as? String {
                let iconPath = url.appendingPathComponent("Contents/Resources/\(iconFile)").path
                selectedAppIconPath = iconPath
            }
        }
    }

    func selectApp(_ app: NSRunningApplication) {
        selectedAppBundleID = app.bundleIdentifier ?? ""
        selectedAppName = app.localizedName ?? selectedAppBundleID
        if let icon = app.icon {
            let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("\(selectedAppBundleID).png")
            if let tiffData = icon.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: tempPath)
                selectedAppIconPath = tempPath.path
            }
        }
    }

    func runningUserApps() -> [NSRunningApplication] {
        let skipBundles = Set(["com.apple.Music", "com.spotify.client", "com.apple.finder",
                               "com.apple.dock", "com.apple.systemuiserver"])
        return NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                !skipBundles.contains(app.bundleIdentifier ?? "")
            }
            .prefix(8)
            .map { $0 }
    }

    func loadPlaylists(for service: MusicService) {
        isLoadingPlaylists = true
        playlists = []
        switch service {
        case .appleMusic:
            AppMonitorService.shared.fetchAppleMusicPlaylists { loaded in
                self.playlists = loaded
                self.isLoadingPlaylists = false
            }
        case .spotify:
            AppMonitorService.shared.fetchSpotifyPlaylists { loaded in
                self.playlists = loaded
                self.isLoadingPlaylists = false
            }
        }
    }

    func saveRule() {
        guard let playlist = selectedPlaylist else { return }
        var rule = AppRule(
            appName: selectedAppName,
            appBundleID: selectedAppBundleID,
            appIconPath: selectedAppIconPath,
            service: selectedService,
            playlistID: playlist.id,
            playlistName: playlist.name,
            isEnabled: true,
            triggerOnLaunch: triggerOnLaunch,
            triggerOnFocus: triggerOnFocus
        )
        if let existing = editingRule {
            rule.id = existing.id
            settingsStore.updateRule(rule)
        } else {
            settingsStore.addRule(rule)
        }
        dismiss()
    }
}

// MARK: - Running App Chip
struct RunningAppChip: View {
    let app: NSRunningApplication
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                Text(app.localizedName ?? "App")
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color(hex: "#6c63ff") : .primary)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#6c63ff").opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color(hex: "#6c63ff") : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Playlist Row
struct PlaylistRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(playlist.service == .appleMusic ?
                            Color(hex: "#fc3c44").opacity(0.15) :
                            Color(hex: "#1db954").opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 12))
                        .foregroundStyle(playlist.service == .appleMusic ?
                            Color(hex: "#fc3c44") : Color(hex: "#1db954"))
                }
                Text(playlist.name)
                    .font(.system(size: 13))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#6c63ff"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color(hex: "#6c63ff").opacity(0.06) : Color.clear)
    }
}

// MARK: - Trigger Option
struct TriggerOption: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
