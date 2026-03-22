import SwiftUI
import ServiceManagement

struct GeneralView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var appMonitor: AppMonitorService
    @State private var loginItemStatus: String = "Checking..."

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("General")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("App preferences and system settings")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider()

            ScrollView {
                VStack(spacing: 14) {
                    // Startup Section
                    SettingsSection(title: "Startup & Background") {
                        SettingsRow(
                            icon: "power",
                            iconColor: Color(hex: "#10b981"),
                            title: "Launch at Login",
                            subtitle: "Start AppTune automatically when you log in"
                        ) {
                            Toggle("", isOn: $settingsStore.launchAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "eye",
                            iconColor: Color(hex: "#6c63ff"),
                            title: "Monitoring",
                            subtitle: appMonitor.isMonitoring ? "Currently watching for app launches" : "Paused"
                        ) {
                            Toggle("", isOn: Binding(
                                get: { appMonitor.isMonitoring },
                                set: { newVal in
                                    if newVal { appMonitor.startMonitoring() }
                                    else { appMonitor.stopMonitoring() }
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }

                        Divider().padding(.leading, 44)

                        SettingsRow(
                            icon: "menubar.arrow.up.rectangle",
                            iconColor: Color(hex: "#f59e0b"),
                            title: "Lives in Menu Bar",
                            subtitle: "AppTune runs quietly in your menu bar"
                        ) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    // Login Item Status
                    SettingsSection(title: "System Integration") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 13))
                                Text("Login Item Status")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text(loginItemStatus)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            Divider().padding(.leading, 14)

                            Button("Open Login Items in System Settings") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
                            }
                            .buttonStyle(.link)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6c63ff"))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 10)
                        }
                    }

                    // Activity
                    SettingsSection(title: "Recent Activity") {
                        if appMonitor.lastTriggeredApp.isEmpty {
                            HStack {
                                Spacer()
                                Text("No activity yet")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                                    .padding()
                                Spacer()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(Color(hex: "#6c63ff"))
                                    Text("Last triggered by:")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text(appMonitor.lastTriggeredApp)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundStyle(Color(hex: "#fc3c44"))
                                    Text("Playing playlist:")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text(appMonitor.lastTriggeredPlaylist)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .padding(14)
                        }
                    }

                    // About
                    SettingsSection(title: "About") {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#6c63ff"), Color(hex: "#a855f7")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "music.note.tv")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AppTune")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Version 1.0.0")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Text("Music automation for macOS")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                        }
                        .padding(14)
                    }
                }
                .padding(24)
            }
        }
        .onAppear { checkLoginItemStatus() }
    }

    func checkLoginItemStatus() {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled: loginItemStatus = "Enabled ✓"
            case .notFound: loginItemStatus = "Not Registered"
            case .notRegistered: loginItemStatus = "Not Registered"
            case .requiresApproval: loginItemStatus = "Requires Approval"
            @unknown default: loginItemStatus = "Unknown"
            }
        } else {
            loginItemStatus = "macOS 13+ required"
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct SettingsRow<Control: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
