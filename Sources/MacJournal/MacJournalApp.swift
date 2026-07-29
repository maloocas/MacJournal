import SwiftUI
import AppKit

// MARK: - Main App Entry Point

@main
struct MacJournalApp: App {
    @StateObject private var store = DataStore.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Enforce GPU-accelerated layer backing for all windows
                    NSApp.windows.forEach { window in
                        window.backgroundColor = NSColor(white: 0.04, alpha: 1)
                        window.contentView?.wantsLayer = true
                        window.contentView?.canDrawSubviewsIntoLayer = true
                        // Keep the window smooth during live resize
                        window.preservesContentDuringLiveResize = true
                    }
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

    private func importLegacyData() {
        let panel = NSOpenPanel()
        panel.title = "Import Web App Data"
        panel.message = "Select the JSON file exported from the MacJournal web app (localStorage data)."
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
        panel.title = "Import MacJournal Data"
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
}

// MARK: - Content View (Tab Container)

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @Namespace private var sidebarNamespace
    @State private var selectedTab: Tab = .dashboard
    @State private var entryCount: Int = 0
    @State private var showSettingsPopup = false
    @State private var settingsReadingTarget: Int = 50
    @State private var settingsSocialWeight: Double = 0.25
    @State private var settingsSleepMin: Double = 7.0
    @State private var settingsSleepMax: Double = 9.0
    @State private var settingsSleepPenalty: Double = 6.0
    @State private var settingsTDCheckoffTracking = false
    @State private var settingsStatsWindowDays: Int = 30
    @State private var settingsMorningBriefingEnabled = false
    @State private var settingsLLMApiKey = ""
    @State private var settingsLLMModel = "deepseek-v4-flash"
    @State private var settingsAccentColor = "blue"
    @State private var settingsShowAlert = false

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case dailyLog = "Daily Log"
        case tdList = "TD List"
        case stats = "Stats"
        case insights = "Insights"
        case journal = "Journal"
        case goals = "Goals"
        case subscriptions = "Subscriptions"
        case trapShooting = "Trap Shooting"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .tdList: return "checklist.unchecked"
            case .journal: return "book.pages"
            case .dailyLog: return "square.and.pencil"
            case .stats: return "chart.xyaxis.line"
            case .insights: return "lightbulb"
            case .goals: return "target"
            case .subscriptions: return "creditcard"
            case .trapShooting: return "scope"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // --- Sidebar ---
            VStack(spacing: 0) {
                Text("MJ")
                    .font(.system(size: 22, weight: .black))
                    .textCase(.uppercase)
                    .tracking(4)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(alignment: .bottom) {
                        themeManager.colors.sectionDivider.frame(height: 1)
                    }

                // Apple-style sidebar items with continuous rounded corners
                VStack(spacing: 2) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab
                        Button(action: {
                            withAnimation(.snappy(duration: 0.35)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .frame(width: 18)
                                    .foregroundColor(isSelected ? themeManager.colors.accent : themeManager.colors.textSecondary)
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(isSelected ? themeManager.colors.textPrimary : themeManager.colors.textSecondary)
                            .background(
                                Group {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(themeManager.colors.accent.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(themeManager.colors.accent.opacity(0.25), lineWidth: 1)
                                            )
                                            .matchedGeometryEffect(id: "sidebarHighlight", in: sidebarNamespace)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .animation(.snappy(duration: 0.35), value: selectedTab)

                Spacer()

                HStack(spacing: 0) {
                    Button(action: { showSettingsPopup = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(.leading, 18)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    Spacer()

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
            .frame(minWidth: 240, maxWidth: 240)
            .background(themeManager.colors.sidebarBg)
            .onAppear { entryCount = store.entries.count }

            // --- Tab Content ---
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.snappy(duration: 0.35), value: selectedTab)
        }
        .frame(minWidth: 1000, minHeight: 500)
        .background(themeManager.colors.background)
        .overlay {
            if showSettingsPopup {
                settingsPopupOverlay
            }
        }
    }

    // MARK: - Tab Content (lazy rendering)

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
                .transition(.opacity)
        case .tdList:
            TDListView()
                .transition(.opacity)
        case .journal:
            JournalView()
                .transition(.opacity)
        case .dailyLog:
            DailyLogView(isVisible: true)
                .transition(.opacity)
        case .stats:
            StatsView()
                .transition(.opacity)
        case .insights:
            InsightsView()
                .transition(.opacity)
        case .goals:
            GoalsView()
                .transition(.opacity)
        case .subscriptions:
            SubscriptionsView()
                .transition(.opacity)
        case .trapShooting:
            TrapShootingView()
                .transition(.opacity)
        }
    }

    // MARK: - Settings Popup

    @ViewBuilder
    private var settingsPopupOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { showSettingsPopup = false }

            VStack(spacing: 0) {
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        settingsSection("ACADEMIC & BEHAVIORAL TARGETS") {
                            HStack(spacing: 16) {
                                settingsField("Reading Target (Pages)", value: $settingsReadingTarget)
                                settingsField("Social Weight (Penalty)", value: $settingsSocialWeight)
                            }
                        }

                        settingsSection("SLEEP OPTIMIZATION (HOURS)") {
                            HStack(spacing: 16) {
                                settingsField("Target Minimum", value: $settingsSleepMin)
                                settingsField("Target Maximum", value: $settingsSleepMax)
                                settingsField("Penalty Threshold (<)", value: $settingsSleepPenalty)
                            }
                        }

                        settingsSection("STATS DISPLAY") {
                            settingsField("Chart Window (Days)", value: $settingsStatsWindowDays)
                        }

                        settingsSection("ACCENT COLOR") {
                            accentColorPicker
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("TD LIST TRACKING")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .padding(.horizontal, 20)

                            Toggle(isOn: $settingsTDCheckoffTracking) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Track Check-Off Timestamps")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Record when items are checked/unchecked for future analytics")
                                        .font(.system(size: 10))
                                        .foregroundColor(themeManager.colors.textMuted)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(themeManager.colors.accent)
                            .padding(.horizontal, 20)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("LLM INTEGRATION")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .padding(.horizontal, 20)

                            Toggle(isOn: $settingsMorningBriefingEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Morning Briefing (DeepSeek)")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("AI-powered daily summary with personalized suggestions")
                                        .font(.system(size: 10))
                                        .foregroundColor(themeManager.colors.textMuted)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(themeManager.colors.accent)
                            .padding(.horizontal, 20)

                            if settingsMorningBriefingEnabled {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Model")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(themeManager.colors.textSecondary)
                                    Picker("", selection: $settingsLLMModel) {
                                        ForEach(LLMProvider.deepseek.availableModels, id: \.id) { model in
                                            Text(model.label).tag(model.id)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                }
                                .padding(.horizontal, 20)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DeepSeek API Key")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(themeManager.colors.textSecondary)
                                    SecureField("sk-...", text: $settingsLLMApiKey)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(themeManager.colors.textPrimary)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(themeManager.colors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .padding(.horizontal, 20)
                            }
                        }

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
                                    .background(themeManager.colors.surface)
                                    .foregroundColor(themeManager.colors.textPrimary)
                            }
                            .buttonStyle(.plain)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 20)
                        }

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
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        Spacer().frame(height: 8)
                    }
                }
            }
            .frame(width: 500, height: 540)
            .background(themeManager.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(themeManager.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onAppear {
                loadSettings()
            }
            .alert("Configuration Updated", isPresented: $settingsShowAlert) {
                Button("OK") {}
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: showSettingsPopup)
    }

    @ViewBuilder
    private func settingsField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .foregroundColor(themeManager.colors.textPrimary)
                .font(.system(size: 13))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func settingsField(_ label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .foregroundColor(themeManager.colors.textPrimary)
                .font(.system(size: 13))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundColor(themeManager.colors.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            content()
                .padding(.horizontal, 20)
        }
    }

    private var accentColorPicker: some View {
        HStack(spacing: 10) {
            ForEach(AccentOption.all) { option in
                let isSelected = settingsAccentColor == option.id
                Button(action: { settingsAccentColor = option.id }) {
                    Circle()
                        .fill(option.base)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5)
                                .padding(2)
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.black.opacity(0.3) : Color.clear, lineWidth: 4.5)
                        )
                        .shadow(color: option.base.opacity(isSelected ? 0.6 : 0.2), radius: isSelected ? 8 : 4)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
                .buttonStyle(.plain)
                .help(option.label)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadSettings() {
        settingsReadingTarget = store.config.readingTarget
        settingsSocialWeight = store.config.socialWeight
        settingsSleepMin = store.config.sleepMin
        settingsSleepMax = store.config.sleepMax
        settingsSleepPenalty = store.config.sleepPenaltyThreshold
        settingsTDCheckoffTracking = store.config.tdCheckoffTracking
        settingsStatsWindowDays = store.config.statsWindowDays
        settingsMorningBriefingEnabled = store.config.llmConfig.morningBriefingEnabled
        settingsLLMApiKey = store.config.llmConfig.apiKey
        settingsLLMModel = store.config.llmConfig.model
        settingsAccentColor = store.config.accentColor
    }

    private func saveSettings() {
        var llmConfig = store.config.llmConfig
        llmConfig.morningBriefingEnabled = settingsMorningBriefingEnabled
        llmConfig.apiKey = settingsLLMApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        llmConfig.model = settingsLLMModel
        let newConfig = AppConfig(
            readingTarget: max(1, settingsReadingTarget),
            socialWeight: max(0, settingsSocialWeight),
            sleepMin: max(0, settingsSleepMin),
            sleepMax: max(settingsSleepMin, settingsSleepMax),
            sleepPenaltyThreshold: max(0, min(settingsSleepPenalty, settingsSleepMin)),
            tdCheckoffTracking: settingsTDCheckoffTracking,
            statsWindowDays: max(1, settingsStatsWindowDays),
            accentColor: settingsAccentColor,
            llmConfig: llmConfig
        )
        store.updateConfig(newConfig)
        ThemeManager.shared.applyAccent(settingsAccentColor)
        settingsShowAlert = true
    }
}
