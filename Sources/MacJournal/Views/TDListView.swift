import SwiftUI

// MARK: - Interactive TD List Tab (with Progress + Notes Sync)

struct TDListView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notesService = NotesChecklistService.shared

    @State private var isLoading = true
    @State private var items: [ChecklistItem] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Add-item state
    @State private var proNewText = ""
    @State private var perNewText = ""

    // Notes sync state
    @State private var isSyncing = false
    @State private var alertTitle = ""
    @State private var autoSync = false
    @State private var autoApply = false

    private let syncTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "TD List")

                // ── Today's Progress Rings ──
                progressOverviewCard

                // ── Description ──
                Text("Tap to check, pencil to edit, trash to delete. Changes sync to Apple Notes and update today's KPI entry.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineSpacing(4)

                // ── Refresh Button ──
                HStack {
                    Button(action: loadItems) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            Text(isLoading ? "Loading..." : "Refresh from Notes")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeManager.colors.surface)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Spacer()

                    if !items.isEmpty {
                        Text("\(items.count) items")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                }

                // ── Checklist Items ──
                if items.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.colors.textMuted)
                        Text("No checklist items found.\nAdd [x] / [ ] items to your TD List note.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(themeManager.colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
                } else {
                    // Professional Section
                    let proItems = items.filter { $0.section == .professional }
                    SectionBox(title: "Professional (\(proItems.count))") {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(proItems.enumerated()), id: \.element.id) { _, item in
                                ChecklistItemRow(
                                    item: item,
                                    onToggle: { toggleItem(item) },
                                    onDelete: { deleteItem(item) },
                                    onEdit: { newText in editItem(item, newText: newText) }
                                )
                                if proItems.last?.id != item.id {
                                    Divider()
                                        .overlay(themeManager.colors.borderFaint)
                                }
                            }

                            // Add new Professional item
                            if !proItems.isEmpty {
                                Divider().overlay(themeManager.colors.borderFaint)
                            }
                            addItemRow(section: .professional, text: $proNewText)
                        }
                    }

                    // Personal Section
                    let perItems = items.filter { $0.section == .personal }
                    SectionBox(title: "Personal & Academic (\(perItems.count))") {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(perItems.enumerated()), id: \.element.id) { _, item in
                                ChecklistItemRow(
                                    item: item,
                                    onToggle: { toggleItem(item) },
                                    onDelete: { deleteItem(item) },
                                    onEdit: { newText in editItem(item, newText: newText) }
                                )
                                if perItems.last?.id != item.id {
                                    Divider()
                                        .overlay(themeManager.colors.borderFaint)
                                }
                            }

                            // Add new Personal item
                            if !perItems.isEmpty {
                                Divider().overlay(themeManager.colors.borderFaint)
                            }
                            addItemRow(section: .personal, text: $perNewText)
                        }
                    }
                }

                // ── Divider before Notes Sync section ──
                themeManager.colors.sectionDivider.frame(height: 1)
                    .padding(.vertical, 8)

                // ══════════════════════════════════════════════
                // Notes Sync Section (merged from Notes tab)
                // ══════════════════════════════════════════════

                SectionHeader(title: "Notes Sync")

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
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))

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
                            .background(themeManager.colors.card)
                            .foregroundColor(themeManager.colors.textPrimary)
                            .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.accent))
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
            loadItems()
            // Auto-sync on first appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                performSync()
            }
        }
    }

    // MARK: - Progress Overview Card (moved from Stats)

    private var progressOverviewCard: some View {
        let proDone = items.filter { $0.section == .professional && $0.isChecked }.count
        let proTotal = items.filter { $0.section == .professional }.count
        let perDone = items.filter { $0.section == .personal && $0.isChecked }.count
        let perTotal = items.filter { $0.section == .personal }.count

        return HStack(spacing: 18) {
            // Professional ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(proTotal > 0 ? Double(proDone) / Double(proTotal) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(proDone)/\(proTotal)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Professional")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Personal ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(perTotal > 0 ? Double(perDone) / Double(perTotal) : 0))
                        .stroke(themeManager.colors.accentDim, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(perDone)/\(perTotal)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Personal")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Overall
            let totalDone = proDone + perDone
            let totalAll = proTotal + perTotal
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(totalAll > 0 ? Double(totalDone) / Double(totalAll) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(totalDone)/\(totalAll)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Total")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
        .padding(.horizontal)
    }

    // MARK: - Add Item Row

    private func addItemRow(section: ChecklistItem.Section, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 13))
                .foregroundColor(themeManager.colors.accent.opacity(0.6))

            TextField(
                section == .professional ? "Add professional task..." : "Add personal task...",
                text: text
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(themeManager.colors.textPrimary)
            .onSubmit {
                let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                Task {
                    await notesService.addItem(section: section, text: trimmed, store: store)
                    items = notesService.items
                }
                text.wrappedValue = ""
            }

            Button(action: {
                let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                Task {
                    await notesService.addItem(section: section, text: trimmed, store: store)
                    items = notesService.items
                }
                text.wrappedValue = ""
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(
                        text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? themeManager.colors.textMuted
                            : themeManager.colors.accent
                    )
            }
            .buttonStyle(.plain)
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    // MARK: - TD List Actions

    private func loadItems() {
        isLoading = true
        Task {
            let fetched = await notesService.fetchItems()
            items = fetched
            isLoading = false
        }
    }

    private func toggleItem(_ item: ChecklistItem) {
        Task {
            await notesService.toggleItem(item, store: store)
            items = notesService.items

            let proDone = items.filter { $0.section == .professional && $0.isChecked }.count
            let proTotal = items.filter { $0.section == .professional }.count
            let perDone = items.filter { $0.section == .personal && $0.isChecked }.count
            let perTotal = items.filter { $0.section == .personal }.count

            alertTitle = "TD List Synced"
            alertMessage = "Pro \(proDone)/\(proTotal) · Personal \(perDone)/\(perTotal)"
            showAlert = true
        }
    }

    private func deleteItem(_ item: ChecklistItem) {
        Task {
            await notesService.deleteItem(item, store: store)
            items = notesService.items
        }
    }

    private func editItem(_ item: ChecklistItem, newText: String) {
        Task {
            await notesService.updateItemText(item, newText: newText, store: store)
            items = notesService.items
        }
    }

    // MARK: - Notes Sync Actions

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

// MARK: - Checklist Item Row (with edit + delete)

struct ChecklistItemRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let item: ChecklistItem
    let onToggle: () -> Void
    var onDelete: (() -> Void)?
    var onEdit: ((String) -> Void)?

    @State private var isEditing = false
    @State private var editedText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Main row: checkbox + text, entire width tappable for toggle
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Checkbox icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                item.isChecked ? color : themeManager.colors.textMuted,
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                            .background(
                                item.isChecked ? color.opacity(0.15) : Color.clear
                            )

                        if item.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                        }
                    }

                    // Text or Edit Field
                    if isEditing {
                        TextField("Item text", text: $editedText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .focused($isFocused)
                            .onSubmit { commitEdit() }
                            .onAppear {
                                editedText = item.text
                                isFocused = true
                            }
                    } else {
                        Text(item.text)
                            .font(.system(size: 13, weight: item.isChecked ? .regular : .medium))
                            .foregroundColor(
                                item.isChecked ? themeManager.colors.textMuted : themeManager.colors.textPrimary
                            )
                            .strikethrough(item.isChecked, color: themeManager.colors.textMuted)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Edit button (pencil)
            if onEdit != nil {
                Button(action: {
                    if isEditing {
                        commitEdit()
                    } else {
                        editedText = item.text
                        isEditing = true
                        isFocused = true
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(isEditing ? color : themeManager.colors.textMuted)
                }
                .buttonStyle(.plain)
                .help(isEditing ? "Save" : "Edit")
            }

            // Delete button (trash)
            if onDelete != nil {
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.textMuted.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var color: Color {
        item.section == .professional ? themeManager.colors.accent : themeManager.colors.accentDim
    }

    private func commitEdit() {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != item.text else {
            isEditing = false
            return
        }
        isEditing = false
        onEdit?(trimmed)
    }
}
