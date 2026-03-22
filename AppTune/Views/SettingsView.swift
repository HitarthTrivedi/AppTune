import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var appMonitor: AppMonitorService
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var selectedTab: Tab = .rules
    @State private var showAddRule = false

    enum Tab: String, CaseIterable {
        case rules = "Rules"
        case services = "Services"
        case general = "General"

        var icon: String {
            switch self {
            case .rules: return "list.bullet.rectangle"
            case .services: return "music.note.list"
            case .general: return "gear"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App Header
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 52, height: 52)
                        Image(systemName: "music.note.tv")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    Text("AppTune")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Music Automation")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                Divider().padding(.horizontal)

                // Navigation
                VStack(spacing: 2) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        SidebarItem(
                            icon: tab.icon,
                            label: tab.rawValue,
                            isSelected: selectedTab == tab
                        )
                        .onTapGesture { selectedTab = tab }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)

                Spacer()

                // Status indicator
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appMonitor.isMonitoring ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                        Text(appMonitor.isMonitoring ? "Monitoring Active" : "Monitoring Paused")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(settingsStore.rules.filter(\.isEnabled).count) rules active")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 16)
            }
            .frame(width: 180)
            .background(Color(NSColor.windowBackgroundColor))

        } detail: {
            Group {
                switch selectedTab {
                case .rules:
                    RulesView(showAddRule: $showAddRule)
                case .services:
                    ServicesView()
                case .general:
                    GeneralView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showAddRule) {
            AddRuleView()
                .environmentObject(appMonitor)
                .environmentObject(settingsStore)
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 18)
                .foregroundStyle(isSelected ? Color(hex: "#6c63ff") : .secondary)
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "#6c63ff").opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
