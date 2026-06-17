import SwiftUI
import AppKit

// MARK: - Main App Entry Point

@main
struct LMKPIApp: App {
    @StateObject private var store = DataStore.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var googleAuth = GoogleAuthManager()
    @StateObject private var googleServices: GoogleServicesManager = {
        let manager = GoogleServicesManager()
        // Future Google Workspace integrations registered here.
        return manager
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .environmentObject(googleAuth)
                .environmentObject(googleServices)
                .preferredColorScheme(themeManager.effectiveColorScheme)
                .onAppear {
                    applyTerminalStyle()
                }
                .onChange(of: themeManager.theme) { _ in
                    applyTerminalStyle()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .importExport) {
                Divider()
                Button("Import from Web App (JSON)...") {
                    importLegacyData()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export Data...") {
                    _ = store.exportJSON(savePanel: true)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Import JSON Data...") {
                    importStandardData()
                }
            }
        }
    }

    // MARK: - Import helpers (unchanged)

    private func importLegacyData() {
        let panel = NSOpenPanel()
        panel.title = "Import Web App Data"
        panel.message = "Select the JSON file exported from the LM KPI web app (localStorage data)."
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let count = try store.importLegacyJSON(url: url)
            let alert = NSAlert()
            alert.messageText = "Import Complete"
            alert.informativeText = "Successfully imported \(count) entries from the web app."
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Import Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func importStandardData() {
        let panel = NSOpenPanel()
        panel.title = "Import LMKPI Data"
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let (imported, skipped) = try store.importJSON(url: url)
            let alert = NSAlert()
            alert.messageText = "Import Complete"
            alert.informativeText = "Imported \(imported) entries. Skipped \(skipped) duplicates."
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Import Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    // MARK: - Theme application

    private func applyTerminalStyle() {
        switch themeManager.theme {
        case .dark, .blue:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        let bgColor: NSColor
        switch themeManager.theme {
        case .dark: bgColor = NSColor.black
        case .blue: bgColor = NSColor(red: 0.04, green: 0.09, blue: 0.16, alpha: 1)
        case .light: bgColor = NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        }
        NSApp.windows.forEach { win in
            win.backgroundColor = bgColor
        }
    }
}

// MARK: - Content View (Tab Container)

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var googleAuth: GoogleAuthManager
    @EnvironmentObject var googleServices: GoogleServicesManager
    @State private var selectedTab: Tab = .dashboard
    @State private var entryCount: Int = 0
    @State private var showSettingsPopup = false
    @State private var settingsReadingTarget: Int = 50
    @State private var settingsSocialWeight: Double = 0.25
    @State private var settingsSleepMin: Double = 7.0
    @State private var settingsSleepMax: Double = 9.0
    @State private var settingsSleepPenalty: Double = 6.0
    @State private var settingsShowAlert = false

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case tdList = "TD List"
        case journal = "Journal"
        case dailyLog = "Daily Log"
        case stats = "Stats"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .tdList: return "checklist.unchecked"
            case .journal: return "book.pages"
            case .dailyLog: return "square.and.pencil"
            case .stats: return "chart.xyaxis.line"
            }
        }
    }

    var body: some View {
        HSplitView {
            // ── Sidebar ──
            VStack(spacing: 0) {
                // App title
                Text("LM KPI")
                    .font(.system(size: 22, weight: .black))
                    .textCase(.uppercase)
                    .tracking(4)
                    .padding(.vertical, 30)
                    .overlay(alignment: .bottom) {
                        themeManager.colors.sectionDivider.frame(height: 1)
                    }

                // Navigation items
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                .textCase(.uppercase)
                                .tracking(1.5)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(selectedTab == tab ? themeManager.colors.accent.opacity(0.12) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Bottom bar: settings gear + entry count
                HStack(spacing: 0) {
                    // Settings gear button (bottom-left)
                    Button(action: {
                        showSettingsPopup = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(.leading, 18)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Animated entry count
                    Text("\(entryCount) entry\(entryCount == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                        .padding(.trailing, 18)
                        .padding(.vertical, 14)
                        .onChange(of: store.entries.count) { newValue in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                entryCount = newValue
                            }
                        }
                }
                .overlay(alignment: .top) {
                    themeManager.colors.sectionDivider.frame(height: 1)
                }
            }
            .frame(minWidth: 170, idealWidth: 190, maxWidth: 210)
            .background(themeManager.colors.sidebarBg)
            .onAppear { entryCount = store.entries.count }

            // ── Tab Content ──
            ZStack {
                DashboardView()
                    .opacity(selectedTab == .dashboard ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                TDListView()
                    .opacity(selectedTab == .tdList ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                JournalView()
                    .opacity(selectedTab == .journal ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                DailyLogView()
                    .opacity(selectedTab == .dailyLog ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                StatsView()
                    .opacity(selectedTab == .stats ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1000, minHeight: 500)
        .background(themeManager.colors.background)
        .task {
            // Silently try to restore a previous Google session.
            // No gate — the app is always usable without auth.
            await googleAuth.restoreSessionIfAvailable()
            if googleAuth.isAuthenticated {
                await googleServices.configureAll(with: googleAuth)
            }
        }
        // ── Settings Popup Overlay ──
        .overlay {
            if showSettingsPopup {
                ZStack {
                    // Dimmed backdrop — tap to close
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showSettingsPopup = false
                        }

                    // Popup card
                    VStack(spacing: 0) {
                        // Title bar
                        HStack {
                            Text("Settings")
                                .font(.system(size: 14, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(2)
                                .foregroundColor(themeManager.colors.textPrimary)

                            Spacer()

                            Button(action: { showSettingsPopup = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.colors.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .overlay(alignment: .bottom) {
                            themeManager.colors.sectionDivider.frame(height: 1)
                        }

                        // ── Settings Form ──
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Academic & Behavioral Targets
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ACADEMIC & BEHAVIORAL TARGETS")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(2)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Reading Target (Pages)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(themeManager.colors.textSecondary)
                                            TextField("50", value: $settingsReadingTarget, format: .number)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(themeManager.colors.textPrimary)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(themeManager.colors.card)
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Social Weight (Penalty)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(themeManager.colors.textSecondary)
                                            TextField("0.25", value: $settingsSocialWeight, format: .number)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(themeManager.colors.textPrimary)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(themeManager.colors.card)
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }

                                // Sleep Optimization
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SLEEP OPTIMIZATION (HOURS)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(2)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .padding(.horizontal, 20)

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Target Minimum")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(themeManager.colors.textSecondary)
                                            TextField("7", value: $settingsSleepMin, format: .number)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(themeManager.colors.textPrimary)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(themeManager.colors.card)
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Target Maximum")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(themeManager.colors.textSecondary)
                                            TextField("9", value: $settingsSleepMax, format: .number)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(themeManager.colors.textPrimary)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(themeManager.colors.card)
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Penalty Threshold (<)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(themeManager.colors.textSecondary)
                                            TextField("6", value: $settingsSleepPenalty, format: .number)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(themeManager.colors.textPrimary)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(themeManager.colors.card)
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }

                                // Theme Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("APPEARANCE")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(2)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .padding(.horizontal, 20)

                                    HStack(spacing: 12) {
                                        ForEach(AppTheme.allCases, id: \.self) { theme in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    themeManager.theme = theme
                                                }
                                            }) {
                                                HStack(spacing: 8) {
                                                    Circle()
                                                        .fill(themePreviewColor(theme))
                                                        .frame(width: 10, height: 10)
                                                        .overlay(Circle().stroke(
                                                            themeManager.theme == theme
                                                                ? themeManager.colors.accent
                                                                : themeManager.colors.borderFaint,
                                                            lineWidth: themeManager.theme == theme ? 1.5 : 0.5
                                                        ))
                                                    Text(theme.displayName)
                                                        .font(.system(size: 11, weight: themeManager.theme == theme ? .semibold : .medium))
                                                        .textCase(.uppercase)
                                                        .tracking(1)
                                                        .foregroundColor(themeManager.theme == theme
                                                            ? themeManager.colors.accent
                                                            : themeManager.colors.textSecondary)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    themeManager.theme == theme
                                                        ? themeManager.colors.accent.opacity(0.1)
                                                        : themeManager.colors.card
                                                )
                                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(
                                                    themeManager.theme == theme
                                                        ? themeManager.colors.accent
                                                        : themeManager.colors.borderFaint
                                                ))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }

                                // Data Management
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("DATA MANAGEMENT")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(2)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .padding(.horizontal, 20)

                                    Button(action: {
                                        showSettingsPopup = false
                                        _ = store.exportCSV(savePanel: true)
                                    }) {
                                        Text("Export All Data (CSV)")
                                            .font(.system(size: 11, weight: .bold))
                                            .textCase(.uppercase)
                                            .tracking(3)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(themeManager.colors.card)
                                            .foregroundColor(themeManager.colors.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                    .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint, lineWidth: 1))
                                    .padding(.horizontal, 20)
                                }

                                // Update button
                                Button(action: saveSettings) {
                                    Text("Update Configuration")
                                        .font(.system(size: 11, weight: .bold))
                                        .textCase(.uppercase)
                                        .tracking(3)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(themeManager.colors.accent)
                                        .foregroundColor(themeManager.colors.background)
                                }
                                .buttonStyle(.plain)
                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.accent, lineWidth: 1))
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                                Spacer().frame(height: 8)
                            }
                        }
                    }
                    .frame(width: 500, height: 420)
                    .background(themeManager.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(themeManager.colors.border, lineWidth: 1)
                    )
                    .onAppear { loadSettings() }
                    .alert("Configuration Updated", isPresented: $settingsShowAlert) {
                        Button("OK") {}
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showSettingsPopup)
            }
        }
    }

    // MARK: - Settings helpers

    private func loadSettings() {
        settingsReadingTarget = store.config.readingTarget
        settingsSocialWeight = store.config.socialWeight
        settingsSleepMin = store.config.sleepMin
        settingsSleepMax = store.config.sleepMax
        settingsSleepPenalty = store.config.sleepPenaltyThreshold
    }

    private func saveSettings() {
        let newConfig = AppConfig(
            readingTarget: max(1, settingsReadingTarget),
            socialWeight: max(0, settingsSocialWeight),
            sleepMin: max(0, settingsSleepMin),
            sleepMax: max(settingsSleepMin, settingsSleepMax),
            sleepPenaltyThreshold: max(0, min(settingsSleepPenalty, settingsSleepMin))
        )
        store.updateConfig(newConfig)
        settingsShowAlert = true
    }

    private func themePreviewColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .dark: return Color.black
        case .blue: return Color(red: 0.36, green: 0.61, blue: 0.84)
        case .light: return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }
}
