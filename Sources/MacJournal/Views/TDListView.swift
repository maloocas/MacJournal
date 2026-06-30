import SwiftUI

// MARK: - Interactive TD List Tab

struct TDListView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var proNewText = ""
    @State private var perNewText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "TD List")

                progressOverviewCard

                Text("Tap to check, pencil to edit, trash to delete. Changes are saved locally and update today's KPI entry.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineSpacing(4)

                HStack {
                    PopOutButton()

                    Spacer()

                    if !store.checklistItems.isEmpty {
                        Text("\(store.checklistItems.count) items")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                }

                if store.checklistItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.colors.textMuted)
                        Text("No checklist items yet.\nAdd some below to get started.")
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

                let proItems = store.checklistItems.filter { $0.section == .professional }
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

                        if !proItems.isEmpty {
                            Divider().overlay(themeManager.colors.borderFaint)
                        }
                        addItemRow(section: .professional, text: $proNewText)
                    }
                }

                let perItems = store.checklistItems.filter { $0.section == .personal }
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

                        if !perItems.isEmpty {
                            Divider().overlay(themeManager.colors.borderFaint)
                        }
                        addItemRow(section: .personal, text: $perNewText)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)
        .alert("TD List", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Progress Overview Card

    private var progressOverviewCard: some View {
        let proDone = store.checklistItems.filter { $0.section == .professional && $0.isChecked }.count
        let proTotal = store.checklistItems.filter { $0.section == .professional }.count
        let perDone = store.checklistItems.filter { $0.section == .personal && $0.isChecked }.count
        let perTotal = store.checklistItems.filter { $0.section == .personal }.count

        return HStack(spacing: 18) {
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

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(perTotal > 0 ? Double(perDone) / Double(perTotal) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
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
.background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                store.addChecklistItem(section: section, text: trimmed)
                text.wrappedValue = ""
            }

            Button(action: {
                let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addChecklistItem(section: section, text: trimmed)
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

    // MARK: - Pop-Out Button

    struct PopOutButton: View {
        @EnvironmentObject var themeManager: ThemeManager

        var body: some View {
            Button(action: { PopOutWindowManager.shared.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                        .font(.system(size: 11))
                    Text("Pop Out")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(themeManager.colors.surface)
                .foregroundColor(themeManager.colors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Open TD List in a floating window")
        }
    }

    // MARK: - Actions

    private func toggleItem(_ item: ChecklistItem) {
        store.toggleChecklistItem(item)
        let proDone = store.checklistItems.filter { $0.section == .professional && $0.isChecked }.count
        let proTotal = store.checklistItems.filter { $0.section == .professional }.count
        let perDone = store.checklistItems.filter { $0.section == .personal && $0.isChecked }.count
        let perTotal = store.checklistItems.filter { $0.section == .personal }.count
        alertMessage = "Pro \(proDone)/\(proTotal) · Personal \(perDone)/\(perTotal)"
        showAlert = true
    }

    private func deleteItem(_ item: ChecklistItem) {
        store.deleteChecklistItem(item)
    }

    private func editItem(_ item: ChecklistItem, newText: String) {
        store.updateChecklistItemText(item, newText: newText)
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
            Button(action: onToggle) {
                HStack(spacing: 12) {
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
        themeManager.colors.accent
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
