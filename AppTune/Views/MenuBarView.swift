import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appMonitor: AppMonitorService
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#6c63ff"), Color(hex: "#a855f7")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 30, height: 30)
                    Image(systemName: "music.note.tv")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("AppTune")
                        .font(.system(size: 13, weight: .bold))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(appMonitor.isMonitoring ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(appMonitor.isMonitoring ? "Monitoring" : "Paused")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    if appMonitor.isMonitoring {
                        appMonitor.stopMonitoring()
                    } else {
                        appMonitor.startMonitoring()
                    }
                }) {
                    Image(systemName: appMonitor.isMonitoring ? "pause.circle" : "play.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(appMonitor.isMonitoring ? .secondary : Color(hex: "#6c63ff"))
                }
                .buttonStyle(.plain)
                .help(appMonitor.isMonitoring ? "Pause monitoring" : "Resume monitoring")
            }
            .padding(12)

            Divider()

            // Active Rules
            if settingsStore.rules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No rules configured")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("ACTIVE RULES")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("\(settingsStore.rules.filter(\.isEnabled).count) of \(settingsStore.rules.count)")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    ForEach(settingsStore.rules.prefix(5)) { rule in
                        MenuBarRuleRow(rule: rule) {
                            var updated = rule
                            updated.isEnabled.toggle()
                            settingsStore.updateRule(updated)
                        }
                    }

                    if settingsStore.rules.count > 5 {
                        Text("+\(settingsStore.rules.count - 5) more rules")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 6)
                    }
                }
            }

            // Last activity
            if !appMonitor.lastTriggeredApp.isEmpty {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("Last: \(appMonitor.lastTriggeredApp) → \(appMonitor.lastTriggeredPlaylist)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Divider()

            // Footer
            HStack(spacing: 0) {
                Button("Settings") {
                    WindowManager.shared.openSettings()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                Divider().frame(height: 20)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 280)
    }
}

struct MenuBarRuleRow: View {
    let rule: AppRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let iconPath = rule.appIconPath,
               let img = NSImage(contentsOfFile: iconPath) {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(rule.appName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(rule.playlistName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .opacity(rule.isEnabled ? 1.0 : 0.5)
    }
}
