import SwiftUI

// MARK: - Interactive TD List Tab

struct TDListView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notesService = NotesChecklistService.shared

    @State private var isLoading = true
    @State private var items: [ChecklistItem] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "TD List")

                // ── Description ──
                Text("Tap an item to check it off. Changes sync to Apple Notes and update today's KPI entry.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineSpacing(4)

                // ── Progress Overview ──
                overviewCard

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
                    if !proItems.isEmpty {
                        SectionBox(title: "Professional (\(proItems.count))") {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(proItems.enumerated()), id: \.element.id) { _, item in
                                    ChecklistItemRow(
                                        item: item,
                                        onToggle: { toggleItem(item) }
                                    )
                                    if proItems.last?.id != item.id {
                                        Divider()
                                            .overlay(themeManager.colors.borderFaint)
                                    }
                                }
                            }
                        }
                    }

                    // Personal Section
                    let perItems = items.filter { $0.section == .personal }
                    if !perItems.isEmpty {
                        SectionBox(title: "Personal & Academic (\(perItems.count))") {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(perItems.enumerated()), id: \.element.id) { _, item in
                                    ChecklistItemRow(
                                        item: item,
                                        onToggle: { toggleItem(item) }
                                    )
                                    if perItems.last?.id != item.id {
                                        Divider()
                                            .overlay(themeManager.colors.borderFaint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)
        .alert("TD List Synced", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadItems()
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
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
    }

    // MARK: - Actions

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
            // Reload local state from service
            items = notesService.items

            let proDone = items.filter { $0.section == .professional && $0.isChecked }.count
            let proTotal = items.filter { $0.section == .professional }.count
            let perDone = items.filter { $0.section == .personal && $0.isChecked }.count
            let perTotal = items.filter { $0.section == .personal }.count

            alertMessage = "Pro \(proDone)/\(proTotal) · Personal \(perDone)/\(perTotal)"
            showAlert = true
        }
    }
}

// MARK: - Checklist Item Row

struct ChecklistItemRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Custom checkbox
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

                // Task text
                Text(item.text)
                    .font(.system(size: 13, weight: item.isChecked ? .regular : .medium))
                    .foregroundColor(
                        item.isChecked ? themeManager.colors.textMuted : themeManager.colors.textPrimary
                    )
                    .strikethrough(item.isChecked, color: themeManager.colors.textMuted)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var color: Color {
        item.section == .professional ? themeManager.colors.accent : themeManager.colors.accentDim
    }
}
