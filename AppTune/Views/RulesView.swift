import SwiftUI
import AppKit

struct RulesView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Binding var showAddRule: Bool
    @State private var editingRule: AppRule? = nil
    @State private var searchText = ""

    var filteredRules: [AppRule] {
        if searchText.isEmpty { return settingsStore.rules }
        return settingsStore.rules.filter {
            $0.appName.localizedCaseInsensitiveContains(searchText) ||
            $0.playlistName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Rules")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Play music automatically when you open apps")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { showAddRule = true }) {
                    Label("Add Rule", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#6c63ff"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Search rules...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Divider()

            // Rules List
            if filteredRules.isEmpty {
                EmptyRulesView(showAddRule: $showAddRule)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredRules) { rule in
                            RuleRowView(rule: rule) {
                                editingRule = rule
                            } onToggle: {
                                var updated = rule
                                updated.isEnabled.toggle()
                                settingsStore.updateRule(updated)
                            } onDelete: {
                                settingsStore.removeRule(id: rule.id)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(item: $editingRule) { rule in
            AddRuleView(editingRule: rule)
                .environmentObject(AppMonitorService.shared)
                .environmentObject(settingsStore)
        }
    }
}

// MARK: - Rule Row
struct RuleRowView: View {
    let rule: AppRule
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 40, height: 40)
                if let iconPath = rule.appIconPath,
                   let img = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: img)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.appName)
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 6) {
                    ServiceBadge(service: rule.service)
                    Text("→")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 11))
                    Text(rule.playlistName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    if rule.triggerOnLaunch {
                        TagChip(label: "On Launch", color: Color(hex: "#10b981"))
                    }
                    if rule.triggerOnFocus {
                        TagChip(label: "On Focus", color: Color(hex: "#3b82f6"))
                    }
                }
            }

            Spacer()

            // Controls
            if isHovering {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit rule")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Delete rule")
                }
                .padding(.trailing, 4)
            }

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        )
        .opacity(rule.isEnabled ? 1.0 : 0.5)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Service Badge
struct ServiceBadge: View {
    let service: MusicService
    var body: some View {
        Text(service.rawValue)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(service == .appleMusic ?
                Color(hex: "#fc3c44").opacity(0.15) :
                Color(hex: "#1db954").opacity(0.15)
            )
            .foregroundStyle(service == .appleMusic ?
                Color(hex: "#fc3c44") :
                Color(hex: "#1db954")
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: 9))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Empty State
struct EmptyRulesView: View {
    @Binding var showAddRule: Bool
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "#6c63ff").opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "music.note.list")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "#6c63ff"))
            }
            Text("No Rules Yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text("Add rules to automatically play music\nwhen you open specific apps.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Your First Rule") {
                showAddRule = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#6c63ff"))
            Spacer()
        }
        .padding()
    }
}
