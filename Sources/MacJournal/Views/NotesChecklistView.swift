import SwiftUI

// MARK: - Notes Checklist Sync View

struct NotesChecklistView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notesService = NotesChecklistService.shared

    @State private var isSyncing = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var autoSync = false
    @State private var autoApply = false

    private let syncTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Apple Notes Sync")

                // ── Description ──
                Text("Syncs your TD List checklist from Apple Notes into today's KPI entry.\nUse [x] and [ ] markers in your note to track task completion.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineSpacing(4)

                // ── Auto-Sync Toggles ──
                HStack(spacing: 24) {
                    Toggle(isOn: $autoSync) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Sync")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Every 5 min")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(themeManager.colors.accent)

                    Toggle(isOn: $autoApply) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Apply")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Update today's entry")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(themeManager.colors.accent)
                    .disabled(!autoSync)

                    Spacer()
                }
                .padding(14)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // ── Sync Button ──
                Button(action: performSync) {
                    HStack(spacing: 10) {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13))
                        }
                        Text(isSyncing ? "Syncing..." : "Sync Now")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.colors.accent)
                    .foregroundColor(themeManager.colors.background)
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)

                // ── Results ──
                if let result = notesService.lastResult {
                    if let error = result.errorMessage {
                        ErrorStateView(message: error, themeManager: themeManager)
                    } else if result.isEmpty {
                        EmptyStateView(themeManager: themeManager)
                    } else {
                        // ── Professional Progress ──
                        SectionBox(title: "Professional Tasks") {
                            ChecklistProgressRow(
                                done: result.proDone,
                                total: result.proTotal,
                                ratio: result.proRatio,
                                color: themeManager.colors.accent
                            )
                        }

                        // ── Personal & Academic Progress ──
                        SectionBox(title: "Personal & Academic") {
                            ChecklistProgressRow(
                                done: result.perDone,
                                total: result.perTotal,
                                ratio: result.perRatio,
                                color: themeManager.colors.accentDim
                            )
                        }

                        // ── Totals ──
                        SectionBox(title: "Overall Progress") {
                            let totalDone = result.proDone + result.perDone
                            let totalAll = result.proTotal + result.perTotal
                            let overallRatio = totalAll > 0 ? Double(totalDone) / Double(totalAll) : 0
                            ChecklistProgressRow(
                                done: totalDone,
                                total: totalAll,
                                ratio: overallRatio,
                                color: themeManager.colors.accent
                            )
                        }

                        // ── Apply to Today Button ──
                        Button(action: applyToToday) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 13))
                                Text("Apply to Today's Entry")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(themeManager.colors.surface)
                            .foregroundColor(themeManager.colors.textPrimary)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(autoApply)
                    }

                    // ── Last Sync Timestamp ──
                    HStack {
                        Spacer()
                        Text("Last sync: \(formattedTime(result.lastSync))")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                } else {
                    InitialStateView(themeManager: themeManager)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(syncTimer) { _ in
            if autoSync {
                performSync()
            }
        }
        .onAppear {
            // Auto-sync on first appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                performSync()
            }
        }
    }

    // MARK: - Actions

    private func performSync() {
        guard !isSyncing else { return }
        isSyncing = true
        Task {
            let result = await notesService.sync()
            isSyncing = false

            // Auto-apply if enabled and result is valid
            if autoApply, result.errorMessage == nil, !result.isEmpty {
                applyResultToToday(result)
            }
        }
    }

    private func applyToToday() {
        guard let result = notesService.lastResult, result.errorMessage == nil else { return }
        applyResultToToday(result)
    }

    private func applyResultToToday(_ result: NotesChecklistResult) {
        let today = Date()

        if var todayEntry = store.entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            todayEntry.proTotal = result.proTotal
            todayEntry.proDone = result.proDone
            todayEntry.perTotal = result.perTotal
            todayEntry.perDone = result.perDone
            store.addOrUpdate(entry: &todayEntry)

            alertTitle = "Entry Updated"
            alertMessage = "Pro \(result.proDone)/\(result.proTotal) · Personal \(result.perDone)/\(result.perTotal)"
        } else {
            var newEntry = Entry(
                date: today,
                sleepHours: 7.0,
                socialMins: 0,
                breakfast: .standard,
                lunch: .standard,
                dinner: .standard,
                proTotal: result.proTotal,
                proDone: result.proDone,
                perTotal: result.perTotal,
                perDone: result.perDone,
                readingPages: 0,
                meditated: false
            )
            store.addOrUpdate(entry: &newEntry)

            alertTitle = "Entry Created"
            alertMessage = "Pro \(result.proDone)/\(result.proTotal) · Personal \(result.perDone)/\(result.perTotal)"
        }
        showAlert = true
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: date)
    }
}

// MARK: - Sub-Views

struct ErrorStateView: View {
    let message: String
    let themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(themeManager.colors.textMuted)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct EmptyStateView: View {
    let themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundColor(themeManager.colors.textMuted)
            Text("No checklist items found.\nAdd [x] and [ ] items to your TD List note.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct InitialStateView: View {
    let themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundColor(themeManager.colors.textMuted)
            Text("Tap \"Sync Now\" to read your TD List checklist.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Checklist Progress Row

struct ChecklistProgressRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let done: Int
    let total: Int
    let ratio: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(done)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
                Text("/ \(total) completed")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textSecondary)
                Spacer()
                Text("\(Int(round(ratio * 100)))%")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ratio > 0.5 ? color : themeManager.colors.textMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeManager.colors.borderFaint)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(ratio, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
