import SwiftUI

// MARK: - Interactive TD List Tab

struct TDListView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var newItemTexts: [ChecklistItem.Priority: String] = [:]
    @State private var showClearAllConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "TD List")

                progressOverviewCard

                Text("Tap to check, use the drag handle to change priority, or edit and delete tasks. Changes are saved locally.")
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

                        Button(action: store.uncheckAllChecklistItems) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 11))
                                Text("Uncheck All")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(themeManager.colors.surface)
                            .foregroundColor(themeManager.colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.checklistItems.contains(where: \.isChecked))
                        .help("Uncheck all checked checklist items")

                        Button(action: { showClearAllConfirm = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Clear All")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(themeManager.colors.surface)
                            .foregroundColor(themeManager.colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove all checklist items except Daily and Upcoming")
                    }
                }
                .confirmationDialog("Clear all items except Daily and Upcoming?", isPresented: $showClearAllConfirm, titleVisibility: .visible) {
                    Button("Clear All", role: .destructive) {
                        store.clearChecklistItemsExceptDailyAndUpcoming()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes all checklist items except those in the Daily (P4) and Upcoming sections. This cannot be undone.")
                }

                prioritySections
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)

    }

    // MARK: - Priority Sections

    private var prioritySections: some View {
        VStack(spacing: 16) {
            ForEach(ChecklistItem.Priority.allCases, id: \.self) { priority in
                let items = store.checklistItems.filter { $0.priority == priority }
                SectionBox(title: "\(priority.title) (\(items.count))") {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                            ChecklistItemRow(
                                item: item,
                                onToggle: { toggleItem(item) },
                                onDelete: { deleteItem(item) },
                                onEdit: { newText in editItem(item, newText: newText) }
                            )
                            if items.last?.id != item.id {
                                Divider().overlay(themeManager.colors.borderFaint)
                            }
                        }

                        if !items.isEmpty {
                            Divider().overlay(themeManager.colors.borderFaint)
                        }
                        addItemRow(priority: priority, text: newItemText(for: priority))
                    }
                }
                .checklistPriorityDropTarget(
                    priority,
                    store: store,
                    accentColor: themeManager.colors.accent
                )
            }
        }
    }


    // MARK: - Priority Progress Overview

    private var progressOverviewCard: some View {
        HStack(spacing: 12) {
            let counts = TDListCounts(items: store.checklistItems)
            let totalItems = counts.totalItems
            let completedItems = counts.completedItems

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(completedItems)/\(totalItems)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Total")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)

            ForEach(ChecklistItem.Priority.progressCases, id: \.self) { priority in
                let items = store.checklistItems.filter { $0.priority == priority }
                let done = items.filter(\.isChecked).count
                let total = items.count

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: CGFloat(total > 0 ? Double(done) / Double(total) : 0))
                            .stroke(themeManager.colors.accent, lineWidth: 4)
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))

                        Text("\(done)/\(total)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeManager.colors.textPrimary)
                    }
                    Text(priority.title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
    }

    private func newItemText(for priority: ChecklistItem.Priority) -> Binding<String> {
        Binding(
            get: { newItemTexts[priority] ?? "" },
            set: { newItemTexts[priority] = $0 }
        )
    }

    private func addItemRow(priority: ChecklistItem.Priority, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 13))
                .foregroundColor(themeManager.colors.accent.opacity(0.6))

            TextField("Add task to \(priority.title)...", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(themeManager.colors.textPrimary)
                .onSubmit {
                    let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.addChecklistItem(priority: priority, text: trimmed)
                    text.wrappedValue = ""
                }

            Button(action: {
                let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addChecklistItem(priority: priority, text: trimmed)
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
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundColor(themeManager.colors.textMuted)
                .help("Drag to change priority")
                .draggable(item.id.uuidString)

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


private struct ChecklistPriorityDropTarget: ViewModifier {
    let priority: ChecklistItem.Priority
    let store: DataStore
    let accentColor: Color

    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .dropDestination(for: String.self) { identifiers, _ in
                guard let id = identifiers.compactMap({ UUID(uuidString: $0) }).first else { return false }
                return store.moveChecklistItem(id: id, to: priority)
            } isTargeted: { isTargeted = $0 }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isTargeted ? accentColor : .clear, lineWidth: isTargeted ? 2 : 0)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func checklistPriorityDropTarget(
        _ priority: ChecklistItem.Priority,
        store: DataStore,
        accentColor: Color
    ) -> some View {
        modifier(ChecklistPriorityDropTarget(priority: priority, store: store, accentColor: accentColor))
    }
}

// MARK: - Daily Goal Row (with edit + delete)

struct DailyGoalRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let goal: DailyGoal
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
                                goal.isChecked ? color : themeManager.colors.textMuted,
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                            .background(
                                goal.isChecked ? color.opacity(0.15) : Color.clear
                            )

                        if goal.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                        }
                    }

                    if isEditing {
                        TextField("Goal text", text: $editedText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .focused($isFocused)
                            .onSubmit { commitEdit() }
                            .onAppear {
                                editedText = goal.text
                                isFocused = true
                            }
                    } else {
                        Text(goal.text)
                            .font(.system(size: 13, weight: goal.isChecked ? .regular : .medium))
                            .foregroundColor(
                                goal.isChecked ? themeManager.colors.textMuted : themeManager.colors.textPrimary
                            )
                            .strikethrough(goal.isChecked, color: themeManager.colors.textMuted)
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
                        editedText = goal.text
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
        guard !trimmed.isEmpty, trimmed != goal.text else {
            isEditing = false
            return
        }
        isEditing = false
        onEdit?(trimmed)
    }
}
