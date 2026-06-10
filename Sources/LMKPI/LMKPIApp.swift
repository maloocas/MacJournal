import SwiftUI
import AppKit

// MARK: - Main App Entry Point

@main
struct LMKPIApp: App {
    @StateObject private var store = DataStore.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var googleAuth = GoogleAuthManager()
    @StateObject private var googleServices: GoogleServicesManager = {
        let manager = GoogleServicesManager()
        // Register all Google Workspace integrations here.
        // Future services (Mail, Drive, Tasks) get registered the same way.
        manager.register(GoogleCalendarService())
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

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case tdList = "TD List"
        case journal = "Journal"
        case notes = "Notes"
        case dailyLog = "Daily Log"
        case trends = "Trends"
        case calendar = "Calendar"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .tdList: return "checklist.unchecked"
            case .journal: return "book.pages"
            case .notes: return "arrow.triangle.2.circlepath"
            case .dailyLog: return "square.and.pencil"
            case .trends: return "chart.xyaxis.line"
            case .calendar: return "calendar"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        // Only show Calendar tab if the service is registered
        let showCalendar = googleServices.service(named: "calendar") != nil

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

                // Navigation items — show Calendar only if registered
                ForEach(Tab.allCases.filter { tab in
                    if tab == .calendar { return showCalendar }
                    return true
                }, id: \.self) { tab in
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

                // Animated entry count
                Text("\(entryCount) entry\(entryCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .padding(.bottom, 20)
                    .onChange(of: store.entries.count) { newValue in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            entryCount = newValue
                        }
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

                NotesChecklistView()
                    .opacity(selectedTab == .notes ? 1 : 0)
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

                TrendsView()
                    .opacity(selectedTab == .trends ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showCalendar {
                    CalendarView()
                        .opacity(selectedTab == .calendar ? 1 : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Theme switcher pinned bottom-right
                ThemeSwitcher()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(themeManager.colors.background)
        .task {
            // Silently try to restore a previous Google session.
            // No gate — the app is always usable without auth.
            await googleAuth.restoreSessionIfAvailable()
            if googleAuth.isAuthenticated {
                await googleServices.configureAll(with: googleAuth)
            }
        }
    }
}
