import SwiftUI

// MARK: - Pop-Out TD List (compact, 10pt)

struct PopOutTDListView: View {
    @ObservedObject private var store = DataStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var proText = ""
    @State private var perText = ""
    @State private var dailyGoalText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TD List")
                        .font(.system(size: 12, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundColor(themeManager.colors.textSecondary)

                    Spacer()

                    Text("\(store.checklistItems.count) items")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.colors.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                dailyGoalsSection

                if store.checklistItems.isEmpty && store.todayDailyGoals.isEmpty {
                    emptyPlaceholder
                } else {
                    checklistSections
                }
            }
        }
        .background(themeManager.colors.background)
    }

    // MARK: - Daily Goals Section

    private var dailyGoalsSection: some View {
        let todayGoals = store.todayDailyGoals
        return VStack(alignment: .leading, spacing: 0) {
            if !todayGoals.isEmpty || todayGoals.count < DailyGoal.maxPerDay {
                Text("Daily Goals (\(todayGoals.count)/\(DailyGoal.maxPerDay))")
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundColor(themeManager.colors.textMuted)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)

                VStack(spacing: 0) {
                    ForEach(Array(todayGoals.enumerated()), id: \.element.id) { idx, goal in
                        popoutDailyGoalRow(goal: goal)
                        if idx < todayGoals.count - 1 {
                            Divider().overlay(themeManager.colors.borderFaint)
                        }
                    }

                    if todayGoals.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 22))
                                .foregroundColor(themeManager.colors.textMuted)
                            Text("No daily goals yet.\nAdd 1-5 goals for today.")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }

                    if todayGoals.count < DailyGoal.maxPerDay {
                        if !todayGoals.isEmpty {
                            Divider().overlay(themeManager.colors.borderFaint)
                        }
                        popoutAddDailyGoalRow
                    }
                }
                .padding(6)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 8)
    }

    private var popoutAddDailyGoalRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.system(size: 11))
                .foregroundColor(themeManager.colors.accent.opacity(0.6))

            TextField("Add daily goal...", text: $dailyGoalText)
                .textFieldStyle(.plain)
                .font(.system(size: 10))
                .foregroundColor(themeManager.colors.textPrimary)
                .onSubmit {
                    let trimmed = dailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.addDailyGoal(text: trimmed)
                    dailyGoalText = ""
                }

            Button(action: {
                let trimmed = dailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addDailyGoal(text: trimmed)
                dailyGoalText = ""
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(
                        dailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? themeManager.colors.textMuted
                            : themeManager.colors.accent
                    )
            }
            .buttonStyle(.plain)
            .disabled(dailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private func popoutDailyGoalRow(goal: DailyGoal) -> some View {
        HStack(spacing: 6) {
            Button(action: { store.toggleDailyGoal(id: goal.id) }) {
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(
                                goal.isChecked ? color : themeManager.colors.textMuted,
                                lineWidth: 1.5
                            )
                            .frame(width: 16, height: 16)
                            .background(
                                goal.isChecked ? color.opacity(0.15) : Color.clear
                            )

                        if goal.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                        }
                    }

                    Text(goal.text)
                        .font(.system(size: 10, weight: goal.isChecked ? .regular : .medium))
                        .foregroundColor(
                            goal.isChecked ? themeManager.colors.textMuted : themeManager.colors.textPrimary
                        )
                        .strikethrough(goal.isChecked, color: themeManager.colors.textMuted)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { store.deleteDailyGoal(id: goal.id) }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.colors.textMuted.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
    }

    // MARK: - Empty

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 22))
                .foregroundColor(themeManager.colors.textMuted)
            Text("No checklist items.\nAdd some in the TD List tab.")
                .font(.system(size: 10))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Checklist Sections

    private var checklistSections: some View {
        VStack(spacing: 10) {
            let proItems = store.checklistItems.filter { $0.section == .professional }
            let perItems = store.checklistItems.filter { $0.section == .personal }

            if !proItems.isEmpty {
                sectionBlock(title: "Professional (\(proItems.count))", items: proItems)
            }

            if !perItems.isEmpty {
                sectionBlock(title: "Personal & Academic (\(perItems.count))", items: perItems)
            }
        }
        .padding(.horizontal, 8)
    }

    private func sectionBlock(title: String, items: [ChecklistItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(themeManager.colors.textMuted)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)

            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                popoutRow(item: item)
                if idx < items.count - 1 {
                    Divider()
                        .overlay(themeManager.colors.borderFaint)
                }
            }
        }
        .padding(6)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Row

    private func popoutRow(item: ChecklistItem) -> some View {
        HStack(spacing: 6) {
            Button(action: { store.toggleChecklistItem(item) }) {
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(
                                item.isChecked ? color : themeManager.colors.textMuted,
                                lineWidth: 1.5
                            )
                            .frame(width: 16, height: 16)
                            .background(
                                item.isChecked ? color.opacity(0.15) : Color.clear
                            )

                        if item.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                        }
                    }

                    Text(item.text)
                        .font(.system(size: 10, weight: item.isChecked ? .regular : .medium))
                        .foregroundColor(
                            item.isChecked ? themeManager.colors.textMuted : themeManager.colors.textPrimary
                        )
                        .strikethrough(item.isChecked, color: themeManager.colors.textMuted)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { store.deleteChecklistItem(item) }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.colors.textMuted.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
    }

    private var color: Color {
        themeManager.colors.accent
    }
}
