import SwiftUI

// MARK: - Goals Tab

struct GoalsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var newGoalText = ""
    @State private var newGoalDueDate = Date()
    @State private var editingGoalID: UUID? = nil
    @State private var editingText = ""
    @State private var editingDueDate = Date()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Goals")

                // ── Add Goal Bar ──
                addGoalBar

                // ── Goals List ──
                if store.goals.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.goals) { goal in
                            goalCard(goal)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)
    }

    // MARK: - Add Goal Bar

    private var addGoalBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("Add a new goal...", text: $newGoalText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(themeManager.colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onSubmit { submitGoal() }

                Button(action: submitGoal) {
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? themeManager.colors.surface
                                : themeManager.colors.accent
                        )
                        .foregroundColor(
                            newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? themeManager.colors.textMuted
                                : themeManager.colors.background
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.colors.textMuted)

                DatePicker("Due", selection: $newGoalDueDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .font(.system(size: 12))
                    .labelsHidden()

                Text(dateFormatter.string(from: newGoalDueDate))
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.colors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(themeManager.colors.surface)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Goal Card

    private func goalCard(_ goal: Goal) -> some View {
        let isEditing = editingGoalID == goal.id

        return VStack(spacing: 0) {
            if isEditing {
                // ── Editing mode ──
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Goal text", text: $editingText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(themeManager.colors.background)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))

                    DatePicker("Due Date", selection: $editingDueDate, displayedComponents: .date)
                        .datePickerStyle(.field)
                        .font(.system(size: 12))
                        .labelsHidden()

                    HStack(spacing: 10) {
                        Spacer()

                        // Cancel edit
                        Button(action: { cancelEdit() }) {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                        .buttonStyle(.plain)

                        // Confirm edit
                        Button(action: { confirmEdit(goal: goal) }) {
                            Text("Save")
                                .font(.system(size: 11, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundColor(themeManager.colors.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(14)
            } else {
                // ── Display mode ──
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Goal text — bold
                        Text(goal.text)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        // Due date
                        if let due = goal.dueDate {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text("Due \(dateFormatter.string(from: due))")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(themeManager.colors.accent)
                        } else {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text("No due date")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(themeManager.colors.textMuted)
                        }
                    }

                    Spacer()

                    // Edit button
                    Button(action: { startEdit(goal: goal) }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(6)
                    }
                    .buttonStyle(.plain)

                    // Delete button
                    Button(action: { store.deleteGoal(id: goal.id) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
        }
.background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 32))
                .foregroundColor(themeManager.colors.textMuted)
            Text("No goals yet.\nAdd one above to get started.")
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

    // MARK: - Actions

    private func submitGoal() {
        let trimmed = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addGoal(text: trimmed, dueDate: newGoalDueDate)
        newGoalText = ""
        newGoalDueDate = Date()
    }

    private func startEdit(goal: Goal) {
        editingGoalID = goal.id
        editingText = goal.text
        editingDueDate = goal.dueDate ?? Date()
    }

    private func confirmEdit(goal: Goal) {
        store.updateGoal(id: goal.id, text: editingText, dueDate: editingDueDate)
        cancelEdit()
    }

    private func cancelEdit() {
        editingGoalID = nil
        editingText = ""
    }
}
